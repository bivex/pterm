// Tracy Profiler Swift Wrapper for pterm
import Foundation
import PtermCore

/// Tracy profiler wrapper - enables memory leak profiling with autocapture
public final class TracyProfiler {
    private static let isAvailable = {
        // Check if Tracy client library is linked
        // We'll try to initialize and see if it works
        true
    }()

    /// Initialize Tracy profiler with autocapture enabled
    /// Returns true if initialization succeeded
    @discardableResult
    public static func initialize() -> Bool {
        guard isAvailable else { return false }

        // Initialize with default autocapture port (8086)
        let result = tracy_init_with_autocapture(8086)
        return result == 0
    }

    /// Mark a frame boundary (optional - autocapture handles this automatically)
    public static func markFrame() {
        guard isAvailable else { return }
        tracy_frame_mark()
    }

    /// Report a memory allocation (manual)
    public static func reportAlloc(_ ptr: UnsafeRawPointer, size: Int) {
        guard isAvailable else { return }
        tracy_mem_alloc(ptr, size)
    }

    /// Report a memory deallocation (manual)
    public static func reportFree(_ ptr: UnsafeRawPointer) {
        guard isAvailable else { return }
        tracy_mem_free(ptr)
    }

    /// Report a named memory allocation (manual)
    public static func reportAllocNamed(_ ptr: UnsafeRawPointer, size: Int, name: String) {
        guard isAvailable else { return }
        name.withCString { namePtr in
            tracy_mem_alloc_n(ptr, size, namePtr)
        }
    }

    /// Report a named memory deallocation (manual)
    public static func reportFreeNamed(_ ptr: UnsafeRawPointer, name: String) {
        guard isAvailable else { return }
        name.withCString { namePtr in
            tracy_mem_free_n(ptr, namePtr)
        }
    }

    // MARK: - Zone Profiling

    /// Begin a profiling zone - returns a zone context
    @discardableResult
    public static func beginZone(_ name: String, function: String = #function, line: UInt = #line) -> UnsafeMutableRawPointer? {
        guard isAvailable else { return nil }
        return name.withCString { namePtr in
            function.withCString { funcPtr in
                tracy_zone_begin(namePtr, funcPtr, UInt32(line))
            }
        }
    }

    /// End a profiling zone by context
    public static func endZone(_ ctx: UnsafeMutableRawPointer?) {
        guard isAvailable, let ctx = ctx else { return }
        tracy_zone_end(ctx)
    }

    /// Begin a named zone (simplified)
    @discardableResult
    public static func beginZoneNamed(_ name: String) -> UnsafeMutableRawPointer? {
        guard isAvailable else { return nil }
        return name.withCString { namePtr in
            tracy_zone_begin_named(namePtr)
        }
    }

    /// Scoped zone that automatically ends when deinitialized
    public final class Zone {
        private let ctx: UnsafeMutableRawPointer?
        private let active: Bool

        public init(name: String, function: String = #function, line: UInt = #line) {
            self.active = TracyProfiler.isAvailable
            if active {
                self.ctx = TracyProfiler.beginZone(name, function: function, line: line)
            } else {
                self.ctx = nil
            }
        }

        public convenience init(named name: String) {
            self.init(name: name, function: "named_zone", line: 0)
        }

        deinit {
            if active, let ctx = ctx {
                TracyProfiler.endZone(ctx)
            }
        }
    }
}
