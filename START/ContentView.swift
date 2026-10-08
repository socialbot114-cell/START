import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var players: PlayerStore
    @State private var newName: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    Text("QUEM COMEÇA?")
                        .font(.headline)
                        .foregroundColor(Theme.accentText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityIdentifier("start-title")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        NavigationLink {
                            DiceView()
                        } label: {
                            ModeTile(emoji: "🎲", title: "Dados", subtitle: "D4, D6, D8, D10, D12, D20")
                        }
                        .accessibilityIdentifier("mode-dice")

                        NavigationLink {
                            FingerPickerView()
                        } label: {
                            ModeTile(emoji: "👆", title: "Dedos na Tela", subtitle: "Escolha fisicamente")
                        }
                        .accessibilityIdentifier("mode-finger")

                        NavigationLink {
                            CardsView()
                        } label: {
                            ModeTile(emoji: "🃏", title: "Carta Alta", subtitle: "Quem tira a maior")
                        }
                        .accessibilityIdentifier("mode-cards")

                        NavigationLink {
                            SituationDeckView()
                        } label: {
                            ModeTile(emoji: "🎴", title: "Situações", subtitle: "Baralho de critérios")
                        }
                        .accessibilityIdentifier("mode-situations")
                    }

                    playersCard
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("START")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(Theme.accent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("START")
                .font(.system(size: 44, weight: .black))
                .foregroundColor(.white)
            Text("YOUR BOARD GAME COMPANION")
                .font(.caption)
                .tracking(2)
                .foregroundColor(Theme.mutedText)
            Text("Decida quem começa, role dados e sorteie critérios. Tudo offline.")
                .font(.subheadline)
                .foregroundColor(Theme.mutedText)
        }
        .accessibilityIdentifier("home-header")
    }

    private var playersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jogadores na mesa")
                .font(.headline)
                .foregroundColor(.white)
            if players.players.isEmpty {
                Text("Nenhum jogador. Os modos usam Jogador 1 e Jogador 2.")
                    .font(.subheadline)
                    .foregroundColor(Theme.mutedText)
            } else {
                ForEach(players.players, id: \.self) { name in
                    HStack {
                        Text(name).foregroundColor(.white)
                        Spacer()
                        Button(role: .destructive) {
                            if let idx = players.players.firstIndex(of: name) {
                                players.players.remove(at: idx)
                            }
                        } label: {
                            Image(systemName: "xmark.circle").foregroundColor(Theme.mutedText)
                        }
                        .accessibilityIdentifier("remove-\(name)")
                    }
                    .padding(.vertical, 2)
                }
            }
            HStack {
                TextField("Nome do jogador", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("player-name-field")
                Button("Adicionar") {
                    players.add(name: newName)
                    newName = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .foregroundColor(Theme.accentText)
                .accessibilityIdentifier("add-player-button")
            }
        }
        .startCard()
        .accessibilityIdentifier("players-card")
    }
}

struct ModeTile: View {
    var emoji: String
    var title: String
    var subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji).font(.largeTitle)
            Text(title).font(.headline).foregroundColor(.white)
            Text(subtitle).font(.caption).foregroundColor(Theme.mutedText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(12)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

#Preview {
    ContentView().environmentObject(PlayerStore())
}
