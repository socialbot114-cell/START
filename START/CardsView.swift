import SwiftUI

enum PlayingCardStyle: String, CaseIterable, Identifiable {
    case classic
    case casino
    case vintage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return "Clássico"
        case .casino: return "Cassino"
        case .vintage: return "Vintage"
        }
    }

    var backColors: [Color] {
        switch self {
        case .classic: return [Color(red: 0.12, green: 0.37, blue: 0.27), Color(red: 0.035, green: 0.16, blue: 0.12)]
        case .casino: return [Color(red: 0.25, green: 0.13, blue: 0.16), Color(red: 0.055, green: 0.06, blue: 0.08)]
        case .vintage: return [Color(red: 0.53, green: 0.25, blue: 0.15), Color(red: 0.24, green: 0.08, blue: 0.055)]
        }
    }

    var paperColors: [Color] {
        switch self {
        case .classic: return [Color(red: 1.0, green: 0.99, blue: 0.95), Color(red: 0.93, green: 0.91, blue: 0.84)]
        case .casino: return [Color(red: 1.0, green: 1.0, blue: 0.98), Color(red: 0.93, green: 0.93, blue: 0.89)]
        case .vintage: return [Color(red: 0.98, green: 0.93, blue: 0.81), Color(red: 0.88, green: 0.79, blue: 0.63)]
        }
    }

    var ornament: Color {
        switch self {
        case .classic: return Theme.accentLight
        case .casino: return Color(red: 1.0, green: 0.76, blue: 0.32)
        case .vintage: return Color(red: 0.89, green: 0.67, blue: 0.36)
        }
    }
}

struct CardsView: View {
    @EnvironmentObject private var players: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draws: [(name: String, card: PlayingCard)] = []
    @State private var deck = PlayingCard.deck().shuffled()
    @State private var tiedNames: [String] = []
    @State private var dealCount = 0
    @State private var fanIsOpen = false
    @State private var showDeckBrowser = false
    @AppStorage("start.playingCardStyle") private var selectedStyleRawValue = "classic"
    private let screenshotMode = ProcessInfo.processInfo.arguments.contains("-screenshot-mode")

    private var selectedStyle: PlayingCardStyle {
        PlayingCardStyle(rawValue: selectedStyleRawValue) ?? .classic
    }

