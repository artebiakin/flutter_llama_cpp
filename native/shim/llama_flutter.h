#ifndef LLAMA_FLUTTER_H
#define LLAMA_FLUTTER_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>  // For size_t

#ifdef __cplusplus
extern "C" {
#endif

// Platform-specific export macros
#if defined(_WIN32) || defined(_WIN64)
    #define LF_API __declspec(dllexport)
#else
    #define LF_API __attribute__((visibility("default")))
#endif

// Forward declarations
typedef struct lf_model lf_model;
typedef struct lf_context lf_context;

// Error codes
typedef enum {
    LF_OK = 0,
    LF_ERROR_INIT = -1,
    LF_ERROR_MODEL_LOAD = -2,
    LF_ERROR_CONTEXT_CREATE = -3,
    LF_ERROR_INVALID_PARAM = -4,
    LF_ERROR_OUT_OF_MEMORY = -5,
    LF_ERROR_CANCELLED = -6,
    LF_ERROR_UNKNOWN = -999
} lf_error_t;

// Model information structure
typedef struct {
    char name[256];
    char architecture[64];
    int32_t vocab_size;
    int32_t n_ctx_max;
    int32_t n_embd;
    int32_t n_params;
    size_t size_bytes;
} lf_model_info_t;

// Generation parameters
typedef struct {
    int32_t n_predict;      // Number of tokens to predict (-1 for infinite, -2 for until context filled)
    int32_t top_k;          // Top-k sampling
    float top_p;            // Top-p sampling
    float temp;             // Temperature
    float repeat_penalty;   // Repetition penalty
    bool penalize_nl;       // Penalize newlines
    int32_t seed;           // RNG seed (-1 for random)
} lf_generation_params_t;

// Core API functions

/**
 * Initialize the llama.cpp library.
 * Must be called before any other functions.
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_init(void);

/**
 * Get library information.
 * @param info_buffer Buffer to write info string (null-terminated)
 * @param buffer_size Size of the buffer
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_info(char* info_buffer, size_t buffer_size);

/**
 * Get the last error message.
 * @param error_buffer Buffer to write error string (null-terminated)
 * @param buffer_size Size of the buffer
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_last_error(char* error_buffer, size_t buffer_size);

/**
 * Load a model from file.
 * @param model_path Path to the GGUF model file
 * @param model Pointer to store the loaded model
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_model_load(const char* model_path, lf_model** model);

/**
 * Get model information.
 * @param model Model handle
 * @param info Pointer to store model information
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_model_info(lf_model* model, lf_model_info_t* info);

/**
 * Free a loaded model.
 * @param model Model to free
 */
LF_API void lf_model_free(lf_model* model);

/**
 * Create a context for inference.
 * @param model Model handle
 * @param n_ctx Context size (0 for model default)
 * @param context Pointer to store the created context
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_context_create(lf_model* model, int32_t n_ctx, lf_context** context);

/**
 * Free a context.
 * @param context Context to free
 */
LF_API void lf_context_free(lf_context* context);

/**
 * Evaluate a prompt and prepare for generation.
 * @param context Context handle
 * @param prompt Input prompt text
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_eval_prompt(lf_context* context, const char* prompt);

/**
 * Generate the next token.
 * @param context Context handle
 * @param params Generation parameters
 * @param token_buffer Buffer to write the generated token text
 * @param buffer_size Size of the buffer
 * @param is_eos Set to true if this is the end-of-sequence token
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_generate_next(lf_context* context, 
                                   const lf_generation_params_t* params,
                                   char* token_buffer, 
                                   size_t buffer_size,
                                   bool* is_eos);

/**
 * Cancel ongoing generation.
 * @param context Context handle
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_cancel(lf_context* context);

/**
 * Reset context state.
 * @param context Context handle
 * @return LF_OK on success, error code on failure
 */
LF_API lf_error_t lf_reset(lf_context* context);

/**
 * Get default generation parameters.
 * @param params Pointer to store default parameters
 */
LF_API void lf_generation_params_default(lf_generation_params_t* params);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_FLUTTER_H
