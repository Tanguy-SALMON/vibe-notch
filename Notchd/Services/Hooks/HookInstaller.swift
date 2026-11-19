//
//  HookInstaller.swift
//  Notchd
//
//  Auto-installs Claude Code hooks on app launch
//

import Foundation

struct HookInstaller {

    /// Install hook script and update settings.json on app launch
    static func installIfNeeded() {
        let hooksDir = ClaudePaths.hooksDir
        let pythonScript = hooksDir.appendingPathComponent("notchd-state.py")

        try? FileManager.default.createDirectory(
            at: hooksDir,
            withIntermediateDirectories: true
        )

        if let bundled = Bundle.main.url(forResource: "notchd-state", withExtension: "py") {
            try? FileManager.default.removeItem(at: pythonScript)
            try? FileManager.default.copyItem(at: bundled, to: pythonScript)
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: pythonScript.path
            )
        }

        if let bundled = Bundle.main.url(forResource: "notchd-statusline", withExtension: "py") {
            let dest = hooksDir.appendingPathComponent("notchd-statusline.py")
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.copyItem(at: bundled, to: dest)
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
        }

        migrateLegacyFiles(in: hooksDir)
        updateSettings(at: ClaudePaths.settingsFile)
    }

    /// Point `statusLine` at our forwarder (which feeds rate-limit usage to the app),
    /// remembering any pre-existing command so the forwarder can chain to it.
    private static func installStatusLine(into json: inout [String: Any], python: String) {
        let scriptPath = ClaudePaths.shellQuote(
            ClaudePaths.hooksDir.appendingPathComponent("notchd-statusline.py").path
        )
        let command = "\(python) \(scriptPath)"
        let origFile = ClaudePaths.hooksDir.appendingPathComponent("notchd-statusline.orig")

        // Never record our own forwarder (current or pre-rename name) as the "original" command: it would chain to itself.
        if let existing = json["statusLine"] as? [String: Any],
           let existingCommand = existing["command"] as? String,
           !existingCommand.contains("notchd-statusline.py"),
           !legacyStatuslineScripts.contains(where: { existingCommand.contains($0) }) {
            try? existingCommand.write(to: origFile, atomically: true, encoding: .utf8)
        }
        // Keep the user's other statusLine keys (e.g. padding); only the command is ours.
        var statusLine = json["statusLine"] as? [String: Any] ?? [:]
        statusLine["type"] = "command"
        statusLine["command"] = command
        json["statusLine"] = statusLine
    }

    private static func updateSettings(at settingsURL: URL) {
        var json: [String: Any] = [:]
        if FileManager.default.fileExists(atPath: settingsURL.path) {
            // A settings.json we cannot parse (JSONC with comments, a partial write) is left untouched rather than overwritten.
            guard let data = try? Data(contentsOf: settingsURL),
                  let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            json = existing
        }

        let python = detectPython()
        let command = "\(python) \(ClaudePaths.hookScriptShellPath)"
        let hookEntry: [[String: Any]] = [["type": "command", "command": command]]
        let hookEntryWithTimeout: [[String: Any]] = [["type": "command", "command": command, "timeout": 86400]]
        let withMatcher: [[String: Any]] = [["matcher": "*", "hooks": hookEntry]]
        let withMatcherAndTimeout: [[String: Any]] = [["matcher": "*", "hooks": hookEntryWithTimeout]]
        let withoutMatcher: [[String: Any]] = [["hooks": hookEntry]]
        let preCompactConfig: [[String: Any]] = [
            ["matcher": "auto", "hooks": hookEntry],
            ["matcher": "manual", "hooks": hookEntry]
        ]

        var hooks = json["hooks"] as? [String: Any] ?? [:]

        // Strip any existing Notchd hooks from ALL event types first — even
        // events we no longer register. Fixes users who installed v1.3 on an older
        // Claude Code and now have invalid keys like PermissionDenied sitting in
        // their settings.json (issue #85).
        var cleanedHooks: [String: Any] = [:]
        for (event, value) in hooks {
            if let entries = value as? [[String: Any]] {
                let cleaned = entries.compactMap { removingNotchdHooks(from: $0) }
                if !cleaned.isEmpty {
                    cleanedHooks[event] = cleaned
                }
            } else {
                cleanedHooks[event] = value
            }
        }
        hooks = cleanedHooks

        // Register only hooks the installed Claude Code version supports.
        // When detection fails, fall back to the baseline set that every
        // Claude Code version has supported (no new v1.3+ hooks).
        let installedVersion = detectClaudeCodeVersion()
        let hookEvents = supportedHookEvents(
            for: installedVersion,
            withMatcher: withMatcher,
            withMatcherAndTimeout: withMatcherAndTimeout,
            withoutMatcher: withoutMatcher,
            preCompactConfig: preCompactConfig
        )

        for (event, config) in hookEvents {
            let existing = hooks[event] as? [[String: Any]] ?? []
            hooks[event] = existing + config
        }

        json["hooks"] = hooks
        installStatusLine(into: &json, python: python)

        if let data = try? JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            try? data.write(to: settingsURL)
        }
    }

    // MARK: - Claude Code Version Detection

    /// Simple semantic version used to gate which hook events we register.
    /// Claude Code rejects unknown hook keys, so we must only register
    /// events the installed version knows about.
    struct ClaudeCodeVersion: Comparable {
        let major: Int
        let minor: Int
        let patch: Int

        static func < (lhs: ClaudeCodeVersion, rhs: ClaudeCodeVersion) -> Bool {
            (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
        }
    }

    /// Runs `claude --version` and parses the result. Returns nil on any
    /// failure (binary not found, non-zero exit, unparseable output).
    static func detectClaudeCodeVersion() -> ClaudeCodeVersion? {
        // Claude Code can land in a few typical spots; try each until we find one
        let fm = FileManager.default
        let candidates = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            NSHomeDirectory() + "/.claude/local/claude",
            NSHomeDirectory() + "/.local/bin/claude",
            "/usr/bin/claude",
        ]
        guard let claudePath = candidates.first(where: { fm.fileExists(atPath: $0) }) else {
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = ["--version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            return parseClaudeCodeVersion(from: output)
        } catch {
            return nil
        }
    }

    /// Extracts the first `X.Y.Z` token from arbitrary version output.
    /// Accepts any prefix/suffix — works for "2.1.88", "v2.1.88", "claude 2.1.88 (...)" etc.
    static func parseClaudeCodeVersion(from text: String) -> ClaudeCodeVersion? {
        let pattern = #"(\d+)\.(\d+)\.(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges == 4,
              let majorRange = Range(match.range(at: 1), in: text),
              let minorRange = Range(match.range(at: 2), in: text),
              let patchRange = Range(match.range(at: 3), in: text),
              let major = Int(text[majorRange]),
              let minor = Int(text[minorRange]),
              let patch = Int(text[patchRange])
        else { return nil }
        return ClaudeCodeVersion(major: major, minor: minor, patch: patch)
    }

    /// Returns the ordered list of (event, config) pairs to register, filtered
    /// to only events the installed Claude Code version knows about.
    private static func supportedHookEvents(
        for version: ClaudeCodeVersion?,
        withMatcher: [[String: Any]],
        withMatcherAndTimeout: [[String: Any]],
        withoutMatcher: [[String: Any]],
        preCompactConfig: [[String: Any]]
    ) -> [(String, [[String: Any]])] {
        // Baseline — present in every Claude Code version that supports hooks
        var events: [(String, [[String: Any]])] = [
            ("UserPromptSubmit", withoutMatcher),
            ("PreToolUse", withMatcher),
            ("PostToolUse", withMatcher),
            ("PermissionRequest", withMatcherAndTimeout),
            ("Notification", withMatcher),
            ("Stop", withoutMatcher),
            ("SubagentStop", withoutMatcher),
            ("SessionStart", withoutMatcher),
            ("SessionEnd", withoutMatcher),
            ("PreCompact", preCompactConfig),
        ]

        // Without a detected version, stick to the baseline — better to miss
        // features than to break settings.json on older Claude Code (#85).
        guard let version else { return events }

        // v2.0.x — PostToolUseFailure shipped alongside the PostToolUse redesign
        if version >= ClaudeCodeVersion(major: 2, minor: 0, patch: 0) {
            events.append(("PostToolUseFailure", withMatcher))
        }
        // v2.0.43 — SubagentStart, pairs with SubagentStop
        if version >= ClaudeCodeVersion(major: 2, minor: 0, patch: 43) {
            events.append(("SubagentStart", withoutMatcher))
        }
        // v2.1.76 — PostCompact, pairs with PreCompact
        if version >= ClaudeCodeVersion(major: 2, minor: 1, patch: 76) {
            events.append(("PostCompact", preCompactConfig))
        }
        // v2.1.78 — StopFailure on API errors (rate limit, auth, billing)
        if version >= ClaudeCodeVersion(major: 2, minor: 1, patch: 78) {
            events.append(("StopFailure", withoutMatcher))
        }
        // v2.1.88 — PermissionDenied for auto-mode classifier denials
        if version >= ClaudeCodeVersion(major: 2, minor: 1, patch: 88) {
            events.append(("PermissionDenied", withMatcher))
        }

        return events
    }

    /// Check if hooks are currently installed
    static func isInstalled() -> Bool {
        let settings = ClaudePaths.settingsFile

        guard let data = try? Data(contentsOf: settings),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else {
            return false
        }

        for (_, value) in hooks {
            if let entries = value as? [[String: Any]] {
                for entry in entries {
                    if let entryHooks = entry["hooks"] as? [[String: Any]] {
                        for hook in entryHooks {
                            if isNotchdHook(hook) {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }

    /// Uninstall hooks from settings.json and remove script
    static func uninstall() {
        let hooksDir = ClaudePaths.hooksDir
        let pythonScript = hooksDir.appendingPathComponent("notchd-state.py")
        let settings = ClaudePaths.settingsFile

        try? FileManager.default.removeItem(at: pythonScript)
        restoreStatusLine(at: settings, hooksDir: hooksDir)

        guard let data = try? Data(contentsOf: settings),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var hooks = json["hooks"] as? [String: Any] else {
            return
        }

        for (event, value) in hooks {
            if var entries = value as? [[String: Any]] {
                entries = entries.compactMap { removingNotchdHooks(from: $0) }

                if entries.isEmpty {
                    hooks.removeValue(forKey: event)
                } else {
                    hooks[event] = entries
                }
            }
        }

        if hooks.isEmpty {
            json.removeValue(forKey: "hooks")
        } else {
            json["hooks"] = hooks
        }

        if let data = try? JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            try? data.write(to: settings)
        }
    }

    /// On uninstall, put the user's original statusLine command back (or remove ours) and delete the forwarder files.
    private static func restoreStatusLine(at settingsURL: URL, hooksDir: URL) {
        let fm = FileManager.default
        let origFile = hooksDir.appendingPathComponent("notchd-statusline.orig")
        let forwarder = hooksDir.appendingPathComponent("notchd-statusline.py")

        // a pre-rename install keeps its original command in the old .orig file; uninstall also removes the shims
        migrateLegacyFiles(in: hooksDir, removeShims: true)

        if let data = try? Data(contentsOf: settingsURL),
           var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let current = json["statusLine"] as? [String: Any],
           let command = current["command"] as? String,
           command.contains("notchd-statusline.py") || legacyStatuslineScripts.contains(where: { command.contains($0) }) {
            if let original = try? String(contentsOf: origFile, encoding: .utf8),
               !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                var restored = current   // keeps other keys such as padding
                restored["command"] = original.trimmingCharacters(in: .whitespacesAndNewlines)
                json["statusLine"] = restored
            } else {
                json.removeValue(forKey: "statusLine")
            }
            if let out = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
                try? out.write(to: settingsURL)
            }
        }

        try? fm.removeItem(at: forwarder)
        try? fm.removeItem(at: origFile)
    }

    private static func detectPython() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["python3"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                return "python3"
            }
        } catch {}

        return "python"
    }

    nonisolated private static func removingNotchdHooks(from entry: [String: Any]) -> [String: Any]? {
        guard var entryHooks = entry["hooks"] as? [[String: Any]] else {
            return entry
        }

        entryHooks.removeAll(where: isNotchdHook)
        guard !entryHooks.isEmpty else { return nil }

        var updatedEntry = entry
        updatedEntry["hooks"] = entryHooks
        return updatedEntry
    }

    nonisolated private static func isNotchdHook(_ hook: [String: Any]) -> Bool {
        let cmd = hook["command"] as? String ?? ""
        return cmd.contains("notchd-state.py") || legacyStateScripts.contains { cmd.contains($0) }
    }

    // MARK: - Migration from the old names (claude-island, claude-notch, and claw-notch)

    /// Hook script names used before the app became Notchd. Entries pointing at them are ours and are replaced.
    nonisolated private static let legacyStateScripts = ["claude-island-state.py", "claude-notch-state.py", "claw-notch-state.py"]
    nonisolated private static let legacyStatuslineScripts = ["claude-island-statusline.py", "claude-notch-statusline.py", "claw-notch-statusline.py"]
    nonisolated private static let legacyOrigFiles = ["claude-island-statusline.orig", "claude-notch-statusline.orig", "claw-notch-statusline.orig"]

    /// Stand-ins for the old scripts. Claude Code sessions that were already running keep the old hook commands in memory;
    /// a missing script would make `python3` exit 2, which Claude Code treats as a blocking hook error. The shims exit 0
    /// (the statusline shim forwards to the new forwarder) and are deleted on uninstall.
    private static let legacyStateShim = """
    #!/usr/bin/env python3
    # Left by Notchd so sessions started before the rename keep working. Safe to delete.
    import sys
    sys.stdin.read()
    """
    private static let legacyStatuslineShim = """
    #!/usr/bin/env python3
    # Left by Notchd so sessions started before the rename keep working. Safe to delete.
    import os, subprocess, sys
    data = sys.stdin.read()
    new = os.path.join(os.path.dirname(os.path.abspath(__file__)), "notchd-statusline.py")
    if os.path.exists(new):
        out = subprocess.run([sys.executable, new], input=data, capture_output=True, text=True)
        sys.stdout.write(out.stdout)
    """

    /// Carry the user's original statusLine command across the rename and swap old scripts for harmless shims
    /// (`removeShims: true`, used by uninstall, deletes them instead).
    private static func migrateLegacyFiles(in hooksDir: URL, removeShims: Bool = false) {
        let fm = FileManager.default
        let newOrig = hooksDir.appendingPathComponent("notchd-statusline.orig")
        for name in legacyOrigFiles {
            let legacyOrig = hooksDir.appendingPathComponent(name)
            guard fm.fileExists(atPath: legacyOrig.path) else { continue }
            // A blank or missing new chain file must not win over the user's real original command
            let newText = (try? String(contentsOf: newOrig, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if newText.isEmpty {
                try? fm.removeItem(at: newOrig)
                try? fm.moveItem(at: legacyOrig, to: newOrig)
            } else {
                try? fm.removeItem(at: legacyOrig)
            }
        }
        let shims = legacyStateScripts.map { ($0, legacyStateShim) } + legacyStatuslineScripts.map { ($0, legacyStatuslineShim) }
        for (name, shim) in shims {
            let url = hooksDir.appendingPathComponent(name)
            guard fm.fileExists(atPath: url.path) else { continue }
            if removeShims {
                try? fm.removeItem(at: url)
            } else {
                try? (shim + "\n").write(to: url, atomically: true, encoding: .utf8)
                try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
            }
        }
    }
}