    private var captureCardStyle: PlayingCardStyle? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-capture-cards-casino") { return .casino }
        if arguments.contains("-capture-cards-vintage") { return .vintage }
        if arguments.contains("-capture-cards") { return .classic }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TableBackground()
                ScrollView {
                    VStack(spacing: 0) {
                        AppScreenHeader(title: "Carta alta") { dismiss() }
                        Spacer(minLength: 16)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("O BARALHO DECIDE")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1.7)
                                .foregroundColor(Theme.accent)
                            Text("Quem tira a maior?")
                                .font(.system(size: 25, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("Uma carta para cada pessoa. A maior começa.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        deckStylePicker
                        deckInventoryButton
                        Spacer(minLength: 18)

                        if draws.isEmpty {
                            emptyDeck
                        } else {
                            dealtCards(availableWidth: geometry.size.width)

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
                                .padding(.top, 8)
                                .accessibilityIdentifier("cards-result")
                            }
                        }
                        Spacer(minLength: 18)

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
                            .padding(.top, 12)
                        Spacer(minLength: 14)
                    }
                    .padding(.top, 3)
                    .padding(.bottom, 18)
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
            if ProcessInfo.processInfo.arguments.contains("-capture-full-deck") {
                selectedStyleRawValue = PlayingCardStyle.classic.rawValue
                showDeckBrowser = true
            }
            if let captureCardStyle {
                selectedStyleRawValue = captureCardStyle.rawValue
                if draws.isEmpty { deal() }
            }
        }
        .sheet(isPresented: $showDeckBrowser) {
            FullDeckBrowser(style: selectedStyle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
    }

    private var deckStylePicker: some View {
        HStack(spacing: 8) {
            ForEach(PlayingCardStyle.allCases) { style in
                let isSelected = selectedStyle == style
                Button {
                    GameFeedback.impact(.soft)
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                        selectedStyleRawValue = style.rawValue
                    }
                } label: {
                    VStack(spacing: 5) {
                        PlayingCardBackView(style: style, width: 31)
                        Text(style.title)
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? Theme.accentLight : .white.opacity(0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? style.backColors[0].opacity(0.42) : .black.opacity(0.28), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(isSelected ? Theme.accent.opacity(0.72) : .white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(StartButtonMotionStyle())
                .accessibilityLabel("Estilo de baralho: \(style.title)")
                .accessibilityIdentifier("card-style-\(style.id)")
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 13)
    }

    private var deckInventoryButton: some View {
        Button {
            GameFeedback.impact(.soft)
            showDeckBrowser = true
        } label: {
            HStack(spacing: 11) {
                ZStack {
                    PlayingCardBackView(style: selectedStyle, width: 34)
                        .rotationEffect(.degrees(-9))
                        .offset(x: -5, y: 2)
                    PlayingCardBackView(style: selectedStyle, width: 34)
                        .rotationEffect(.degrees(7))
                        .offset(x: 5, y: -1)
                }
                .frame(width: 48, height: 55)

                VStack(alignment: .leading, spacing: 3) {
                    Text("BARALHO COMPLETO")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(.white.opacity(0.86))
                    Text("\(deck.count) cartas disponíveis")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.mutedText)
                }
                Spacer(minLength: 4)
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Theme.accentLight, Theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Circle().stroke(.white.opacity(0.62), lineWidth: 1).padding(3)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Theme.accentText)
                }
                .frame(width: 34, height: 34)
                .shadow(color: Theme.accent.opacity(0.28), radius: 7, x: 0, y: 3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(LinearGradient(colors: [Theme.cardRaised.opacity(0.84), .black.opacity(0.50)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Theme.accent.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(StartButtonMotionStyle())
        .accessibilityLabel("Abrir baralho completo, \(deck.count) cartas restantes")
        .accessibilityIdentifier("open-full-deck")
        .padding(.horizontal, 18)
        .padding(.top, 9)
    }

    private var emptyDeck: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(colors: [Theme.card.opacity(0.88), .black.opacity(0.66)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.14), lineWidth: 1))
            ZStack {
                PlayingCardBackView(style: selectedStyle, width: 126)
                    .rotationEffect(.degrees(fanIsOpen ? -14 : -10))
                    .offset(x: fanIsOpen ? -44 : -38, y: fanIsOpen ? -5 : 3)
                PlayingCardBackView(style: selectedStyle, width: 126)
                    .rotationEffect(.degrees(fanIsOpen ? 13 : 9))
                    .offset(x: fanIsOpen ? 44 : 38, y: fanIsOpen ? -5 : 3)
                PlayingCardBackView(style: selectedStyle, width: 126)
                    .rotationEffect(.degrees(fanIsOpen ? 1 : 0))
                    .offset(y: fanIsOpen ? -12 : -2)
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Theme.accent)
                    Text("UMA CARTA PARA CADA JOGADOR")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.3)
                        .foregroundColor(.white.opacity(0.82))
                }
                .offset(y: 98)
            }
        }
        .frame(height: 286)
        .padding(.horizontal, 18)
        .onAppear {
            guard !reduceMotion else {
                fanIsOpen = true
                return
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                fanIsOpen = true
            }
        }
    }

    private func dealtCards(availableWidth: CGFloat) -> some View {
        let visibleCount = max(1, min(draws.count, 4))
        let gap: CGFloat = 8
        let stageWidth = min(560, availableWidth) - 36
        let cardWidth = min(122, max(58, (stageWidth - gap * CGFloat(visibleCount - 1) - 24) / CGFloat(visibleCount)))
        let cardHeight = cardWidth * 1.43
        let winningCardIndex = tiedNames.isEmpty ? draws.firstIndex(where: { isWinner($0) }) : nil

        return ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color(red: 0.035, green: 0.075, blue: 0.065), .black.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.accent.opacity(0.26), lineWidth: 1)

            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: gap) {
                    ForEach(Array(draws.enumerated()), id: \.element.card.id) { index, entry in
                        DealtPlayingCardView(
                            name: entry.name,
                            card: entry.card,
                            isWinner: isWinner(entry),
                            style: selectedStyle,
                            celebrates: winningCardIndex == index,
                            index: index,
                            width: cardWidth
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .frame(minWidth: stageWidth, minHeight: cardHeight + 42, alignment: .center)
            }
            .scrollIndicators(.hidden)
        }
        .frame(height: cardHeight + 42)
        .padding(.horizontal, 18)
        .accessibilityIdentifier("cards-table")
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
        GameFeedback.impact(.soft)
        let names: [String]
        if !tiedNames.isEmpty {
            names = tiedNames
        } else {
            names = players.displayNames
        }
        dealCount += 1

        let newDraws: [(name: String, card: PlayingCard)]
        if screenshotMode && dealCount == 1 {
            let ranks = [7, 14, 12, 5]
            let suits = ["♦", "♥", "♠", "♣"]
            newDraws = Array(names.prefix(4).enumerated()).map { index, name in
                (name, PlayingCard(rank: ranks[index], suit: suits[index]))
            }
            let drawnLabels = Set(newDraws.map { $0.card.label })
            deck.removeAll { drawnLabels.contains($0.label) }
        } else {
            if deck.count < names.count { deck = PlayingCard.deck().shuffled() }
            newDraws = names.map { ($0, deck.removeFirst()) }
        }

        let top = newDraws.map(\.card.rank).max() ?? 0
        let winners = newDraws.filter { $0.card.rank == top }
        withAnimation(.spring(response: 0.46, dampingFraction: 0.80)) {
            draws = newDraws
            tiedNames = winners.count > 1 ? winners.map(\.name) : []
        }
    }
}

private struct FullDeckBrowser: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cards = PlayingCard.deck()
    let style: PlayingCardStyle

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    private let suits = ["♠", "♥", "♦", "♣"]

    var body: some View {
        ZStack {
            TableBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BARALHO COMPLETO")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1.6)
                                .foregroundColor(Theme.accent)
                            Text("52 cartas")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.accent)
                                .frame(width: 38, height: 38)
                                .background(.black.opacity(0.48), in: Circle())
                                .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
                        }
                        .buttonStyle(StartButtonMotionStyle())
                        .accessibilityLabel("Fechar baralho")
                        .accessibilityIdentifier("close-full-deck")
                    }

