//
//  UsageStore.swift
//  ClawNotch
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

    /// Set by the notch view: true while any Claude session is processing.
    var isActive = false
    private var boostUntil = Date.distantPast
    private var scheduler: Task<Void, Never>?

    /// Refresh cadence: every minute for 10 minutes after the notch was clicked/opened, every 5 minutes while a
    /// session is active, every 10 minutes otherwise (every 30 seconds whenever 20% or less of the quota remains).
    private var currentInterval: TimeInterval {
        let remaining = 100 - (fiveHour?.usedPercentage ?? 100)
        var interval: TimeInterval = Date() < boostUntil ? 60 : (isActive ? 300 : 600)
        if remaining <= 20 { interval = min(interval, 30) }
        return interval
    }

    /// A cheap 30-second tick that only fetches when the current interval has elapsed (no work in between).
    func startScheduler() {
        guard scheduler == nil else { return }
        scheduler = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                self?.refreshIfStale()
            }
        }
    }

    /// The notch was clicked or opened: fetch now and keep refreshing every minute for the next 10 minutes.
    func boost() {
        boostUntil = Date().addingTimeInterval(600)
        refreshIfStale(force: true)
    }

    /// Fetch usage from Anthropic's usage endpoint using Claude Code's login token, if the current interval has
    /// elapsed (or `force`, with a 5s floor). The status line feed (claw-notch-statusline.py) updates the same
    /// store and acts as a fallback.
    func refreshIfStale(force: Bool = false) {
        let minInterval: TimeInterval = force ? 5 : currentInterval
        guard !isFetching, Date().timeIntervalSince(lastFetch) >= minInterval - 1 else { return }
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
    /// The token is read from the Keychain once per launch and kept in memory (never written anywhere), so a plain
    /// "Allow" answer to the Keychain prompt is asked once, not on every fetch. An expired token (401/403) is re-read once.
    private final class TokenCache: @unchecked Sendable {
        private let lock = NSLock()
        private var token: String?
        func get() -> String? { lock.lock(); defer { lock.unlock() }; return token }
        func set(_ value: String?) { lock.lock(); token = value; lock.unlock() }
    }
    private static let tokenCache = TokenCache()

    nonisolated private static func request(token: String) async -> (Data, Int)? {
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let status = (response as? HTTPURLResponse)?.statusCode else { return nil }
        return (data, status)
    }

    nonisolated private static func fetchUsage() async -> [String: Any]? {
        guard let token = tokenCache.get() ?? readAccessToken() else { return nil }
        tokenCache.set(token)
        guard var (data, status) = await request(token: token) else { return nil }
        if status == 401 || status == 403 {          // expired: read the current token from the Keychain once more
            tokenCache.set(nil)
            guard let fresh = readAccessToken(), let retry = await request(token: fresh) else { return nil }
            tokenCache.set(fresh)
            (data, status) = retry
        }
        guard status == 200,
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
