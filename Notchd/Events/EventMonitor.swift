//
//  EventMonitor.swift
//  Notchd
//
//  Wraps NSEvent monitoring for safe lifecycle management
//

import AppKit

@MainActor
final class EventMonitor {
    // nonisolated(unsafe) so the nonisolated deinit can remove the monitors.
    // Only mutated on the main actor (start/stop) or in deinit (no other refs).
    nonisolated(unsafe) private var globalMonitor: Any?
    nonisolated(unsafe) private var localMonitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: @MainActor (NSEvent) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping @MainActor (NSEvent) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor) }
    }

    func start() {
        guard globalMonitor == nil, localMonitor == nil else { return }

        // Global monitor for events outside our app (delivered on the main thread)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            MainActor.assumeIsolated { self?.handler(event) }
        }

        // Local monitor for events inside our app (delivered on the main thread)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            MainActor.assumeIsolated { self?.handler(event) }
            return event
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}