                    ForEach(suits, id: \.self) { suit in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack(spacing: 7) {
                                Text(suit)
                                    .font(.system(size: 17, weight: .black, design: .serif))
                                    .foregroundColor(isRedSuit(suit) ? Color(red: 0.94, green: 0.32, blue: 0.27) : Theme.accent)
                                Text(suitName(suit).uppercased())
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .tracking(1.2)
                                    .foregroundColor(.white.opacity(0.72))
                                Spacer()
                                Text("13 CARTAS")
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .tracking(0.8)
                                    .foregroundColor(.white.opacity(0.42))
                            }

                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(cards.filter { $0.suit == suit }) { card in
                                    VStack(spacing: 4) {
                                        PlayingCardFaceView(card: card, isWinner: false, style: style, width: 70)
                                            .frame(width: 70, height: 100)
                                        Text(card.label)
                                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                                            .foregroundColor(.white.opacity(0.62))
                                    }
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("Carta \(card.rankLabel) de \(suitName(suit))")
                                    .accessibilityIdentifier("full-deck-card-\(suit)-\(card.rank)")
                                }
                            }
                        }
                        .padding(12)
                        .background(.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 17))
                        .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.08), lineWidth: 1))
                    }
                }
                .padding(18)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.background)
    }

    private func isRedSuit(_ suit: String) -> Bool {
        suit == "♥" || suit == "♦"
    }

    private func suitName(_ suit: String) -> String {
        switch suit {
        case "♠": return "Espadas"
        case "♥": return "Copas"
        case "♦": return "Ouros"
        default: return "Paus"
        }
    }
}

