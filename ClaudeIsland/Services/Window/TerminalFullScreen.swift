//
//  TerminalFullScreen.swift
//  ClaudeIsland
//
//  Brings a session's terminal window to the front and makes it full screen.
//  Works without yabai: walks the process tree to the terminal app, then uses
//  the Accessibility API (AXFullScreen) on the matching window.
//

import AppKit
import ApplicationServices

enum TerminalFullScreen {

    /// Returns false if the terminal couldn't be found or Accessibility isn't granted.
    @discardableResult
    static func enter(forClaudePid pid: Int?, cwd: String) async -> Bool {
        let terminalPid: Int? = await Task.detached {
            guard let pid else { return nil }
            let tree = ProcessTreeBuilder.shared.buildTree()
            return ProcessTreeBuilder.shared.findTerminalPid(forProcess: pid, tree: tree)
        }.value

        guard let terminalPid,
              let app = NSRunningApplication(processIdentifier: pid_t(terminalPid)) else { return false }

        await MainActor.run { _ = app.activate() }

        guard AXIsProcessTrusted() else { return false }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        guard let window = pickWindow(in: axApp, cwd: cwd) else { return false }

        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        return AXUIElementSetAttributeValue(window, "AXFullScreen" as CFString, kCFBooleanTrue) == .success
    }

    /// Prefer a window whose title mentions the project folder; fall back to the focused/main window.
    private static func pickWindow(in app: AXUIElement, cwd: String) -> AXUIElement? {
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
           let windows = value as? [AXUIElement] {
            let folder = (cwd as NSString).lastPathComponent
            if !folder.isEmpty {
                for window in windows {
                    var title: CFTypeRef?
                    if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title) == .success,
                       let text = title as? String, text.localizedCaseInsensitiveContains(folder) {
                        return window
                    }
                }
            }
        }
        for attr in [kAXFocusedWindowAttribute, kAXMainWindowAttribute] {
            var w: CFTypeRef?
            if AXUIElementCopyAttributeValue(app, attr as CFString, &w) == .success, let w {
                return (w as! AXUIElement)
            }
        }
        return nil
    }
}
