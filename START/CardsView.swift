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
    @AppStorage("start.playingCardStyle") private var selectedStyleRawValue = "classic"
    private let screenshotMode = ProcessInfo.processInfo.arguments.contains("-screenshot-mode")

    private var selectedStyle: PlayingCardStyle {
        PlayingCardStyle(rawValue: selectedStyleRawValue) ?? .classic
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
            if ProcessInfo.processInfo.arguments.contains("-capture-cards") {
                selectedStyleRawValue = PlayingCardStyle.classic.rawValue
                if draws.isEmpty { deal() }
            }
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
        case 7: return Array(pipPositionsForEight.prefix(6)) + [CGPoint(x: 0.5, y: 0.22)]
        case 8: return pipPositionsForEight
        case 9: return [CGPoint(x: 0.32, y: 0.22), CGPoint(x: 0.5, y: 0.22), CGPoint(x: 0.68, y: 0.22), CGPoint(x: 0.32, y: 0.5), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.68, y: 0.5), CGPoint(x: 0.32, y: 0.78), CGPoint(x: 0.5, y: 0.78), CGPoint(x: 0.68, y: 0.78)]
        default: return [CGPoint(x: 0.34, y: 0.18), CGPoint(x: 0.66, y: 0.18), CGPoint(x: 0.34, y: 0.34), CGPoint(x: 0.66, y: 0.34), CGPoint(x: 0.34, y: 0.5), CGPoint(x: 0.66, y: 0.5), CGPoint(x: 0.34, y: 0.66), CGPoint(x: 0.66, y: 0.66), CGPoint(x: 0.34, y: 0.82), CGPoint(x: 0.66, y: 0.82)]
        }
    }

    private var pipPositionsForEight: [CGPoint] {
        [CGPoint(x: 0.34, y: 0.20), CGPoint(x: 0.66, y: 0.20), CGPoint(x: 0.34, y: 0.40), CGPoint(x: 0.66, y: 0.40), CGPoint(x: 0.34, y: 0.60), CGPoint(x: 0.66, y: 0.60), CGPoint(x: 0.34, y: 0.80), CGPoint(x: 0.66, y: 0.80)]
    }
}

private struct CourtCardArt: View {
    let card: PlayingCard
    let style: PlayingCardStyle
    let width: CGFloat

    private var ink: Color { card.isRed ? Color(red: 0.78, green: 0.10, blue: 0.14) : Color(red: 0.10, green: 0.12, blue: 0.14) }
    private var emblem: String { card.rank == 11 ? "sparkles" : "crown.fill" }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.08)
                .fill(style.ornament.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: width * 0.08).stroke(style.ornament.opacity(0.48), lineWidth: 0.8))
            VStack(spacing: 1) {
                portraitHalf
                Rectangle()
                    .fill(style.ornament.opacity(0.54))
                    .frame(height: 0.7)
                    .padding(.horizontal, width * 0.06)
                portraitHalf.rotationEffect(.degrees(180))
            }
            .padding(width * 0.05)
        }
    }

    private var portraitHalf: some View {
        HStack(spacing: 1) {
            Image(systemName: emblem)
                .font(.system(size: width * 0.12, weight: .semibold))
                .foregroundColor(style.ornament)
                .frame(width: width * 0.16)
            VStack(spacing: -3) {
                Image(systemName: "person.fill")
                    .font(.system(size: width * 0.20, weight: .medium))
                    .foregroundColor(ink.opacity(0.88))
                Text(card.suit)
                    .font(.system(size: width * 0.12, weight: .bold, design: .serif))
                    .foregroundColor(ink)
            }
            .frame(maxWidth: .infinity)
            Text(card.rankLabel)
                .font(.system(size: width * 0.20, weight: .black, design: .serif))
                .foregroundColor(ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

#Preview {
    NavigationStack { CardsView().environmentObject(PlayerStore()) }
}
