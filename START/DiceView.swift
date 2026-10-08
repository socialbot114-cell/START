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
    private let columns = [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)]

    var body: some View {
        ZStack {
            TableBackground()
            ScrollView {
                VStack(spacing: 13) {
                    AppScreenHeader(title: "Dados") { dismiss() }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("UM GIRO. UM DESTINO.")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(1.7)
                            .foregroundColor(Theme.accent)
                        Text("Role os dados")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("D4, D6, D8, D10, D12 e D20 — sorteio justo, sem internet.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(dice) { die in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                    sides = die.rawValue
                                    result = min(result, sides)
                                    hasRolled = false
                                }
                            } label: {
                                Text(die.label)
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundColor(sides == die.rawValue ? Theme.accentText : .white.opacity(0.86))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(sides == die.rawValue ? Theme.accent : .black.opacity(0.52), in: RoundedRectangle(cornerRadius: 11))
                                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(sides == die.rawValue ? .white.opacity(0.28) : .white.opacity(0.13), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("die-d\(die.rawValue)")
                        }
                    }
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("dice-picker")

                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 23)
                            .fill(LinearGradient(colors: [.black.opacity(0.74), Theme.cardRaised.opacity(0.93)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        RoundedRectangle(cornerRadius: 23)
                            .stroke(Theme.accent.opacity(0.28), lineWidth: 1)
                        Die3DView(sides: sides, result: result, rollToken: rollToken)
                            .padding(.horizontal, 8)
                            .padding(.top, 6)
                            .padding(.bottom, 32)
                            .accessibilityIdentifier("die-3d-view")
                        HStack(spacing: 6) {
                            Circle().fill(Theme.greenLight).frame(width: 6, height: 6)
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
                    .frame(height: 264)
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

                    Text("Cada face tem a mesma chance de sair.")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.54))
                        .padding(.bottom, 8)
                }
                .padding(.top, 7)
                .padding(.bottom, 18)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.72) {
            hasRolled = true
            rolling = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

#Preview {
    NavigationStack { DiceView() }
}
