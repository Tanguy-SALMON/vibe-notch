//
//  UsageStore.swift
//  ClaudeIsland
//
//  Holds the Claude 5-hour / weekly rate-limit windows fed by the status line forwarder.
//

import Combine
import Foundation
import Security

@MainActor
final class UsageStore: ObservableObject {
    static let shared = UsageStore()

    struct Window: Equatable {
        var usedPercentage: Double   // 0...100
        var resetsAt: Date?
    }

    @Published private(set) var fiveHour: Window?
    @Published private(set) var sevenDay: Window?

    func update(from limits: [String: Any]) {
        let five = Self.parse(limits["five_hour"])
        let seven = Self.parse(limits["seven_day"])
        if fiveHour != five { fiveHour = five }
        if sevenDay != seven { sevenDay = seven }
    }

    nonisolated private static func parse(_ value: Any?) -> Window? {
        guard let dict = value as? [String: Any],
              let used = (dict["used_percentage"] as? NSNumber)?.doubleValue else { return nil }
        var reset: Date?
        if let ts = (dict["resets_at"] as? NSNumber)?.doubleValue {
            reset = Date(timeIntervalSince1970: ts)
        }
        return Window(usedPercentage: min(max(used, 0), 100), resetsAt: reset)
    }

    // MARK: - Polling (OAuth usage endpoint)

    private var lastFetch = Date.distantPast
    private var isFetching = false

    /// Fetch usage from Anthropic's usage endpoint using Claude Code's login token.
    /// Called at launch and whenever the notch is opened (no background polling), at most
    /// once every 30s. The status line feed (claude-island-statusline.py) updates the same
    /// store and acts as a fallback.
    func refreshIfStale() {
        guard !isFetching, Date().timeIntervalSince(lastFetch) > 30 else { return }
        isFetching = true
        lastFetch = Date()
        Task.detached(priority: .utility) { [weak self] in
            let limits = await Self.fetchUsage()
            await MainActor.run {
                if let limits { self?.update(from: limits) }
                self?.isFetching = false
            }
        }
    }

    nonisolated private static func readAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let st = SecItemCopyMatching(query as CFDictionary, &item)
        guard st == errSecSuccess,
              let data = item as? Data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String else { return nil }
        return token
    }

    /// Returns limits in the same shape the status line forwarder sends.
    nonisolated private static func fetchUsage() async -> [String: Any]? {
        guard let token = readAccessToken(),
              let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        func window(_ key: String) -> [String: Any]? {
            guard let w = json[key] as? [String: Any],
                  let used = (w["utilization"] as? NSNumber)?.doubleValue else { return nil }
            var out: [String: Any] = ["used_percentage": used]
            if let str = w["resets_at"] as? String, let date = iso.date(from: str) {
                out["resets_at"] = date.timeIntervalSince1970
            }
            return out
        }
        var limits: [String: Any] = [:]
        if let five = window("five_hour") { limits["five_hour"] = five }
        if let seven = window("seven_day") { limits["seven_day"] = seven }
        return limits.isEmpty ? nil : limits
    }
}
