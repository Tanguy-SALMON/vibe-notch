//
//  EventMonitors.swift
//  Notchd
//
//  Singleton that aggregates all event monitors
//

import AppKit
import Combine

@MainActor
final class EventMonitors {
    static let shared = EventMonitors()

    /// Tag written into `eventSourceUserData` of clicks we synthesize ourselves,
    /// so our own monitors ignore them instead of handling them a second time.
    static let syntheticEventTag: Int64 = 0x4E4F_5443_4844 // "NOTCHD"

    let mouseLocation = CurrentValueSubject<CGPoint, Never>(.zero)
    let mouseDown = PassthroughSubject<NSEvent, Never>()

    private var mouseMoveMonitor: EventMonitor?
    private var mouseDownMonitor: EventMonitor?
    private var mouseDraggedMonitor: EventMonitor?

    private init() {
        setupMonitors()
    }

    static func isSynthetic(_ event: NSEvent) -> Bool {
        event.cgEvent?.getIntegerValueField(.eventSourceUserData) == syntheticEventTag
    }

    private func setupMonitors() {
        mouseMoveMonitor = EventMonitor(mask: .mouseMoved) { [weak self] _ in
            self?.sendMouseLocation()
        }
        mouseMoveMonitor?.start()

        mouseDownMonitor = EventMonitor(mask: .leftMouseDown) { [weak self] event in
            guard !Self.isSynthetic(event) else { return }
            self?.mouseDown.send(event)
        }
        mouseDownMonitor?.start()

        mouseDraggedMonitor = EventMonitor(mask: .leftMouseDragged) { [weak self] _ in
            self?.sendMouseLocation()
        }
        mouseDraggedMonitor?.start()
    }

    /// Skip duplicate positions so subscribers don't do work for no movement.
    private func sendMouseLocation() {
        let location = NSEvent.mouseLocation
        guard location != mouseLocation.value else { return }
        mouseLocation.send(location)
    }
}
