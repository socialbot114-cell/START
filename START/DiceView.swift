import SwiftUI
import UIKit

struct DiceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sides: Int = 6
    @State private var result: Int = 4
    @State private var rollToken: Int = 0
    @State private var rolling = false
    @State private var hasRolled = false
    @State private var captureReelTask: Task<Void, Never>?

    private let dice = Dice.allCases
    private let captureReel: [(sides: Int, result: Int)] = [
        (4, 3), (6, 5), (8, 7), (10, 8), (12, 9), (20, 17)
    ]
    private var launchArguments: [String] { ProcessInfo.processInfo.arguments }
    private var screenshotMode: Bool { launchArguments.contains("-screenshot-mode") }
    private var captureStillSides: Int? {
        let prefix = "-capture-die-"
        guard let argument = launchArguments.first(where: { $0.hasPrefix(prefix) }),
              let sides = Int(String(argument.dropFirst(prefix.count))),
              dice.contains(where: { $0.rawValue == sides }) else { return nil }
        return sides
    }

    var body: some View {
        GeometryReader { geometry in
            let stageHeight = max(220, min(390, geometry.size.height - 340))

            ZStack {
                TableBackground()
                ScrollView {
                    VStack(spacing: 8) {
                        AppScreenHeader(title: "Dados") { dismiss() }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("UM GIRO. UM DESTINO.")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1.7)
                                .foregroundColor(Theme.accent)
                            Text("Role os dados")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("D4 a D20 · sorteio justo e offline")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.mutedText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal) {
                            HStack(spacing: 7) {
                                ForEach(dice) { die in
                                    Button {
                                        GameFeedback.impact(.soft)
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                            sides = die.rawValue
                                            result = min(result, sides)
                                            hasRolled = false
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Circle()
                                                .fill(resinColor(for: die.rawValue))
                                                .frame(width: 6, height: 6)
                                            Text(die.label)
                                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                        }
                                        .foregroundColor(sides == die.rawValue ? Theme.accentText : .white.opacity(0.86))
                                        .frame(width: 52)
                                        .padding(.vertical, 8)
                                        .background(sides == die.rawValue ? Theme.accent : .black.opacity(0.52), in: RoundedRectangle(cornerRadius: 11))
                                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(sides == die.rawValue ? .white.opacity(0.28) : .white.opacity(0.13), lineWidth: 1))
                                    }
                                    .buttonStyle(StartButtonMotionStyle())
                                    .accessibilityIdentifier("die-d\(die.rawValue)")
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .scrollIndicators(.hidden)
                        .accessibilityIdentifier("dice-picker")

                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 23)
                                .fill(LinearGradient(colors: [Color(red: 0.035, green: 0.075, blue: 0.065), .black.opacity(0.89)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            Circle()
                                .fill(RadialGradient(colors: [resinColor(for: sides).opacity(0.24), .clear], center: .center, startRadius: 5, endRadius: 115))
                                .frame(width: 230, height: 230)
                                .offset(y: -4)
                                .blur(radius: 10)
                                .allowsHitTesting(false)
                            RoundedRectangle(cornerRadius: 23)
                                .stroke(Theme.accent.opacity(0.24), lineWidth: 1)
                            Die3DView(sides: sides, result: result, rollToken: rollToken)
                                .padding(.horizontal, 8)
                                .padding(.top, 6)
                                .padding(.bottom, 32)
                                .accessibilityIdentifier("die-3d-view")
                            HStack(spacing: 6) {
                                Circle().fill(resinColor(for: sides)).frame(width: 6, height: 6)
                                Text(hasRolled ? "D\(sides)  ·  RESULTADO" : "D\(sides)  ·  PRONTO PARA ROLAR")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .tracking(1.2)
                                    .foregroundColor(.white.opacity(0.76))
                                Spacer()
                                if hasRolled {
                                    Text("\(result)")
                                        .font(.system(size: 21, weight: .black, design: .rounded))
                                        .foregroundColor(Theme.accent)
                                        .accessibilityIdentifier("dice-result")
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.bottom, 12)
                        }
                        .frame(height: stageHeight)
                        .padding(.horizontal, 18)

                        Button {
                            roll()
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: "arrow.clockwise")
                                Text(rolling ? "ROLANDO…" : "ROLAR D\(sides)")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .startPrimaryButton()
                        }
                        .disabled(rolling)
                        .padding(.horizontal, 20)
                        .accessibilityIdentifier("roll-dice-button")

                    }
                    .padding(.top, 3)
                    .padding(.bottom, 10)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if launchArguments.contains("-capture-dice-reel") {
                playCaptureReel()
            } else if let captureStillSides {
                showCaptureStill(for: captureStillSides)
            } else if launchArguments.contains("-capture-dice"), !hasRolled {
                roll()
            }
        }
        .onDisappear { captureReelTask?.cancel() }
    }

    private func showCaptureStill(for sides: Int) {
        self.sides = sides
        result = captureResult(for: sides)
        hasRolled = true
        rolling = false
    }

    private func playCaptureReel() {
        guard captureReelTask == nil else { return }
        captureReelTask = Task { @MainActor in
            for frame in captureReel {
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.22)) {
                    sides = frame.sides
                    result = frame.result
                    rolling = false
                    hasRolled = false
                }
                try? await Task.sleep(nanoseconds: 450_000_000)
                guard !Task.isCancelled else { break }
                roll(resultOverride: frame.result)
                try? await Task.sleep(nanoseconds: 2_850_000_000)
            }
            captureReelTask = nil
        }
    }

    private func captureResult(for sides: Int) -> Int {
        captureReel.first(where: { $0.sides == sides })?.result ?? min(4, sides)
    }

    private func roll(resultOverride: Int? = nil) {
        guard !rolling else { return }
        rolling = true
        hasRolled = false
        GameFeedback.impact(.medium)
        GameFeedback.play(.diceRoll)
        result = resultOverride ?? (screenshotMode ? min(4, sides) : Dice.roll(sides: sides))
        rollToken += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.08) {
            GameFeedback.impact(.heavy)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.30) {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                hasRolled = true
                rolling = false
            }
            GameFeedback.play(.winner)
            GameFeedback.success()
        }
    }

    private func resinColor(for sides: Int) -> Color {
        // Keep this palette aligned with RESIN_COLORS in the Blender asset generator.
        switch sides {
        case 4: return Color(red: 0.66, green: 0.075, blue: 0.085)
        case 6: return Color(red: 0.82, green: 0.77, blue: 0.65)
        case 8: return Color(red: 0.055, green: 0.20, blue: 0.50)
        case 10: return Color(red: 0.055, green: 0.35, blue: 0.21)
        case 12: return Color(red: 0.33, green: 0.105, blue: 0.52)
        default: return Color(red: 0.045, green: 0.13, blue: 0.45)
        }
    }
}

#Preview {
    NavigationStack { DiceView() }
}
