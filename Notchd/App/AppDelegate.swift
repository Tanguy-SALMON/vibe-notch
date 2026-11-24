import AppKit
import IOKit
import Mixpanel
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager?
    private var screenObserver: ScreenObserver?

    static var shared: AppDelegate?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    /// One-time migration of settings from the legacy ClawNotch defaults domain (bundle id was renamed).
    /// Copies keys that are not already set, then flags it done. Must run before any view reads settings.
    private func migrateLegacyDefaults() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "migratedFromClawNotch") else { return }
        if let old = defaults.persistentDomain(forName: "com.tanguysalmon.clawnotch") {
            for (key, value) in old where defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }
        defaults.set(true, forKey: "migratedFromClawNotch")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single-instance check first: a duplicate launch must quit before touching defaults or analytics.
        if !ensureSingleInstance() {
            NSApplication.shared.terminate(nil)
            return
        }
        migrateLegacyDefaults()

        Mixpanel.initialize(token: "49814c1436104ed108f3fc4735228496")

        let distinctId = getOrCreateDistinctId()
        Mixpanel.mainInstance().identify(distinctId: distinctId)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let osVersion = Foundation.ProcessInfo.processInfo.operatingSystemVersionString

        Mixpanel.mainInstance().registerSuperProperties([
            "app_version": version,
            "build_number": build,
            "macos_version": osVersion
        ])

        fetchAndRegisterClaudeVersion()

        Mixpanel.mainInstance().people.set(properties: [
            "app_version": version,
            "build_number": build,
            "macos_version": osVersion
        ])

        Mixpanel.mainInstance().track(event: "App Launched")
        Mixpanel.mainInstance().flush()

        HookInstaller.installIfNeeded()
        NSApplication.shared.setActivationPolicy(.accessory)

        windowManager = WindowManager()
        _ = windowManager?.setupNotchWindow()
        UsageStore.shared.refreshIfStale()
        UsageStore.shared.startScheduler()

        screenObserver = ScreenObserver { [weak self] in
            self?.handleScreenChange()
        }
    }

    private func handleScreenChange() {
        _ = windowManager?.setupNotchWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        Mixpanel.mainInstance().flush()
        screenObserver = nil
    }

    private func getOrCreateDistinctId() -> String {
        let key = "mixpanel_distinct_id"

        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }

        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        defer { IOObjectRelease(platformExpert) }

        if let uuid = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String {
            UserDefaults.standard.set(uuid, forKey: key)
            return uuid
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    /// Scans the Claude projects directory off the main thread (it can hold many sessions), then registers the
    /// Claude Code version with analytics back on the main thread.
    private func fetchAndRegisterClaudeVersion() {
        let claudeProjectsDir = ClaudePaths.projectsDir
        Task.detached(priority: .utility) {
            guard let version = Self.latestClaudeVersion(in: claudeProjectsDir) else { return }
            await MainActor.run {
                Mixpanel.mainInstance().registerSuperProperties(["claude_code_version": version])
                Mixpanel.mainInstance().people.set(properties: ["claude_code_version": version])
            }
        }
    }

    nonisolated private static func latestClaudeVersion(in claudeProjectsDir: URL) -> String? {
        let fm = FileManager.default
        guard let projectDirs = try? fm.contentsOfDirectory(
            at: claudeProjectsDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return nil }

        var latestFile: URL?
        var latestDate: Date?

        for projectDir in projectDirs {
            guard let files = try? fm.contentsOfDirectory(
                at: projectDir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ) else { continue }

            for file in files where file.pathExtension == "jsonl" && !file.lastPathComponent.hasPrefix("agent-") {
                if let modDate = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                   latestDate.map({ modDate > $0 }) ?? true {
                    latestDate = modDate
                    latestFile = file
                }
            }
        }

        guard let jsonlFile = latestFile,
              let handle = FileHandle(forReadingAtPath: jsonlFile.path) else { return nil }
        defer { try? handle.close() }

        let data = handle.readData(ofLength: 8192)
        // The 8 KB read can cut a multi-byte character; decode lossily so the complete lines still parse.
        let content = String(decoding: data, as: UTF8.self)

        for line in content.components(separatedBy: .newlines) where !line.isEmpty {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let version = json["version"] as? String else { continue }
            return version
        }
        return nil
    }

    private func ensureSingleInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.tanguysalmon.notchd"
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleID
        }

        if runningApps.count > 1 {
            if let existingApp = runningApps.first(where: { $0.processIdentifier != getpid() }) {
                existingApp.activate()
            }
            return false
        }

        return true
    }
}
