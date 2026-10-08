import SwiftUI

struct CardsView: View {
    @EnvironmentObject private var players: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @State private var draws: [(name: String, card: PlayingCard)] = []
    @State private var deck = PlayingCard.deck().shuffled()
    @State private var tiedNames: [String] = []
    @State private var dealCount = 0
    private let screenshotMode = ProcessInfo.processInfo.arguments.contains("-screenshot-mode")

    var body: some View {
        ZStack {
            TableBackground()
            ScrollView {
                VStack(spacing: 13) {
                    AppScreenHeader(title: "Carta mais alta") { dismiss() }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("O BARALHO DECIDE")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(1.7)
                            .foregroundColor(Theme.accent)
                        Text("Quem tira a maior?")
                            .font(.system(size: 23, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("Cada pessoa revela uma carta. A maior começa.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    if draws.isEmpty {
                        emptyDeck
                    } else {
                        VStack(spacing: 8) {
                            ForEach(draws, id: \.card.id) { entry in
                                cardRow(entry)
                            }
                        }
                        .padding(.horizontal, 18)

                        if let winner = winnerText {
                            HStack(spacing: 10) {
                                Image(systemName: winner.hasPrefix("Empate") ? "arrow.triangle.2.circlepath" : "crown.fill")
                                    .foregroundColor(Theme.accent)
                                Text(winner)
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.accent)
                                Spacer(minLength: 0)
                            }
                            .padding(13)
                            .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent.opacity(0.36), lineWidth: 1))
                            .padding(.horizontal, 18)
                            .accessibilityIdentifier("cards-result")
                        }
                    }

                    Button {
                        deal()
                    } label: {
                        HStack {
                            Image(systemName: draws.isEmpty ? "rectangle.stack.fill" : "arrow.triangle.2.circlepath")
                            Text(draws.isEmpty ? "DISTRIBUIR CARTAS" : (tiedNames.isEmpty ? "NOVA RODADA" : "DESEMPATAR"))
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .startPrimaryButton()
                    }
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("deal-cards-button")

                    Text("Baralho completo · sem repetir cartas na rodada")
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
            if ProcessInfo.processInfo.arguments.contains("-capture-cards"), draws.isEmpty { deal() }
        }
    }

    private var emptyDeck: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 23)
                .fill(.black.opacity(0.54))
                .overlay(RoundedRectangle(cornerRadius: 23).stroke(.white.opacity(0.15), lineWidth: 1))
            ZStack {
                playingCardBack(color: Theme.green).rotationEffect(.degrees(-13)).offset(x: -39, y: 3)
                playingCardBack(color: Color(red: 0.55, green: 0.17, blue: 0.10)).rotationEffect(.degrees(10)).offset(x: 39, y: 2)
                VStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(Theme.accent)
                    Text("QUEM VAI COMEÇAR?")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.3)
                        .foregroundColor(.white.opacity(0.82))
                }
                .offset(y: 76)
            }
        }
        .frame(height: 235)
        .padding(.horizontal, 18)
    }

    private func playingCardBack(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(colors: [color, color.opacity(0.63)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent.opacity(0.78), lineWidth: 1.4).padding(7))
            .overlay {
                Image(systemName: "sparkles")
                    .font(.system(size: 35, weight: .light))
                    .foregroundColor(.white.opacity(0.72))
            }
            .frame(width: 126, height: 180)
            .shadow(color: .black.opacity(0.38), radius: 13, x: 0, y: 9)
    }

    private func cardRow(_ entry: (name: String, card: PlayingCard)) -> some View {
        let winner = isWinner(entry)
        return HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(winner ? Theme.accent : .black.opacity(0.47))
                VStack(spacing: 0) {
                    Text(entry.card.rankLabel)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                    Text(entry.card.suit)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(winner ? Theme.accentText : (entry.card.isRed ? Color(red: 1, green: 0.40, blue: 0.31) : .white))
            }
            .frame(width: 38, height: 48)
            Text(entry.name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer(minLength: 0)
            if winner {
                Text("MAIOR")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(10)
        .background(winner ? Theme.accent.opacity(0.14) : .black.opacity(0.55), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(winner ? Theme.accent.opacity(0.76) : .white.opacity(0.12), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var winnerText: String? {
        guard let top = draws.map(\.card.rank).max() else { return nil }
        let winners = draws.filter { $0.card.rank == top }
        if winners.count == 1 { return "\(winners[0].name) COMEÇA!" }
        return "Empate entre \(winners.map(\.name).joined(separator: " e "))"
    }

    private func isWinner(_ entry: (name: String, card: PlayingCard)) -> Bool {
        guard let top = draws.map(\.card.rank).max() else { return false }
        return entry.card.rank == top
    }

    private func deal() {
        let names: [String]
        if !tiedNames.isEmpty {
            names = tiedNames
        } else {
            names = players.displayNames
        }
        dealCount += 1

        if screenshotMode && dealCount == 1 {
            let ranks = [7, 14, 10, 5]
            let suits = ["♦", "♥", "♠", "♣"]
            draws = Array(names.prefix(4).enumerated()).map { index, name in
                (name, PlayingCard(rank: ranks[index], suit: suits[index]))
            }
        } else {
            if deck.count < names.count { deck = PlayingCard.deck().shuffled() }
            draws = names.map { ($0, deck.removeFirst()) }
        }

        let top = draws.map(\.card.rank).max() ?? 0
        let winners = draws.filter { $0.card.rank == top }
        tiedNames = winners.count > 1 ? winners.map(\.name) : []
    }
}

#Preview {
    NavigationStack { CardsView().environmentObject(PlayerStore()) }
}
