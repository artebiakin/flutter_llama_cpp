#include "llama_flutter.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// Global state
static char g_last_error[1024] = "";
static bool g_initialized = false;

// Helper functions
static void set_last_error(const char* error) {
    strncpy(g_last_error, error, sizeof(g_last_error) - 1);
    g_last_error[sizeof(g_last_error) - 1] = '\0';
}

static void safe_strncpy(char* dest, const char* src, size_t size) {
    if (dest && src && size > 0) {
        strncpy(dest, src, size - 1);
        dest[size - 1] = '\0';
    }
}

// API Implementation (stub version for testing)

LF_API lf_error_t lf_init(void) {
    if (g_initialized) {
        return LF_OK;
    }
    
    g_initialized = true;
    set_last_error("");
    return LF_OK;
}

LF_API lf_error_t lf_info(char* info_buffer, size_t buffer_size) {
    if (!info_buffer || buffer_size == 0) {
        set_last_error("Invalid buffer parameters");
        return LF_ERROR_INVALID_PARAM;
    }
    
    const char* info = "llama.cpp Flutter Plugin (STUB VERSION)\n"
                      "Build date: " __DATE__ " " __TIME__ "\n"
                      "Status: Not implemented - for testing only";
    
    safe_strncpy(info_buffer, info, buffer_size);
    return LF_OK;
}

LF_API lf_error_t lf_last_error(char* error_buffer, size_t buffer_size) {
    if (!error_buffer || buffer_size == 0) {
        return LF_ERROR_INVALID_PARAM;
    }
    
    safe_strncpy(error_buffer, g_last_error, buffer_size);
    return LF_OK;
}

LF_API lf_error_t lf_model_load(const char* model_path, lf_model** model) {
    (void)model_path;
    (void)model;
    set_last_error("Model loading not implemented in stub version");
    return LF_ERROR_MODEL_LOAD;
}

LF_API lf_error_t lf_model_info(lf_model* model, lf_model_info_t* info) {
    (void)model;
    (void)info;
    set_last_error("Model info not implemented in stub version");
    return LF_ERROR_INVALID_PARAM;
}

LF_API void lf_model_free(lf_model* model) {
    (void)model;
    // No-op in stub version
}

LF_API lf_error_t lf_context_create(lf_model* model, int32_t n_ctx, lf_context** context) {
    (void)model;
    (void)n_ctx;
    (void)context;
    set_last_error("Context creation not implemented in stub version");
    return LF_ERROR_CONTEXT_CREATE;
}

LF_API void lf_context_free(lf_context* context) {
    (void)context;
    // No-op in stub version
}

LF_API lf_error_t lf_eval_prompt(lf_context* context, const char* prompt) {
    (void)context;
    (void)prompt;
    set_last_error("Prompt evaluation not implemented in stub version");
    return LF_ERROR_INVALID_PARAM;
}

LF_API lf_error_t lf_generate_next(lf_context* context, 
                                   const lf_generation_params_t* params,
                                   char* token_buffer, 
                                   size_t buffer_size,
                                   bool* is_eos) {
    (void)context;
    (void)params;
    (void)token_buffer;
    (void)buffer_size;
    (void)is_eos;
    set_last_error("Text generation not implemented in stub version");
    return LF_ERROR_UNKNOWN;
}

LF_API lf_error_t lf_cancel(lf_context* context) {
    (void)context;
    set_last_error("Cancel not implemented in stub version");
    return LF_ERROR_INVALID_PARAM;
}

LF_API lf_error_t lf_reset(lf_context* context) {
    (void)context;
    set_last_error("Reset not implemented in stub version");
    return LF_ERROR_INVALID_PARAM;
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
