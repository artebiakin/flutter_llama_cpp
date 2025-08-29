#include "llama_flutter.h"
#include "../vendor/llama.cpp/include/llama.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <atomic>
#include <memory>
#include <string>
#include <vector>
#include <mutex>

// Internal structures
struct lf_model {
    llama_model* model;
    std::string path;
    bool is_valid;
    
    lf_model() : model(nullptr), is_valid(false) {}
    ~lf_model() {
        if (model) {
            llama_free_model(model);
        }
    }
};

struct lf_context {
    llama_context* ctx;
    lf_model* model_ref;
    llama_sampler* sampler;
    std::vector<llama_token> tokens;
    std::atomic<bool> should_cancel;
    std::mutex generation_mutex;
    bool is_valid;
    
    lf_context() : ctx(nullptr), model_ref(nullptr), sampler(nullptr), 
                   should_cancel(false), is_valid(false) {}
    ~lf_context() {
        if (sampler) {
            llama_sampler_free(sampler);
        }
        if (ctx) {
            llama_free(ctx);
        }
    }
};

// Global state
static std::string g_last_error;
static std::mutex g_error_mutex;
static bool g_initialized = false;

// Helper functions
static void set_last_error(const std::string& error) {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    g_last_error = error;
}

static void safe_strncpy(char* dest, const char* src, size_t size) {
    if (dest && src && size > 0) {
        strncpy(dest, src, size - 1);
        dest[size - 1] = '\0';
    }
}

// API Implementation

LF_API lf_error_t lf_init(void) {
    if (g_initialized) {
        return LF_OK;
    }
    
    try {
        llama_backend_init();
        llama_numa_init(GGML_NUMA_STRATEGY_DISABLED);
        g_initialized = true;
        set_last_error("");
        return LF_OK;
    } catch (const std::exception& e) {
        set_last_error(std::string("Failed to initialize: ") + e.what());
        return LF_ERROR_INIT;
    } catch (...) {
        set_last_error("Failed to initialize: unknown error");
        return LF_ERROR_INIT;
    }
}

LF_API lf_error_t lf_info(char* info_buffer, size_t buffer_size) {
    if (!info_buffer || buffer_size == 0) {
        set_last_error("Invalid buffer parameters");
        return LF_ERROR_INVALID_PARAM;
    }
    
    try {
        std::string info = "llama.cpp Flutter Plugin\n";
        info += "Build date: " __DATE__ " " __TIME__ "\n";
        info += "Commit: " LLAMA_COMMIT;
        
        safe_strncpy(info_buffer, info.c_str(), buffer_size);
        return LF_OK;
    } catch (...) {
        set_last_error("Failed to get info");
        return LF_ERROR_UNKNOWN;
    }
}

LF_API lf_error_t lf_last_error(char* error_buffer, size_t buffer_size) {
    if (!error_buffer || buffer_size == 0) {
        return LF_ERROR_INVALID_PARAM;
    }
    
    std::lock_guard<std::mutex> lock(g_error_mutex);
    safe_strncpy(error_buffer, g_last_error.c_str(), buffer_size);
    return LF_OK;
}

LF_API lf_error_t lf_model_load(const char* model_path, lf_model** model) {
    if (!model_path || !model) {
        set_last_error("Invalid parameters");
        return LF_ERROR_INVALID_PARAM;
    }
    
    if (!g_initialized) {
        set_last_error("Library not initialized");
        return LF_ERROR_INIT;
    }
    
    try {
        auto lf_model_ptr = std::make_unique<lf_model>();
        lf_model_ptr->path = model_path;
        
        llama_model_params model_params = llama_model_default_params();
        model_params.n_gpu_layers = 0; // CPU-only for now
        
        lf_model_ptr->model = llama_load_model_from_file(model_path, model_params);
        if (!lf_model_ptr->model) {
            set_last_error(std::string("Failed to load model: ") + model_path);
            return LF_ERROR_MODEL_LOAD;
        }
        
        lf_model_ptr->is_valid = true;
        *model = lf_model_ptr.release();
        set_last_error("");
        return LF_OK;
    } catch (const std::exception& e) {
        set_last_error(std::string("Exception loading model: ") + e.what());
        return LF_ERROR_MODEL_LOAD;
    } catch (...) {
        set_last_error("Unknown error loading model");
        return LF_ERROR_MODEL_LOAD;
    }
}

