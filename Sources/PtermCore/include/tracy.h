// Tracy Profiler C Bridge for pterm
// Enables memory profiling with autocapture

#ifndef PTERM_TRACY_H
#define PTERM_TRACY_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Initialize Tracy profiler with autocapture enabled
// autocapturePort: TCP port for tracy-capture to connect (default: 8086)
// Returns 0 on success, -1 if already initialized
int tracy_init_with_autocapture(uint16_t autocapturePort);

// Shutdown the profiler
void tracy_shutdown(void);

// Manually mark a frame (optional, autocapture handles this)
void tracy_frame_mark(void);

// Memory profiling: report an allocation
void tracy_mem_alloc(const void* ptr, size_t size);

// Memory profiling: report a deallocation
void tracy_mem_free(const void* ptr);

// Memory profiling: report a named allocation
void tracy_mem_alloc_n(const void* ptr, size_t size, const char* name);

// Memory profiling: report a named deallocation
void tracy_mem_free_n(const void* ptr, const char* name);

// Get current heap usage in bytes
size_t tracy_get_heap_usage(void);

// Zone profiling: push a zone onto the thread-local stack.
// Pair with tracy_zone_pop() — use Swift defer for automatic cleanup.
void tracy_zone_push(const char* name, const char* function, uint32_t line);

// Zone profiling: pop the innermost zone from the thread-local stack.
void tracy_zone_pop(void);

#ifdef __cplusplus
}
#endif

#endif // PTERM_TRACY_H
