import SwiftUI

enum AppRoute: String, Hashable {
    case chooseMethod
    case dice
    case finger
    case cards
    case situations
}

struct ContentView: View {
    @EnvironmentObject private var players: PlayerStore
    @State private var path: [AppRoute] = []
    @State private var showPlayers = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                TableBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        homeHeader
                        hero

                        Button {
                            path.append(.chooseMethod)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                Text("QUEM COMEÇA?")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .startPrimaryButton()
                        }
                        .accessibilityIdentifier("start-title")

                        HStack {
                            Text("ESCOLHA COMO COMEÇAR")
                                .font(.system(.caption, design: .rounded, weight: .heavy))
                                .tracking(1.2)
                                .foregroundColor(.white.opacity(0.83))
                            Spacer()
                            Text("04 MODOS")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Theme.accent)
                        }
                        .padding(.top, 2)

                        LazyVGrid(columns: columns, spacing: 11) {
                            modeLink(.dice, symbol: "die.face.5.fill", title: "Dados", subtitle: "D4 até D20", number: "01", id: "mode-dice")
                            modeLink(.finger, symbol: "hand.tap.fill", title: "Dedos na tela", subtitle: "Escolha no toque", number: "02", id: "mode-finger")
                            modeLink(.cards, symbol: "suit.spade.fill", title: "Carta mais alta", subtitle: "Quem tira a maior", number: "03", id: "mode-cards")
                            modeLink(.situations, symbol: "rectangle.stack.fill", title: "Cartas de situação", subtitle: "Quem combina?", number: "04", id: "mode-situations")
                        }

                        playerSummary
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 22)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .chooseMethod:
                    MethodChooserView { path.append($0) }
                case .dice:
                    DiceView()
                case .finger:
                    FingerPickerView()
                case .cards:
                    CardsView()
                case .situations:
                    SituationDeckView()
                }
            }
        }
        .tint(Theme.accent)
        .sheet(isPresented: $showPlayers) {
            PlayerManagerView()
                .environmentObject(players)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
    }

    private var homeHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                StartLogo()
                    .frame(height: 50, alignment: .leading)
                Text("YOUR BOARD GAME COMPANION")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(2.1)
                    .foregroundColor(Theme.mutedText)
                    .padding(.leading, 3)
            }
            Spacer()
            Button { showPlayers = true } label: {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.42), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
            }
            .accessibilityLabel("Editar jogadores")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Todo jogo tem uma grande história.")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text("E ela sempre começa por alguém.")
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.accent)
                .fixedSize(horizontal: false, vertical: true)
            Text("Decida quem começa. Rápido, divertido e sem internet.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(.vertical, 2)
        .accessibilityIdentifier("home-header")
    }

    private var playerSummary: some View {
        Button { showPlayers = true } label: {
            HStack(spacing: 11) {
                HStack(spacing: -8) {
                    ForEach(Array(players.displayNames.prefix(4).enumerated()), id: \.offset) { index, name in
                        Text(String(name.prefix(1)).uppercased())
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.accentText)
                            .frame(width: 29, height: 29)
                            .background([Theme.accent, Theme.greenLight, Color(red: 0.84, green: 0.41, blue: 0.24), Color(red: 0.64, green: 0.47, blue: 0.9)][index % 4])
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.background, lineWidth: 2))
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("MESA ATUAL")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.1)
                        .foregroundColor(Theme.mutedText)
                    Text("\(players.players.count) jogadores")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.44), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.11), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("players-summary")
    }

    private func modeLink(_ route: AppRoute, symbol: String, title: String, subtitle: String, number: String, id: String) -> some View {
        NavigationLink(value: route) {
            ModeTile(symbol: symbol, title: title, subtitle: subtitle, number: number)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

struct ModeTile: View {
    let symbol: String
    let title: String
    let subtitle: String
    let number: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.accent)
                    .frame(width: 37, height: 37)
                    .background(Theme.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                Spacer()
                Text(number)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.42))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 91, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.76), Theme.cardRaised.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 9, x: 0, y: 5)
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MethodChooserView: View {
    let onSelect: (AppRoute) -> Void
    @Environment(\.dismiss) private var dismiss
    private let methods: [(AppRoute, String, String, String)] = [
        (.dice, "die.face.5.fill", "Dados", "Role D4, D6, D8, D10, D12 ou D20"),
        (.finger, "hand.tap.fill", "Dedos na tela", "Todos escolhem ao mesmo tempo"),
        (.cards, "suit.spade.fill", "Carta mais alta", "Uma carta para cada jogador"),
        (.situations, "rectangle.stack.fill", "Cartas de situação", "Descubra quem combina com a frase")
    ]

    var body: some View {
        ZStack {
            TableBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    AppScreenHeader(title: "Escolha o método") { dismiss() }
                    Text("Como vamos descobrir quem começa?")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                    ForEach(Array(methods.enumerated()), id: \.offset) { _, method in
                        Button { onSelect(method.0) } label: {
                            HStack(spacing: 13) {
                                Image(systemName: method.1)
                                    .font(.system(size: 21, weight: .bold))
                                    .foregroundColor(Theme.accent)
                                    .frame(width: 48, height: 48)
                                    .background(Theme.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(method.2).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.white)
                                    Text(method.3).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Theme.mutedText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundColor(Theme.accent)
                            }
                            .startCard(padding: 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct PlayerManagerView: View {
    @EnvironmentObject private var players: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                TableBackground()
                VStack(alignment: .leading, spacing: 14) {
                    Text("Quem está na mesa?")
                        .font(.system(size: 23, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    ForEach(Array(players.players.enumerated()), id: \.offset) { index, name in
                        HStack(spacing: 10) {
                            Text(String(name.prefix(1)).uppercased())
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(Theme.accentText)
                                .frame(width: 32, height: 32)
                                .background(Theme.accent, in: Circle())
                            Text(name).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.white)
                            Spacer()
                            Button {
                                players.players.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundColor(.white.opacity(0.48))
                            }
                            .accessibilityLabel("Remover \(name)")
                        }
                        .padding(10)
                        .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 13))
                    }
                    HStack(spacing: 9) {
                        TextField("Nome do jogador", text: $newName)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("player-name-field")
                        Button("Adicionar") {
                            players.add(name: newName)
                            newName = ""
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.accentText)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 11)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 11))
                        .accessibilityIdentifier("add-player-button")
                    }
                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Concluir") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView().environmentObject(PlayerStore())
}