private struct DealtPlayingCardView: View {
    let name: String
    let card: PlayingCard
    let isWinner: Bool
    let style: PlayingCardStyle
    let celebrates: Bool
    let index: Int
    let width: CGFloat
    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var height: CGFloat { width * 1.43 }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                PlayingCardBackView(style: style, width: width)
                    .rotation3DEffect(.degrees(!reduceMotion && isRevealed ? 90 : 0), axis: (x: 0, y: 1, z: 0))
                    .opacity(isRevealed ? 0 : 1)
                PlayingCardFaceView(card: card, isWinner: isWinner, style: style, width: width)
                    .rotation3DEffect(.degrees(!reduceMotion && !isRevealed ? -90 : 0), axis: (x: 0, y: 1, z: 0))
                    .opacity(isRevealed ? 1 : 0)
            }
            .frame(width: width, height: height)
            .shadow(color: isWinner ? Theme.accent.opacity(0.26) : .black.opacity(0.36), radius: isWinner ? 12 : 7, x: 0, y: 6)

            Text(name)
                .font(.system(size: max(9, width * 0.13), weight: .bold, design: .rounded))
                .foregroundColor(isWinner ? Theme.accent : .white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: width)
        }
        .frame(width: width)
        .offset(y: isRevealed ? 0 : 18)
        .opacity(isRevealed ? 1 : 0.55)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(card.label)\(isWinner ? ", maior carta" : "")")
        .accessibilityIdentifier("dealt-card-\(index)")
        .task {
            if !reduceMotion {
                try? await Task.sleep(nanoseconds: UInt64(90 + index * 125) * 1_000_000)
            }
            guard !Task.isCancelled else { return }
            if celebrates {
                GameFeedback.play(.winner)
                GameFeedback.success()
            } else {
                GameFeedback.play(.cardFlip)
            }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.12) : .spring(response: 0.50, dampingFraction: 0.72)) {
                isRevealed = true
            }
        }
    }
}

private struct PlayingCardFaceView: View {
    let card: PlayingCard
    let isWinner: Bool
    let style: PlayingCardStyle
    let width: CGFloat

    private var height: CGFloat { width * 1.43 }
    private var ink: Color { card.isRed ? Color(red: 0.78, green: 0.10, blue: 0.14) : Color(red: 0.10, green: 0.12, blue: 0.14) }

