import Foundation
import Combine

final class PlayerStore: ObservableObject {
    @Published var players: [String] = ["Ana", "Carlos", "Pedro", "Júlia"]

    var displayNames: [String] {
        if players.isEmpty { return ["Jogador 1", "Jogador 2"] }
        if players.count == 1 { return players + ["Jogador 2"] }
        return players
    }

    func add(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        players.append(trimmed)
    }

    func remove(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
    }
}

enum Dice: Int, CaseIterable, Identifiable {
    case d4 = 4, d6 = 6, d8 = 8, d10 = 10, d12 = 12, d20 = 20

    var id: Int { rawValue }
    var label: String { "D\(rawValue)" }

    static func roll(sides: Int) -> Int {
        Int.random(in: 1...max(2, sides))
    }
}

struct PlayingCard: Identifiable, Equatable {
    let id = UUID()
    let rank: Int // 2...14 (11=J, 12=Q, 13=K, 14=A)
    let suit: String // ♠ ♥ ♦ ♣

    var rankLabel: String {
        switch rank {
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        case 14: return "A"
        default: return "\(rank)"
        }
    }

    var label: String { "\(rankLabel)\(suit)" }
    var isRed: Bool { suit == "♥" || suit == "♦" }

    static func random() -> PlayingCard {
        PlayingCard(rank: Int.random(in: 2...14), suit: ["♠", "♥", "♦", "♣"].randomElement()!)
    }
}

struct SituationDeck {
    static let prompts: [String] = [
        "Quem está usando óculos?",
        "Quem está de vermelho?",
        "Jogador mais novo começa",
        "Jogador mais velho começa",
        "Quem acordou mais cedo hoje?",
        "Quem morou em mais cidades?",
        "Quem tem o aniversário mais próximo?",
        "Quem chegou por último na mesa?",
        "Quem nunca jogou este jogo?",
        "Quem venceu a última partida?",
        "Quem tem o nome mais curto?",
        "Quem tem o nome mais longo?",
        "Quem está com o celular na mão?",
        "Quem bebeu água por último?",
        "Quem é mais pontual?",
        "Quem conta as melhores histórias?",
        "Quem escolheu o jogo de hoje?",
        "Quem está sentado mais perto da porta?",
        "Quem tem mais jogos na coleção?",
        "Quem viajou mais longe este ano?",
        "Quem dormiu mais tarde ontem?",
        "Quem faz o melhor café?",
        "Quem chegou primeiro hoje?",
        "Quem está mais animado para jogar?"
    ]

    static func shuffled() -> [String] {
        prompts.shuffled()
    }
}