LF_API lf_error_t lf_model_info(lf_model* model, lf_model_info_t* info) {
    if (!model || !model->is_valid || !info) {
        set_last_error("Invalid model or info pointer");
        return LF_ERROR_INVALID_PARAM;
    }
    
    try {
        memset(info, 0, sizeof(lf_model_info_t));
        
        // Get basic model info
        info->vocab_size = llama_n_vocab(model->model);
        info->n_ctx_max = llama_n_ctx_train(model->model);
        info->n_embd = llama_n_embd(model->model);
        info->size_bytes = llama_model_size(model->model);
        
        // Try to get model name and architecture
        const char* model_name = llama_model_name(model->model);
        if (model_name) {
            safe_strncpy(info->name, model_name, sizeof(info->name));
        } else {
            safe_strncpy(info->name, "Unknown", sizeof(info->name));
        }
        
        const char* arch = llama_model_arch(model->model);
        if (arch) {
            safe_strncpy(info->architecture, arch, sizeof(info->architecture));
        } else {
            safe_strncpy(info->architecture, "Unknown", sizeof(info->architecture));
        }
        
        return LF_OK;
    } catch (...) {
        set_last_error("Failed to get model info");
        return LF_ERROR_UNKNOWN;
    }
}

LF_API void lf_model_free(lf_model* model) {
    if (model) {
        delete model;
    }
}

LF_API lf_error_t lf_context_create(lf_model* model, int32_t n_ctx, lf_context** context) {
    if (!model || !model->is_valid || !context) {
        set_last_error("Invalid model or context pointer");
        return LF_ERROR_INVALID_PARAM;
    }
    
    try {
        auto lf_ctx = std::make_unique<lf_context>();
        lf_ctx->model_ref = model;
        
        llama_context_params ctx_params = llama_context_default_params();
        ctx_params.n_ctx = n_ctx > 0 ? n_ctx : llama_n_ctx_train(model->model);
        ctx_params.n_batch = 512;
        ctx_params.n_ubatch = 512;
        ctx_params.n_threads = 4;
        ctx_params.n_threads_batch = 4;
        
        lf_ctx->ctx = llama_new_context_with_model(model->model, ctx_params);
        if (!lf_ctx->ctx) {
            set_last_error("Failed to create context");
            return LF_ERROR_CONTEXT_CREATE;
        }
        
        // Create sampler
        auto sparams = llama_sampler_chain_default_params();
        lf_ctx->sampler = llama_sampler_chain_init(sparams);
        
        lf_ctx->is_valid = true;
        *context = lf_ctx.release();
        set_last_error("");
        return LF_OK;
    } catch (const std::exception& e) {
        set_last_error(std::string("Exception creating context: ") + e.what());
        return LF_ERROR_CONTEXT_CREATE;
    } catch (...) {
        set_last_error("Unknown error creating context");
        return LF_ERROR_CONTEXT_CREATE;
    }
}

LF_API void lf_context_free(lf_context* context) {
    if (context) {
        delete context;
    }
}

LF_API lf_error_t lf_eval_prompt(lf_context* context, const char* prompt) {
    if (!context || !context->is_valid || !prompt) {
        set_last_error("Invalid context or prompt");
        return LF_ERROR_INVALID_PARAM;
    }
    
    try {
        std::lock_guard<std::mutex> lock(context->generation_mutex);
        
        // Tokenize the prompt
        int n_tokens = strlen(prompt) + 1024; // Rough estimate
        std::vector<llama_token> tokens(n_tokens);
        
        n_tokens = llama_tokenize(context->model_ref->model, prompt, strlen(prompt), 
                                 tokens.data(), tokens.size(), true, false);
        
        if (n_tokens < 0) {
            set_last_error("Failed to tokenize prompt");
            return LF_ERROR_INVALID_PARAM;
        }
        
        tokens.resize(n_tokens);
        context->tokens = tokens;
        
        // Clear context and evaluate prompt
        llama_kv_cache_clear(context->ctx);
        
        for (int i = 0; i < n_tokens; ++i) {
            if (llama_decode(context->ctx, llama_batch_get_one(&tokens[i], i, 0, 0))) {
                set_last_error("Failed to evaluate prompt");
                return LF_ERROR_UNKNOWN;
            }
        }
        
        set_last_error("");
        return LF_OK;
    } catch (const std::exception& e) {
        set_last_error(std::string("Exception evaluating prompt: ") + e.what());
        return LF_ERROR_UNKNOWN;
    } catch (...) {
        set_last_error("Unknown error evaluating prompt");
        return LF_ERROR_UNKNOWN;
    }
}

