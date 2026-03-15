// Tracy Profiler Swift Wrapper for pterm
import Foundation
import PtermCore

/// Tracy profiler wrapper - enables memory leak profiling with autocapture
public final class TracyProfiler {

    /// Initialize Tracy profiler with autocapture enabled
    /// Returns true if initialization succeeded
    @discardableResult
    public static func initialize() -> Bool {
        let result = tracy_init_with_autocapture(8086)
        return result == 0
    }

    /// Mark a frame boundary (optional - autocapture handles this automatically)
    public static func markFrame() {
        tracy_frame_mark()
    }

    /// Report a memory allocation (manual)
    public static func reportAlloc(_ ptr: UnsafeRawPointer, size: Int) {
        tracy_mem_alloc(ptr, size)
    }

    /// Report a memory deallocation (manual)
    public static func reportFree(_ ptr: UnsafeRawPointer) {
        tracy_mem_free(ptr)
    }

    /// Report a named memory allocation (manual)
    public static func reportAllocNamed(_ ptr: UnsafeRawPointer, size: Int, name: String) {
        name.withCString { namePtr in
            tracy_mem_alloc_n(ptr, size, namePtr)
        }
    }

    /// Report a named memory deallocation (manual)
    public static func reportFreeNamed(_ ptr: UnsafeRawPointer, name: String) {
        name.withCString { namePtr in
            tracy_mem_free_n(ptr, namePtr)
        }
    }

    // MARK: - Zone Profiling (push/pop stack)
    //
    // Usage:
    //   TracyProfiler.pushZone("MyZone")
    //   defer { TracyProfiler.popZone() }
    //
    // The defer call is opaque to Swift's ARC optimizer, so the zone is
    // guaranteed to close at the correct scope boundary.

    @inline(__always)
    public static func pushZone(_ name: StaticString, function: StaticString = #function, line: UInt32 = #line) {
        // StaticString.utf8Start points to null-terminated UTF-8 data in the binary.
        // This satisfies __builtin_strlen in the C bridge.
        tracy_zone_push(
            UnsafeRawPointer(name.utf8Start).assumingMemoryBound(to: CChar.self),
            UnsafeRawPointer(function.utf8Start).assumingMemoryBound(to: CChar.self),
            line
        )
    }

    @inline(__always)
    public static func popZone() {
        tracy_zone_pop()
    }
}
