import SwiftUI

struct SituationDeckView: View {
    @EnvironmentObject private var players: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @State private var deck: [String] = {
        let prompts = SituationDeck.prompts
        return ProcessInfo.processInfo.arguments.contains("-screenshot-mode")
            ? [prompts[0]] + Array(prompts.dropFirst()).shuffled()
            : prompts.shuffled()
    }()
    @State private var index = 0
    @State private var selectedPlayer: String? = ProcessInfo.processInfo.arguments.contains("-screenshot-mode") ? "Carlos" : nil
    @State private var confirmedPlayer: String?
    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TableBackground()
                ScrollView {
                    VStack(spacing: 0) {
                        AppScreenHeader(title: "Situações") { dismiss() }
                        Spacer(minLength: 14)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("BARALHO DA MESA")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1.7)
                                .foregroundColor(Theme.accent)
                            Text("Quem combina com a frase?")
                                .font(.system(size: 23, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("Leiam em voz alta e escolham juntos.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.mutedText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        Spacer(minLength: 18)

                        promptCard(minimumHeight: max(150, min(230, geometry.size.height * 0.27)))
                            .id(index)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        Spacer(minLength: 14)

                        if let confirmedPlayer {
                            HStack(spacing: 9) {
                                Image(systemName: "crown.fill").foregroundColor(Theme.accent)
                                Text("\(confirmedPlayer.uppercased()) COMEÇA!")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .tracking(0.7)
                                    .foregroundColor(.white)
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .background(Theme.green.opacity(0.75), in: RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.greenLight.opacity(0.58), lineWidth: 1))
                            .padding(.horizontal, 18)
                            .accessibilityIdentifier("situation-result")
                            .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(players.displayNames, id: \.self) { name in
                                    playerChip(name)
                                }
                            }
                            .padding(.horizontal, 18)
                            .accessibilityIdentifier("situation-players")
                        }
                        Spacer(minLength: 14)

                        Button {
                            if confirmedPlayer != nil {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                    nextPrompt()
                                    selectedPlayer = nil
                                    confirmedPlayer = nil
                                }
                            } else if let selectedPlayer {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                    confirmedPlayer = selectedPlayer
                                }
                                GameFeedback.play(.winner)
                                GameFeedback.success()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                Text(confirmedPlayer == nil ? (selectedPlayer.map { "\($0.uppercased()) COMEÇA" } ?? "ESCOLHA UM JOGADOR") : "NOVA FRASE")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .startPrimaryButton()
                        }
                        .disabled(selectedPlayer == nil && confirmedPlayer == nil)
                        .opacity(selectedPlayer == nil && confirmedPlayer == nil ? 0.53 : 1)
                        .padding(.horizontal, 20)
                        .accessibilityIdentifier("confirm-situation-button")

                        Button(confirmedPlayer == nil ? "Ninguém se encaixa · tirar outra" : "Embaralhar o baralho") {
                            GameFeedback.impact(.soft)
                            GameFeedback.play(.cardFlip)
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                if confirmedPlayer != nil {
                                    deck = SituationDeck.shuffled()
                                    index = 0
                                } else {
                                    nextPrompt()
                                }
                                selectedPlayer = nil
                                confirmedPlayer = nil
                            }
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.accentLight)
                        .padding(.vertical, 6)
                        .accessibilityIdentifier("next-situation-button")
                        Spacer(minLength: 12)
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
    }

    private func promptCard(minimumHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle").foregroundColor(Theme.accent)
                    Text("CARTA \(index + 1) / \(deck.count)")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.25)
                        .foregroundColor(.white.opacity(0.74))
                }
                Spacer()
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.accent.opacity(0.85))
            }

            Rectangle().fill(Theme.accent.opacity(0.25)).frame(height: 1)

            Text(currentPrompt)
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)
                .accessibilityIdentifier("situation-text")

            Text("\(max(0, deck.count - index - 1)) cartas depois desta")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Theme.mutedText)
        }
        .padding(17)
        .background(
            LinearGradient(colors: [Color(red: 0.08, green: 0.12, blue: 0.095), .black.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 19)
        )
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(Theme.accent.opacity(0.43), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 13, x: 0, y: 8)
        .padding(.horizontal, 18)
    }

    private func playerChip(_ name: String) -> some View {
        let isSelected = selectedPlayer == name
        return Button {
            GameFeedback.impact(.soft)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                selectedPlayer = name
            }
        } label: {
            HStack(spacing: 8) {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accentText)
                    .frame(width: 25, height: 25)
                    .background(isSelected ? Theme.accent : Theme.green, in: Circle())
                Text(name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.accent) }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.accent.opacity(0.16) : .black.opacity(0.53), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(isSelected ? Theme.accent : .white.opacity(0.13), lineWidth: 1))
        }
        .buttonStyle(StartButtonMotionStyle())
        .accessibilityIdentifier("situation-player-\(name)")
    }

    private var currentPrompt: String {
        guard deck.indices.contains(index) else { return "Quem está usando óculos?" }
        return deck[index]
    }

    private func nextPrompt() {
        if index + 1 < deck.count {
            index += 1
        } else {
            deck = SituationDeck.shuffled()
            index = 0
        }
    }
}

#Preview {
    NavigationStack { SituationDeckView().environmentObject(PlayerStore()) }
}
