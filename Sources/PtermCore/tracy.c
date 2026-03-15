// Tracy Profiler C Bridge Implementation for pterm
//
// This file implements the Tracy bridge by declaring the external Tracy
// functions and linking against the pre-built libTracyClient.a.
// With TRACY_AUTOCAPTURE=1, Tracy initializes automatically on first use.

#include "tracy.h"
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>

// External declarations for Tracy C API functions
// These are defined in Tracy's TracyC.h and linked from libTracyClient.a
// Note: macOS adds leading underscore to C symbols, so we use 3 underscores
// in code which becomes 4 underscores in the final symbol

extern void ___tracy_emit_frame_mark(const char* name);

extern void ___tracy_emit_memory_alloc(const void* ptr, size_t size, int secure);
extern void ___tracy_emit_memory_free(const void* ptr, int secure);
extern void ___tracy_emit_memory_alloc_callstack(const void* ptr, size_t size, int depth, int secure);
extern void ___tracy_emit_memory_free_callstack(const void* ptr, int depth, int secure);

// Zone functions — Tracy defines TracyCZoneCtx as struct { uint32_t id; }
typedef struct { uint32_t id; } TZoneCtx;
extern uint64_t ___tracy_alloc_srcloc(uint32_t line, const char* source, size_t sourceSz, const char* function, size_t functionSz, uint32_t color);
extern TZoneCtx ___tracy_emit_zone_begin_alloc(uint64_t srcloc, int active);
extern void ___tracy_emit_zone_end(TZoneCtx ctx);

static int tracy_initialized = 0;

int tracy_init_with_autocapture(uint16_t autocapturePort) {
    (void)autocapturePort;  // Port is configured via TRACY_AUTOCAPTURE env var or defaults to 8086
    if (tracy_initialized) {
        return -1; // Already initialized
    }

    // With TRACY_AUTOCAPTURE=1, Tracy initializes automatically
    // No explicit startup call needed
    tracy_initialized = 1;
    return 0;
}

void tracy_shutdown(void) {
    if (!tracy_initialized) return;
    // Tracy cleanup is automatic
    tracy_initialized = 0;
}

void tracy_frame_mark(void) {
    if (!tracy_initialized) return;
    ___tracy_emit_frame_mark(NULL);
}

void tracy_mem_alloc(const void* ptr, size_t size) {
    if (!tracy_initialized || !ptr) return;
    ___tracy_emit_memory_alloc_callstack(ptr, size, 12, 0);
}

void tracy_mem_free(const void* ptr) {
    if (!tracy_initialized || !ptr) return;
    ___tracy_emit_memory_free_callstack(ptr, 12, 0);
}

void tracy_mem_alloc_n(const void* ptr, size_t size, const char* name) {
    (void)name;  // Could be used for named allocation with more complex setup
    if (!tracy_initialized || !ptr) return;
    ___tracy_emit_memory_alloc_callstack(ptr, size, 12, 0);
}

void tracy_mem_free_n(const void* ptr, const char* name) {
    (void)name;  // Unused - Tracy will record callstack
    if (!tracy_initialized || !ptr) return;
    ___tracy_emit_memory_free_callstack(ptr, 12, 0);
}

size_t tracy_get_heap_usage(void) {
    return 0;
}

// Thread-local zone push/pop stack
// Each Swift call site does: tracy_zone_push(...); defer { tracy_zone_pop(); }
// C calls inside defer are opaque to Swift's ARC optimizer and cannot be elided.

#define TRACY_ZONE_STACK_DEPTH 128
static __thread TZoneCtx tracy_zone_stack[TRACY_ZONE_STACK_DEPTH];
static __thread int tracy_zone_depth = 0;

void tracy_zone_push(const char* name, const char* function, uint32_t line) {
    if (!tracy_initialized || tracy_zone_depth >= TRACY_ZONE_STACK_DEPTH) return;
    uint64_t srcloc = ___tracy_alloc_srcloc(
        line,
        name, __builtin_strlen(name),
        function, __builtin_strlen(function),
        0 /* color */
    );
    tracy_zone_stack[tracy_zone_depth++] = ___tracy_emit_zone_begin_alloc(srcloc, 1);
}

void tracy_zone_pop(void) {
    if (!tracy_initialized || tracy_zone_depth <= 0) return;
    ___tracy_emit_zone_end(tracy_zone_stack[--tracy_zone_depth]);
}
