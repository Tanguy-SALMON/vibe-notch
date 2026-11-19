//
//  AnimationDebugRow.swift
//  ClawNotch
//
//  The notch menu's "Animation Debug" row.
//

import SwiftUI

/// Expandable panel to review the Antics stories one by one on a 2x preview crab.
/// The preview always runs the Antics style, whatever Crab Style is saved, and only animates
/// while a story is playing. "Play all" is the old "Preview All Stories" switch: it also makes
/// the notch crab run every story in order when its style is Antics.
struct AnimationDebugRow: View {
    @ObservedObject private var controller = CrabStoryDebugController.shared
    @AppStorage(CrabStoryScheduler.debugLoopKey) private var playAll = false
    @State private var isExpanded = false
    @State private var isHovered = false

    private let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]

    /// Entry highlighted in the list
    private var current: CrabStory {
        playAll ? (controller.nowPlaying ?? controller.selected) : controller.selected
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                if !isExpanded { controller.stop() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "ladybug")
                        .font(.system(size: 12))
                        .foregroundColor(textColor)
                        .frame(width: 16)

                    Text("Animation Debug")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(textColor)

                    Spacer()

                    Text(playAll ? "Play all on" : "\(CrabStoryCatalog.all.count) stories")
                        .font(.system(size: 11))
                        .foregroundColor(playAll ? TerminalColors.green : .white.opacity(0.4))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }

            if isExpanded {
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        preview
                        controls
                    }

                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(CrabStoryCatalog.all) { story in
                            AnimationDebugEntry(story: story, isCurrent: story == current) {
                                playSingle { controller.play(story) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .onDisappear { controller.stop() }
            }
        }
    }

    /// 2x crab on a notch-black stage, with room for the props around it
    private var preview: some View {
        ClaudeCrabIcon(size: 30, mood: .idle, debug: controller.request(playAll: playAll))
            .padding(.top, 14)
            .frame(width: 124, height: 78)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("#\(current.number)  \(current.title)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)

            HStack(spacing: 6) {
                AnimationDebugButton(icon: "backward.end.fill", help: "Previous") {
                    playSingle { controller.previous() }
                }
                AnimationDebugButton(icon: "arrow.counterclockwise", label: "Replay", help: "Replay") {
                    playSingle { controller.replay() }
                }
                AnimationDebugButton(icon: "forward.end.fill", help: "Next") {
                    playSingle { controller.next() }
                }
            }

            HStack(spacing: 6) {
                AnimationDebugButton(label: "Loop this one", isOn: controller.looping, help: "Repeat the selected story") {
                    playAll = false
                    controller.looping.toggle()
                    if controller.looping { controller.replay() }
                }
                AnimationDebugButton(label: "Play all", isOn: playAll, help: "Every story in order, starting here") {
                    playAll.toggle()
                }
                AnimationDebugButton(label: "0.5x", isOn: controller.halfSpeed, help: "Half speed") {
                    controller.halfSpeed.toggle()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Any single-story action ends "Play all"
    private func playSingle(_ action: () -> Void) {
        playAll = false
        action()
    }

    private var textColor: Color {
        .white.opacity(isHovered ? 1.0 : 0.7)
    }
}

private struct AnimationDebugEntry: View {
    let story: CrabStory
    let isCurrent: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("\(story.number)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(isCurrent ? TerminalColors.green : .white.opacity(0.35))
                    .frame(width: 24, alignment: .trailing)

                Text(story.title)
                    .font(.system(size: 11, weight: isCurrent ? .semibold : .regular))
                    .foregroundColor(.white.opacity(isCurrent || isHovered ? 1 : 0.7))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(isCurrent ? 0.14 : (isHovered ? 0.08 : 0)))
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

private struct AnimationDebugButton: View {
    var icon: String?
    var label: String?
    var isOn = false
    let help: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                if let label {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .foregroundColor(isOn ? .black : .white.opacity(isHovered ? 1 : 0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isOn ? TerminalColors.green : Color.white.opacity(isHovered ? 0.18 : 0.1))
            )
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
    }
}