    var body: some View {
        RoundedRectangle(cornerRadius: width * 0.14)
            .fill(LinearGradient(colors: style.paperColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                CardPaperGrain(ink: ink)
                    .clipShape(RoundedRectangle(cornerRadius: width * 0.14))
            }
            .overlay {
                RoundedRectangle(cornerRadius: width * 0.14)
                    .stroke(style.ornament.opacity(0.34), lineWidth: 0.55)
                    .padding(width * 0.055)
            }
            .overlay {
                VStack(alignment: .leading, spacing: 0) {
                    cornerIndex
                    Spacer(minLength: 2)
                    centerMark
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Spacer(minLength: 2)
                    cornerIndex
                        .rotationEffect(.degrees(180))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(width * 0.09)
            }
            .overlay {
                RoundedRectangle(cornerRadius: width * 0.14)
                    .stroke(isWinner ? Theme.accent : .black.opacity(0.13), lineWidth: isWinner ? 2.4 : 0.8)
                    .padding(isWinner ? 1 : 0)
            }
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }

    private var cornerIndex: some View {
        VStack(spacing: -2) {
            Text(card.rankLabel)
                .font(.system(size: max(10, width * 0.17), weight: .black, design: .serif))
            Text(card.suit)
                .font(.system(size: max(9, width * 0.14), weight: .bold, design: .serif))
        }
        .foregroundColor(ink)
    }

    @ViewBuilder
    private var centerMark: some View {
        if card.rank == 14 {
            Text(card.suit)
                .font(.system(size: width * 0.55, weight: .regular, design: .serif))
                .foregroundColor(ink)
        } else if card.rank >= 11 {
            CourtCardArt(card: card, style: style, width: width)
        } else {
            GeometryReader { geometry in
                ForEach(Array(pipPositions.enumerated()), id: \.offset) { _, point in
                    Text(card.suit)
                        .font(.system(size: width * (card.rank == 2 ? 0.20 : 0.16), weight: .semibold, design: .serif))
                        .foregroundColor(ink.opacity(0.94))
                        .position(x: geometry.size.width * point.x, y: geometry.size.height * point.y)
                }
            }
        }
    }

    private var pipPositions: [CGPoint] {
        switch card.rank {
        case 2: return [CGPoint(x: 0.5, y: 0.29), CGPoint(x: 0.5, y: 0.71)]
        case 3: return [CGPoint(x: 0.5, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 0.75)]
        case 4: return [CGPoint(x: 0.34, y: 0.28), CGPoint(x: 0.66, y: 0.28), CGPoint(x: 0.34, y: 0.72), CGPoint(x: 0.66, y: 0.72)]
        case 5: return [CGPoint(x: 0.34, y: 0.25), CGPoint(x: 0.66, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.34, y: 0.75), CGPoint(x: 0.66, y: 0.75)]
        case 6: return [CGPoint(x: 0.34, y: 0.22), CGPoint(x: 0.66, y: 0.22), CGPoint(x: 0.34, y: 0.5), CGPoint(x: 0.66, y: 0.5), CGPoint(x: 0.34, y: 0.78), CGPoint(x: 0.66, y: 0.78)]
        case 7: return [CGPoint(x: 0.32, y: 0.18), CGPoint(x: 0.68, y: 0.18), CGPoint(x: 0.32, y: 0.5), CGPoint(x: 0.68, y: 0.5), CGPoint(x: 0.32, y: 0.82), CGPoint(x: 0.68, y: 0.82), CGPoint(x: 0.5, y: 0.34)]
        case 8: return pipPositionsForEight
        case 9: return [CGPoint(x: 0.32, y: 0.22), CGPoint(x: 0.5, y: 0.22), CGPoint(x: 0.68, y: 0.22), CGPoint(x: 0.32, y: 0.5), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.68, y: 0.5), CGPoint(x: 0.32, y: 0.78), CGPoint(x: 0.5, y: 0.78), CGPoint(x: 0.68, y: 0.78)]
        default: return pipPositionsForEight + [CGPoint(x: 0.5, y: 0.29), CGPoint(x: 0.5, y: 0.71)]
        }
    }

    private var pipPositionsForEight: [CGPoint] {
        [CGPoint(x: 0.32, y: 0.12), CGPoint(x: 0.68, y: 0.12), CGPoint(x: 0.32, y: 0.37), CGPoint(x: 0.68, y: 0.37), CGPoint(x: 0.32, y: 0.63), CGPoint(x: 0.68, y: 0.63), CGPoint(x: 0.32, y: 0.88), CGPoint(x: 0.68, y: 0.88)]
    }
}

private struct CourtCardArt: View {
    let card: PlayingCard
    let style: PlayingCardStyle
    let width: CGFloat

