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

                Picker("Dado", selection: $sides) {
                    ForEach(Dice.allCases) { d in
                        Text(d.label).tag(d.rawValue)
                    }
                }
                .pickerStyle(.segmented)
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
