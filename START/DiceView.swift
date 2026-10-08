import SwiftUI

struct DiceView: View {
    @State private var sides: Int = 6
    @State private var result: Int = 6
    @State private var rolling: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Escolha o dado e role. Offline e imediato.")
                    .font(.subheadline)
                    .foregroundColor(Theme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Dice.allCases) { d in
                        Button(d.label) { sides = d.rawValue }
                            .font(.headline)
                            .foregroundColor(sides == d.rawValue ? Theme.accentText : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(sides == d.rawValue ? Theme.accent : Theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(sides == d.rawValue ? Theme.accent : Theme.cardBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .accessibilityIdentifier("dice-picker")

                Text("\(result)")
                    .font(.system(size: 96, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .accessibilityIdentifier("dice-result")
                    .accessibilityLabel("Resultado do dado: \(result)")

                Button(rolling ? "Rolando..." : "Rolar D\(sides)") {
                    roll()
                }
                .disabled(rolling)
                .startPrimaryButton()
                .accessibilityIdentifier("roll-dice-button")
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Dados")
    }

    private func roll() {
        rolling = true
        var ticks = 0
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            result = Dice.roll(sides: sides)
            ticks += 1
            if ticks >= 8 {
                timer.invalidate()
                rolling = false
            }
        }
    }
}

#Preview {
    NavigationStack { DiceView() }
}
