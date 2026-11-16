//
//  ModelMetricsStore.swift
//  ClawNotch
//
//  Token consumption per model, scanned straight from the Claude transcripts (~/.claude/projects/**/*.jsonl)
//  so it does not depend on which sessions the app is currently tracking. Usage is bucketed per minute and per
//  model, so any time range (today, the 5-hour window, the weekly window, overall) is a cheap sum over buckets.
//  Incremental: each file is read once and then only the lines appended since the last scan.
//

import Combine
import Foundation

struct MetricsBucketKey: Hashable, Sendable {
    let minute: Int        // epoch seconds / 60
    let model: String
}

actor ModelMetricsScanner {
    private struct FileState {
        var offset: UInt64 = 0
        var buckets: [MetricsBucketKey: UsageInfo] = [:]
        var seen: Set<String> = []     // message ids already counted (a message is written once per content block)
    }

    private var states: [String: FileState] = [:]
    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private let isoPlain = ISO8601DateFormatter()

    /// All buckets. Only transcripts modified in the last `days` days are (re)read, or every transcript when `days` is nil.
    func scan(days: Int?) -> [MetricsBucketKey: UsageInfo] {
        let cutoff = days.map { Date().addingTimeInterval(-Double($0) * 86_400) }
        if let walker = FileManager.default.enumerator(
            at: ClaudePaths.projectsDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in walker where url.pathExtension == "jsonl" {
                guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                      let modified = values.contentModificationDate,
                      let size = values.fileSize else { continue }
                if let cutoff, modified < cutoff { continue }
                var state = states[url.path] ?? FileState()
                if UInt64(size) < state.offset { state = FileState() }       // truncated or replaced
                if UInt64(size) > state.offset { consume(url: url, into: &state) }
                states[url.path] = state
            }
        }

        var total: [MetricsBucketKey: UsageInfo] = [:]
        for state in states.values {
            for (key, usage) in state.buckets {
                total[key, default: UsageInfo()].add(usage)
            }
        }
        return total
    }

    private func consume(url: URL, into state: inout FileState) {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return }
        defer { try? handle.close() }
        guard (try? handle.seek(toOffset: state.offset)) != nil,
              let data = try? handle.readToEnd(), !data.isEmpty,
              let lastNewline = data.lastIndex(of: 0x0A) else { return }

        let complete = data.prefix(through: lastNewline)
        state.offset += UInt64(complete.count)
        let marker = Data("\"usage\"".utf8)

        for lineData in complete.split(separator: 0x0A, omittingEmptySubsequences: true) {
            // Cheap pre-filter before JSON parsing: only assistant lines carry usage.
            guard lineData.range(of: marker) != nil,
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  json["type"] as? String == "assistant",
                  let message = json["message"] as? [String: Any],
                  let usage = message["usage"] as? [String: Any],
                  let model = message["model"] as? String, !model.hasPrefix("<"),
                  let stamp = json["timestamp"] as? String,
                  let date = iso.date(from: stamp) ?? isoPlain.date(from: stamp) else { continue }

            if let id = message["id"] as? String {
                if state.seen.contains(id) { continue }
                state.seen.insert(id)
            }
            var add = UsageInfo()
            add.inputTokens = usage["input_tokens"] as? Int ?? 0
            add.outputTokens = usage["output_tokens"] as? Int ?? 0
            add.cacheReadTokens = usage["cache_read_input_tokens"] as? Int ?? 0
            add.cacheCreationTokens = usage["cache_creation_input_tokens"] as? Int ?? 0
            state.buckets[MetricsBucketKey(minute: Int(date.timeIntervalSince1970 / 60), model: model), default: UsageInfo()].add(add)
        }
    }
}

extension UsageInfo {
    mutating func add(_ other: UsageInfo) {
        inputTokens += other.inputTokens
        outputTokens += other.outputTokens
        cacheReadTokens += other.cacheReadTokens
        cacheCreationTokens += other.cacheCreationTokens
    }
}

@MainActor
final class ModelMetricsStore: ObservableObject {
    static let shared = ModelMetricsStore()

    @Published private(set) var buckets: [MetricsBucketKey: UsageInfo] = [:]
    @Published private(set) var isScanning = false

    private let scanner = ModelMetricsScanner()
    private var lastScan = Date.distantPast
    private var scannedAll = false

    /// Scan on demand (metrics view appears, range changes to Overall); at most once every 20s unless a wider scan is needed.
    /// Recent ranges read the last 8 days of transcripts; "overall" reads every transcript once (then stays incremental).
    func refresh(needsAll: Bool = false, force: Bool = false) {
        let wider = needsAll && !scannedAll
        guard !isScanning, force || wider || Date().timeIntervalSince(lastScan) > 20 else { return }
        isScanning = true
        lastScan = Date()
        let all = needsAll || scannedAll
        Task {
            let result = await scanner.scan(days: all ? nil : 8)
            buckets = result
            if all { scannedAll = true }
            isScanning = false
        }
    }

    /// When the notch was opened the time before this one (nil the very first time). The metrics view shows the tokens
    /// used since then, so "what did I spend since I last looked" is one glance.
    @Published private(set) var sinceLastOpen: Date?
    private static let lastOpenKey = "metricsLastOpenedAt"

    /// Call each time the notch opens: remembers the previous open time for display and stores this one.
    func markOpened() {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: Self.lastOpenKey) as? Date
        sinceLastOpen = previous
        defaults.set(Date(), forKey: Self.lastOpenKey)
        refresh(force: true)
    }

    /// Token totals per model for usage at or after `since` (nil = everything scanned).
    func totals(since: Date?) -> [String: UsageInfo] {
        let from = since.map { Int($0.timeIntervalSince1970 / 60) }
        var out: [String: UsageInfo] = [:]
        for (key, usage) in buckets where from == nil || key.minute >= from! {
            out[key.model, default: UsageInfo()].add(usage)
        }
        return out
    }
}