LF_API lf_error_t lf_generate_next(lf_context* context, 
                                   const lf_generation_params_t* params,
                                   char* token_buffer, 
                                   size_t buffer_size,
                                   bool* is_eos) {
    if (!context || !context->is_valid || !params || !token_buffer || !is_eos) {
        set_last_error("Invalid parameters");
        return LF_ERROR_INVALID_PARAM;
    }
    
    if (context->should_cancel.load()) {
        set_last_error("Generation cancelled");
        return LF_ERROR_CANCELLED;
    }
    
    try {
        std::lock_guard<std::mutex> lock(context->generation_mutex);
        
        // Sample next token
        llama_token new_token = llama_sampler_sample(context->sampler, context->ctx, -1);
        
        // Check for EOS
        *is_eos = llama_token_is_eog(context->model_ref->model, new_token);
        
        if (*is_eos) {
            token_buffer[0] = '\0';
            return LF_OK;
        }
        
        // Convert token to text
        std::vector<char> piece(256);
        int n_chars = llama_token_to_piece(context->model_ref->model, new_token, 
                                          piece.data(), piece.size(), 0, false);
        
        if (n_chars < 0) {
            piece.resize(-n_chars);
            n_chars = llama_token_to_piece(context->model_ref->model, new_token, 
                                          piece.data(), piece.size(), 0, false);
        }
        
        if (n_chars >= 0) {
            safe_strncpy(token_buffer, piece.data(), buffer_size);
        } else {
            token_buffer[0] = '\0';
        }
        
        // Update context with new token
        context->tokens.push_back(new_token);
        if (llama_decode(context->ctx, llama_batch_get_one(&new_token, context->tokens.size() - 1, 0, 0))) {
            set_last_error("Failed to update context");
            return LF_ERROR_UNKNOWN;
        }
        
        // Accept the sampled token
        llama_sampler_accept(context->sampler, new_token);
        
        return LF_OK;
    } catch (const std::exception& e) {
        set_last_error(std::string("Exception generating token: ") + e.what());
        return LF_ERROR_UNKNOWN;
    } catch (...) {
        set_last_error("Unknown error generating token");
        return LF_ERROR_UNKNOWN;
    }
}

LF_API lf_error_t lf_cancel(lf_context* context) {
    if (!context || !context->is_valid) {
        set_last_error("Invalid context");
        return LF_ERROR_INVALID_PARAM;
    }
    
    context->should_cancel.store(true);
    return LF_OK;
}

LF_API lf_error_t lf_reset(lf_context* context) {
    if (!context || !context->is_valid) {
        set_last_error("Invalid context");
        return LF_ERROR_INVALID_PARAM;
    }
    
    try {
        std::lock_guard<std::mutex> lock(context->generation_mutex);
        
        llama_kv_cache_clear(context->ctx);
        llama_sampler_reset(context->sampler);
        context->tokens.clear();
        context->should_cancel.store(false);
        
        return LF_OK;
    } catch (...) {
        set_last_error("Failed to reset context");
        return LF_ERROR_UNKNOWN;
    }
}

LF_API void lf_generation_params_default(lf_generation_params_t* params) {
    if (params) {
        params->n_predict = -1;
        params->top_k = 40;
        params->top_p = 0.9f;
        params->temp = 0.8f;
        params->repeat_penalty = 1.1f;
        params->penalize_nl = false;
        params->seed = -1;
    }
}
