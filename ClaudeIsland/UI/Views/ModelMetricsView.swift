//
//  ModelMetricsView.swift
//  ClaudeIsland
//
//  Token consumption per model over the last 7 days (from the transcripts, see ModelMetricsStore).
//

import SwiftUI

struct ModelMetricsView: View {
    @ObservedObject private var store = ModelMetricsStore.shared

    private let accent = Color(red: 0.85, green: 0.47, blue: 0.34)

    private struct Row: Identifiable {
        let id: String
        let name: String
        let usage: UsageInfo
    }

    private var rows: [Row] {
        store.byModel
            .map { Row(id: $0.key, name: Self.displayName($0.key), usage: $0.value) }
            .sorted { $0.usage.totalTokens > $1.usage.totalTokens }
    }

    var body: some View {
        let rows = rows
        let maxTokens = max(rows.first?.usage.totalTokens ?? 1, 1)

        if rows.isEmpty {
            VStack(spacing: 8) {
                Text(store.isScanning ? "Reading transcripts…" : "No usage in the last 7 days")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("Token counts per model appear here")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.25))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { store.refresh() }
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(rows) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(row.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                                Text(row.usage.formattedTotal)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(accent)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.08))
                                    Capsule()
                                        .fill(accent.opacity(0.85))
                                        .frame(width: geo.size.width * CGFloat(row.usage.totalTokens) / CGFloat(maxTokens))
                                }
                            }
                            .frame(height: 3)
                            Text("in \(Self.format(row.usage.inputTokens)) · out \(Self.format(row.usage.outputTokens)) · cache r \(Self.format(row.usage.cacheReadTokens)) / w \(Self.format(row.usage.cacheCreationTokens))")
                                .font(.system(size: 10))
                                .monospacedDigit()
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 14)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
            .onAppear { store.refresh() }
        }
    }

    private static func format(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }

    /// "claude-opus-4-5-20251101" -> "Opus 4.5"
    private static func displayName(_ model: String) -> String {
        var parts = model.replacingOccurrences(of: "claude-", with: "").split(separator: "-").map(String.init)
        if let last = parts.last, last.count == 8, Int(last) != nil { parts.removeLast() }
        guard let family = parts.first else { return model }
        let version = parts.dropFirst().joined(separator: ".")
        return version.isEmpty ? family.capitalized : "\(family.capitalized) \(version)"
    }
}
