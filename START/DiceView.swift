import SwiftUI
import UIKit

struct DiceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sides: Int = 6
    @State private var result: Int = 4
    @State private var rollToken: Int = 0
    @State private var rolling = false
    @State private var hasRolled = false

    private let dice = Dice.allCases
    private var launchArguments: [String] { ProcessInfo.processInfo.arguments }
    private var screenshotMode: Bool { launchArguments.contains("-screenshot-mode") }

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
            if launchArguments.contains("-capture-dice"), !hasRolled {
                roll()
            }
        }
    }

    private func roll() {
        guard !rolling else { return }
        rolling = true
        hasRolled = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        result = screenshotMode ? min(4, sides) : Dice.roll(sides: sides)
        rollToken += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.08) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.30) {
            hasRolled = true
            rolling = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func resinColor(for sides: Int) -> Color {
        switch sides {
        case 4: return Color(red: 0.84, green: 0.16, blue: 0.18)
        case 6: return Color(red: 0.88, green: 0.82, blue: 0.68)
        case 8: return Color(red: 0.10, green: 0.27, blue: 0.62)
        case 10: return Color(red: 0.10, green: 0.43, blue: 0.29)
        case 12: return Color(red: 0.48, green: 0.22, blue: 0.70)
        default: return Color(red: 0.10, green: 0.27, blue: 0.62)
        }
    }
}

#Preview {
    NavigationStack { DiceView() }
}
