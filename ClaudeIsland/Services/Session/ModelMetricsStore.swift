//
//  ModelMetricsStore.swift
//  ClaudeIsland
//
//  Token consumption per model, scanned straight from the Claude transcripts (~/.claude/projects/**/*.jsonl)
//  so it does not depend on which sessions the app is currently tracking. Incremental: each file is read once
//  and then only the lines appended since the last scan.
//

import Combine
import Foundation

actor ModelMetricsScanner {
    private struct FileState {
        var offset: UInt64 = 0
        var perModel: [String: UsageInfo] = [:]
        var seen: Set<String> = []     // message ids already counted (a message is written once per content block)
    }

    private var states: [String: FileState] = [:]

    /// Totals per model over transcripts modified in the last `days` days.
    func scan(days: Int) -> [String: UsageInfo] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86_400)
        let fm = FileManager.default
        var live: Set<String> = []

        if let walker = fm.enumerator(
            at: ClaudePaths.projectsDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in walker where url.pathExtension == "jsonl" {
                guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                      let modified = values.contentModificationDate, modified >= cutoff,
                      let size = values.fileSize else { continue }
                live.insert(url.path)
                var state = states[url.path] ?? FileState()
                if UInt64(size) < state.offset { state = FileState() }       // truncated or replaced
                if UInt64(size) > state.offset { Self.consume(url: url, into: &state) }
                states[url.path] = state
            }
        }

        states = states.filter { live.contains($0.key) }
        var total: [String: UsageInfo] = [:]
        for state in states.values {
            for (model, usage) in state.perModel {
                var t = total[model] ?? UsageInfo()
                t.inputTokens += usage.inputTokens
                t.outputTokens += usage.outputTokens
                t.cacheReadTokens += usage.cacheReadTokens
                t.cacheCreationTokens += usage.cacheCreationTokens
                total[model] = t
            }
        }
        return total
    }

    private static func consume(url: URL, into state: inout FileState) {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return }
        defer { try? handle.close() }
        guard (try? handle.seek(toOffset: state.offset)) != nil,
              let data = try? handle.readToEnd(), !data.isEmpty,
              let lastNewline = data.lastIndex(of: 0x0A) else { return }

        let complete = data.prefix(through: lastNewline)
        state.offset += UInt64(complete.count)

        for lineData in complete.split(separator: 0x0A, omittingEmptySubsequences: true) {
            // Cheap pre-filter before JSON parsing: only assistant lines carry usage.
            guard lineData.range(of: Data("\"usage\"".utf8)) != nil,
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  json["type"] as? String == "assistant",
                  let message = json["message"] as? [String: Any],
                  let usage = message["usage"] as? [String: Any],
                  let model = message["model"] as? String, !model.hasPrefix("<") else { continue }

            if let id = message["id"] as? String {
                if state.seen.contains(id) { continue }
                state.seen.insert(id)
            }
            var perModel = state.perModel[model] ?? UsageInfo()
            perModel.inputTokens += usage["input_tokens"] as? Int ?? 0
            perModel.outputTokens += usage["output_tokens"] as? Int ?? 0
            perModel.cacheReadTokens += usage["cache_read_input_tokens"] as? Int ?? 0
            perModel.cacheCreationTokens += usage["cache_creation_input_tokens"] as? Int ?? 0
            state.perModel[model] = perModel
        }
    }
}

@MainActor
final class ModelMetricsStore: ObservableObject {
    static let shared = ModelMetricsStore()

    @Published private(set) var byModel: [String: UsageInfo] = [:]
    @Published private(set) var isScanning = false

    private let scanner = ModelMetricsScanner()
    private var lastScan = Date.distantPast

    /// Scan on demand (when the metrics view appears or the notch opens); at most once every 20s.
    func refresh(days: Int = 7) {
        guard !isScanning, Date().timeIntervalSince(lastScan) > 20 else { return }
        isScanning = true
        lastScan = Date()
        Task {
            let result = await scanner.scan(days: days)
            byModel = result
            isScanning = false
        }
    }
}
