import SwiftUI

struct CardsView: View {
    @EnvironmentObject private var players: PlayerStore
    @State private var draws: [(name: String, card: PlayingCard)] = []
    @State private var round: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Cada jogador tira uma carta. A maior vence. Empate = nova rodada só com os empatados.")
                    .font(.subheadline)
                    .foregroundColor(Theme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if draws.isEmpty {
                    Text("Toque em distribuir para começar.")
                        .foregroundColor(Theme.mutedText)
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                } else {
                    ForEach(draws, id: \.card.id) { entry in
                        HStack {
                            Text(entry.name)
                                .foregroundColor(.white)
                                .font(.headline)
                            Spacer()
                            Text(entry.card.label)
                                .font(.title2)
                                .foregroundColor(entry.card.isRed ? .red : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(12)
                        .background(isWinner(entry) ? Theme.accent.opacity(0.15) : Theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isWinner(entry) ? Theme.accent : Theme.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    if let winner = winnerText {
                        Text(winner)
                            .font(.headline)
                            .foregroundColor(Theme.accent)
                            .accessibilityIdentifier("cards-result")
                    }
                }

                Button(draws.isEmpty ? "Distribuir cartas" : "Nova rodada") {
                    deal()
                }
                .startPrimaryButton()
                .accessibilityIdentifier("deal-cards-button")
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Carta mais alta")
        .onAppear { if draws.isEmpty { deal() } }
    }

    private func deal() {
        round += 1
        let names: [String]
        if round == 1 {
            names = players.displayNames
        } else {
            let top = draws.map(\.card.rank).max() ?? 0
            let tied = draws.filter { $0.card.rank == top }.map(\.name)
            names = tied.count > 1 ? tied : players.displayNames
        }
        draws = names.map { ($0, PlayingCard.random()) }
    }

    private var winnerText: String? {
        guard !draws.isEmpty else { return nil }
        let top = draws.map(\.card.rank).max()!
        let winners = draws.filter { $0.card.rank == top }
        if winners.count == 1 {
            return "\(winners[0].name) VENCEU!"
        } else {
            return "Empate entre \(winners.map(\.name).joined(separator: ", ")). Toque para desempatar."
        }
    }

    private func isWinner(_ entry: (name: String, card: PlayingCard)) -> Bool {
        guard let top = draws.map(\.card.rank).max() else { return false }
        return entry.card.rank == top
    }
}

#Preview {
    NavigationStack { CardsView().environmentObject(PlayerStore()) }
}
