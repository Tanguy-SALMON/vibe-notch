//
//  ModelMetricsView.swift
//  ClawNotch
//
//  Token consumption per model for a chosen range: today, the current 5-hour window, the current weekly
//  window (both from the reset times Anthropic reports), or everything (from the transcripts, see ModelMetricsStore).
//

import SwiftUI

enum MetricsRange: String, CaseIterable, Identifiable {
    case today, fiveHour, week, overall

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: return "Today"
        case .fiveHour: return "5h"
        case .week: return "Week"
        case .overall: return "All"
        }
    }
}

struct ModelMetricsView: View {
    @ObservedObject private var store = ModelMetricsStore.shared
    @ObservedObject private var usageStore = UsageStore.shared
    @AppStorage("metricsRange") private var rangeRaw = MetricsRange.today.rawValue
    @AppStorage(ClockFormat.defaultsKey) private var use24HourTime = true

    private let accent = Color(red: 0.85, green: 0.47, blue: 0.34)

    private var range: MetricsRange { MetricsRange(rawValue: rangeRaw) ?? .today }

    private struct Row: Identifiable {
        let id: String
        let name: String
        let usage: UsageInfo
    }

    /// Start of the selected range (nil = everything).
    private var rangeStart: Date? {
        let now = Date()
        switch range {
        case .today:
            return Calendar.current.startOfDay(for: now)
        case .fiveHour:
            return windowStart(usageStore.fiveHour?.resetsAt, length: 5 * 3_600, now: now)
        case .week:
            return windowStart(usageStore.sevenDay?.resetsAt, length: 7 * 86_400, now: now)
        case .overall:
            return nil
        }
    }

    /// The window that ends at `reset`; once that reset has passed, a new window began at the reset.
    private func windowStart(_ reset: Date?, length: TimeInterval, now: Date) -> Date {
        guard let reset else { return now.addingTimeInterval(-length) }
        return reset > now ? reset.addingTimeInterval(-length) : reset
    }

    private var rangeCaption: String {
        guard let start = rangeStart else { return "all transcripts" }
        return "since \(ClockFormat.string(start, use24Hour: use24HourTime))"
    }

    private var rows: [Row] {
        store.totals(since: rangeStart)
            .map { Row(id: $0.key, name: Self.displayName($0.key), usage: $0.value) }
            .sorted { $0.usage.totalTokens > $1.usage.totalTokens }
    }

    var body: some View {
        VStack(spacing: 6) {
            picker
            content
        }
        .onAppear { store.refresh(needsAll: range == .overall) }
        .onChange(of: rangeRaw) { _, _ in store.refresh(needsAll: range == .overall) }
    }

    private var picker: some View {
        HStack(spacing: 4) {
            ForEach(MetricsRange.allCases) { option in
                Button {
                    rangeRaw = option.rawValue
                } label: {
                    Text(option.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(range == option ? .black : .white.opacity(0.55))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(range == option ? accent : Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Text(store.isScanning ? "reading…" : rangeCaption)
                .font(.system(size: 10))
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var content: some View {
        let rows = rows
        let maxTokens = max(rows.first?.usage.totalTokens ?? 1, 1)
        // Per-model tokens after the previous time the notch was opened (starting the minute after it)
        let sinceTotals = store.sinceLastOpen.map { store.totals(since: $0.addingTimeInterval(60)) }

        if rows.isEmpty {
            VStack(spacing: 8) {
                Text(store.isScanning ? "Reading transcripts…" : "No usage in this range")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("Token counts per model appear here")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.25))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            HStack(spacing: 8) {
                                Text("in \(Self.format(row.usage.inputTokens)) · out \(Self.format(row.usage.outputTokens)) · cache r \(Self.format(row.usage.cacheReadTokens)) / w \(Self.format(row.usage.cacheCreationTokens))")
                                    .font(.system(size: 10))
                                    .monospacedDigit()
                                    .foregroundColor(.white.opacity(0.4))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer(minLength: 0)
                                // Tokens used since the notch was last opened (stuck to the right, under the bar)
                                if let sinceTotals, let since = store.sinceLastOpen {
                                    let delta = sinceTotals[row.id]?.formattedTotal ?? "0"
                                    Text("+\(delta) since \(ClockFormat.string(since, use24Hour: use24HourTime))")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundColor(accent.opacity(0.85))
                                        .lineLimit(1)
                                        .fixedSize()
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
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
