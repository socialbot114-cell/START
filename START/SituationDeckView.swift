import SwiftUI

struct SituationDeckView: View {
    @State private var deck: [String] = SituationDeck.shuffled()
    @State private var index: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Sorteie um critério. O grupo identifica a pessoa. Se não houver resposta única, tire outra carta.")
                    .font(.subheadline)
                    .foregroundColor(Theme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    Text("CARTA \(min(index + 1, deck.count)) DE \(deck.count)")
                        .font(.caption)
                        .tracking(1.5)
                        .foregroundColor(Theme.mutedText)
                    Text(current)
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .frame(minHeight: 140)
                        .accessibilityIdentifier("situation-text")
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.accent.opacity(0.4), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))

                Text("Restam \(deck.count - index - 1) cartas no baralho")
                    .font(.caption)
                    .foregroundColor(Theme.mutedText)
                    .accessibilityIdentifier("situation-remaining")

                Button("Tirar outra carta") {
                    next()
                }
                .startPrimaryButton()
                .accessibilityIdentifier("next-situation-button")

                Button("Embaralhar de novo") {
                    deck = SituationDeck.shuffled()
                    index = 0
                }
                .font(.subheadline)
                .foregroundColor(Theme.accent)
                .accessibilityIdentifier("restart-situations-button")
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Situações")
    }

    private var current: String {
        guard index < deck.count else { return deck.last ?? "..." }
        return deck[index]
    }

    private func next() {
        if index + 1 < deck.count {
            index += 1
        } else {
            deck = SituationDeck.shuffled()
            index = 0
        }
    }
}

#Preview {
    NavigationStack { SituationDeckView() }
}