    private var ink: Color { card.isRed ? Color(red: 0.78, green: 0.10, blue: 0.14) : Color(red: 0.10, green: 0.12, blue: 0.14) }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: width * 0.08)
                    .fill(style.ornament.opacity(0.09))
                    .overlay(RoundedRectangle(cornerRadius: width * 0.08).stroke(style.ornament.opacity(0.54), lineWidth: 0.8))
                Circle()
                    .fill(style.ornament.opacity(0.10))
                    .overlay(Circle().stroke(style.ornament.opacity(0.42), lineWidth: 0.7))
                    .frame(width: min(width * 0.52, geometry.size.height * 0.86))
                CourtPortrait(
                    rank: card.rank,
                    ink: ink,
                    ornament: style.ornament,
                    paper: style.paperColors[0]
                )
                Text(card.suit)
                    .font(.system(size: width * 0.16, weight: .black, design: .serif))
                    .foregroundColor(ink)
                    .offset(y: geometry.size.height * 0.37)
            }
        }
    }
}

private struct CardPaperGrain: View {
    let ink: Color

    var body: some View {
        Canvas { context, size in
            for fiber in 0..<72 {
                let x = CGFloat((fiber * 37 + 11) % 101) / 101 * size.width
                let y = CGFloat((fiber * 61 + 7) % 97) / 97 * size.height
                let length = CGFloat(2 + fiber % 7)
                var grain = Path()
                grain.move(to: CGPoint(x: x, y: y))
                grain.addLine(to: CGPoint(x: min(size.width, x + length), y: y + 0.35))
                context.stroke(grain, with: .color(ink.opacity(0.025)), lineWidth: 0.3)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct CourtPortrait: View {
    let rank: Int
    let ink: Color
    let ornament: Color
    let paper: Color

    var body: some View {
        Canvas { context, size in
            let point: (CGFloat, CGFloat) -> CGPoint = { x, y in
                CGPoint(x: size.width * x, y: size.height * y)
            }
            let head = CGRect(x: size.width * 0.39, y: size.height * 0.27, width: size.width * 0.22, height: size.height * 0.30)
            let leftEar = CGRect(x: size.width * 0.35, y: size.height * 0.37, width: size.width * 0.075, height: size.height * 0.10)
            let rightEar = CGRect(x: size.width * 0.575, y: size.height * 0.37, width: size.width * 0.075, height: size.height * 0.10)

            var robe = Path()
            robe.move(to: point(0.18, 0.92))
            robe.addCurve(to: point(0.82, 0.92), control1: point(0.20, 0.62), control2: point(0.80, 0.62))
            robe.addLine(to: point(0.69, 0.58))
            robe.addLine(to: point(0.31, 0.58))
            robe.closeSubpath()
            context.fill(robe, with: .color(ornament.opacity(0.70)))
            context.stroke(robe, with: .color(ink.opacity(0.88)), lineWidth: max(0.7, size.width * 0.012))

            var stitching = context
            stitching.clip(to: robe)
            for row in 0..<9 {
                let y = size.height * (0.65 + CGFloat(row) * 0.035)
                var hatch = Path()
                hatch.move(to: CGPoint(x: size.width * 0.22, y: y))
                hatch.addLine(to: CGPoint(x: size.width * 0.78, y: y - size.height * 0.08))
                stitching.stroke(hatch, with: .color(paper.opacity(0.40)), lineWidth: 0.45)
            }

            var neck = Path()
            neck.addRoundedRect(in: CGRect(x: size.width * 0.45, y: size.height * 0.49, width: size.width * 0.10, height: size.height * 0.14), cornerSize: CGSize(width: size.width * 0.025, height: size.width * 0.025))
            context.fill(neck, with: .color(paper))
            context.stroke(neck, with: .color(ink.opacity(0.8)), lineWidth: 0.65)

            context.fill(Path(ellipseIn: leftEar), with: .color(paper))
            context.fill(Path(ellipseIn: rightEar), with: .color(paper))
            context.fill(Path(ellipseIn: head), with: .color(paper))
            context.stroke(Path(ellipseIn: head), with: .color(ink), lineWidth: max(0.7, size.width * 0.012))

            var hair = Path()
            hair.move(to: point(0.38, 0.40))
            hair.addCurve(to: point(0.62, 0.40), control1: point(0.35, 0.16), control2: point(0.65, 0.16))
            hair.addLine(to: point(0.59, 0.34))
            hair.addCurve(to: point(0.41, 0.34), control1: point(0.55, 0.25), control2: point(0.45, 0.25))
            hair.closeSubpath()
            context.fill(hair, with: .color(ink))

            for eyeX in [CGFloat(0.45), 0.55] {
                let eye = CGRect(x: size.width * eyeX - size.width * 0.012, y: size.height * 0.40, width: size.width * 0.024, height: size.height * 0.025)
                context.fill(Path(ellipseIn: eye), with: .color(ink))
            }
            var nose = Path()
            nose.move(to: point(0.50, 0.42))
            nose.addLine(to: point(0.48, 0.48))
            nose.addLine(to: point(0.51, 0.49))
            context.stroke(nose, with: .color(ink.opacity(0.72)), lineWidth: 0.6)

            if rank == 11 {
                var cap = Path()
                cap.move(to: point(0.35, 0.31))
                cap.addQuadCurve(to: point(0.64, 0.30), control: point(0.49, 0.18))
                cap.addLine(to: point(0.61, 0.34))
                cap.addLine(to: point(0.38, 0.36))
                cap.closeSubpath()
                context.fill(cap, with: .color(ornament))
                var feather = Path()
                feather.move(to: point(0.56, 0.23))
                feather.addCurve(to: point(0.78, 0.12), control1: point(0.65, 0.10), control2: point(0.75, 0.10))
                feather.addCurve(to: point(0.64, 0.29), control1: point(0.81, 0.21), control2: point(0.72, 0.25))
                context.stroke(feather, with: .color(ink), lineWidth: max(1, size.width * 0.018))
            } else {
                var crown = Path()
                crown.move(to: point(0.34, 0.30))
                crown.addLine(to: point(0.36, 0.14))
                crown.addLine(to: point(0.44, 0.23))
                crown.addLine(to: point(0.50, rank == 13 ? 0.10 : 0.17))
                crown.addLine(to: point(0.57, 0.23))
                crown.addLine(to: point(0.65, 0.14))
                crown.addLine(to: point(0.67, 0.30))
                crown.closeSubpath()
                context.fill(crown, with: .color(ornament))
                context.stroke(crown, with: .color(ink), lineWidth: 0.7)
                if rank == 13 {
                    var beard = Path()
                    beard.move(to: point(0.39, 0.50))
                    beard.addQuadCurve(to: point(0.61, 0.50), control: point(0.50, 0.66))
                    beard.addLine(to: point(0.50, 0.65))
                    beard.closeSubpath()
                    context.fill(beard, with: .color(ink.opacity(0.88)))
                    context.stroke(beard, with: .color(ornament), lineWidth: 0.65)
                }
            }

            var collar = Path()
            collar.move(to: point(0.40, 0.58))
            collar.addLine(to: point(0.50, 0.69))
            collar.addLine(to: point(0.60, 0.58))
            context.stroke(collar, with: .color(paper), lineWidth: max(1, size.width * 0.025))
        }
        .accessibilityHidden(true)
    }
}

private struct PlayingCardBackView: View {
    let style: PlayingCardStyle
    let width: CGFloat
    private var height: CGFloat { width * 1.43 }

    var body: some View {
        RoundedRectangle(cornerRadius: width * 0.14)
            .fill(LinearGradient(colors: style.backColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: width * 0.14).stroke(.white.opacity(0.76), lineWidth: 1).padding(width * 0.055))
            .overlay(RoundedRectangle(cornerRadius: width * 0.14).stroke(style.ornament.opacity(0.82), lineWidth: 0.9).padding(width * 0.105))
            .overlay {
                ZStack {
                    CardBackPattern(style: style)
                        .padding(width * 0.18)
                    RoundedRectangle(cornerRadius: width * 0.08)
                        .stroke(style.ornament.opacity(0.26), lineWidth: 0.8)
                        .padding(width * 0.18)
                    Circle().stroke(.white.opacity(0.32), lineWidth: 1).padding(width * 0.23)
                    Circle().stroke(style.ornament.opacity(0.60), lineWidth: 0.7).padding(width * 0.30)
                    VStack(spacing: 3) {
                        StartPawn().fill(style.ornament).frame(width: width * 0.24, height: height * 0.22)
                        Text("START")
                            .font(.system(size: width * 0.075, weight: .black, design: .rounded))
                            .tracking(1.4)
                            .foregroundColor(.white.opacity(0.88))
                    }
                    Image(systemName: "sparkle")
                        .font(.system(size: width * 0.12, weight: .light))
                        .foregroundColor(style.ornament.opacity(0.92))
                        .offset(y: -height * 0.34)
                }
            }
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(0.42), radius: width * 0.09, x: 0, y: width * 0.07)
            .accessibilityHidden(true)
    }
}

private struct CardBackPattern: View {
    let style: PlayingCardStyle

    var body: some View {
        Canvas { context, size in
            let ink = style.ornament.opacity(0.38)
            switch style {
            case .classic:
                for row in 0..<7 {
                    for column in 0..<5 {
                        let center = CGPoint(
                            x: size.width * (CGFloat(column) + 0.5 + (row.isMultiple(of: 2) ? 0 : 0.5)) / 5,
                            y: size.height * (CGFloat(row) + 0.5) / 7
                        )
                        let radius = min(size.width / 18, size.height / 25)
                        var diamond = Path()
                        diamond.move(to: CGPoint(x: center.x, y: center.y - radius))
                        diamond.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                        diamond.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                        diamond.addLine(to: CGPoint(x: center.x - radius, y: center.y))
                        diamond.closeSubpath()
                        context.stroke(diamond, with: .color(ink), lineWidth: 0.65)
                    }
                }
            case .casino:
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for ring in 1...4 {
                    let radius = CGFloat(ring) * min(size.width, size.height) * 0.085
                    context.stroke(
                        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(ink),
                        lineWidth: ring.isMultiple(of: 2) ? 0.9 : 0.55
                    )
                }
                for ray in 0..<20 {
                    let angle = Double(ray) * Double.pi * 2 / 20
                    let dx = CGFloat(cos(angle))
                    let dy = CGFloat(sin(angle))
                    let inner = min(size.width, size.height) * 0.13
                    let outer = min(size.width, size.height) * 0.46
                    var line = Path()
                    line.move(to: CGPoint(x: center.x + dx * inner, y: center.y + dy * inner))
                    line.addLine(to: CGPoint(x: center.x + dx * outer, y: center.y + dy * outer))
                    context.stroke(line, with: .color(ink.opacity(0.68)), lineWidth: ray.isMultiple(of: 2) ? 0.8 : 0.45)
                }
            case .vintage:
                for row in 0..<8 {
                    let y = size.height * CGFloat(row) / 8
                    var wave = Path()
                    wave.move(to: CGPoint(x: 0, y: y))
                    wave.addCurve(
                        to: CGPoint(x: size.width, y: y),
                        control1: CGPoint(x: size.width * 0.30, y: y - size.height * 0.10),
                        control2: CGPoint(x: size.width * 0.70, y: y + size.height * 0.10)
                    )
                    context.stroke(wave, with: .color(ink), lineWidth: 0.6)
                }
                for column in 0..<5 {
                    let x = size.width * CGFloat(column) / 5
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: 0))
                    line.addLine(to: CGPoint(x: x + size.width * 0.20, y: size.height))
                    context.stroke(line, with: .color(ink.opacity(0.62)), lineWidth: 0.55)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack { CardsView().environmentObject(PlayerStore()) }
}
