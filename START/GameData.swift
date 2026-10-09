import Combine
import Foundation

struct LocalPlayer: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
}

struct PlayerGroup: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var players: [LocalPlayer]
}

struct WheelOption: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var colorIndex: Int
}

struct SavedWheel: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var gameName: String?
    var isGamePicker: Bool
    var removeWinnerAfterSpin: Bool
    var templateID: String?
    var options: [WheelOption]
}

struct WheelTemplate: Identifiable {
    let id: String
    let title: String
    let gameName: String?
    let description: String
    let isGamePicker: Bool
    let options: [String]

    static let catalog: [WheelTemplate] = [
        WheelTemplate(
            id: "game-picker",
            title: "O que vamos jogar?",
            gameName: nil,
            description: "Sorteia um jogo da coleção da mesa.",
            isGamePicker: true,
            options: ["Wonderlands’ War", "Tiranos do Subterrâneo", "Shackleton Base", "Arnak"]
        ),
        WheelTemplate(
            id: "wonderlands-war",
            title: "Personagens",
            gameName: "Wonderlands’ War",
            description: "Roleta inicial de personagens; ajuste os nomes para sua edição.",
            isGamePicker: false,
            options: ["Alice", "Rainha de Copas", "Gato de Cheshire", "Chapeleiro Maluco", "Jabberwock"]
        ),
        WheelTemplate(
            id: "tyrants-underdark",
            title: "Roleta da mesa",
            gameName: "Tiranos do Subterrâneo",
            description: "Template editável baseado nas opções do exemplo visual.",
            isGamePicker: false,
            options: ["Dragão", "Abominação"]
        ),
        WheelTemplate(
            id: "shackleton-base",
            title: "Módulos da base",
            gameName: "Shackleton Base",
            description: "Opções iniciais de módulos vistas no exemplo da roleta.",
            isGamePicker: false,
            options: ["Artemis", "Moon Mining", "Space Robotics", "Selenium Research", "Sky Watch", "To Mars", "Evergreen"]
        ),
        WheelTemplate(
            id: "arnak-leaders",
            title: "Líderes da expedição",
            gameName: "Arnak",
            description: "Escolha aleatória de líder; os nomes podem ser personalizados.",
            isGamePicker: false,
            options: ["Explorador", "Capitão", "Barão", "Falcoeiro", "Professor", "Assistente"]
        )
    ]

    func makeWheel() -> SavedWheel {
        SavedWheel(
            title: title,
            gameName: gameName,
            isGamePicker: isGamePicker,
            removeWinnerAfterSpin: false,
            templateID: id,
            options: options.enumerated().map { index, title in
                WheelOption(title: title, colorIndex: index)
            }
        )
    }
}

struct WheelSpinRecord: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var wheelID: UUID
    var wheelTitle: String
    var optionTitle: String
    var groupID: UUID
    var spunAt: Date
}

enum LocalMatchStatus: String, Codable, Hashable {
    case live
    case paused
    case finished
}

struct MatchParticipant: Codable, Identifiable, Hashable {
    var id: UUID
    var playerID: UUID
    var name: String
    var score: Int
}

struct ScoreChange: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var participantID: UUID
    var delta: Int
    var scoreAfter: Int
    var changedAt: Date
}

struct LocalMatch: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var groupID: UUID
    var groupName: String
    var gameName: String
    var participants: [MatchParticipant]
    var startedAt: Date
    var endedAt: Date?
    var status: LocalMatchStatus
    var currentRound: Int
    var accumulatedPausedSeconds: TimeInterval
    var pausedAt: Date?
    var turnDurationSeconds: Int
    var turnTimerEndsAt: Date?
    var turnTimerRemainingSeconds: Int?
    var turnTimerPaused: Bool
    var turnTimerWasRunningBeforeMatchPause: Bool
    var winnerIDs: [UUID]
    var scoreChanges: [ScoreChange]

    init(
        groupID: UUID,
        groupName: String,
        gameName: String,
        participants: [MatchParticipant],
        startedAt: Date = Date(),
        turnDurationSeconds: Int = 60
    ) {
        self.groupID = groupID
        self.groupName = groupName
        self.gameName = gameName
        self.participants = participants
        self.startedAt = startedAt
        self.endedAt = nil
        self.status = .live
        self.currentRound = 1
        self.accumulatedPausedSeconds = 0
        self.pausedAt = nil
        self.turnDurationSeconds = turnDurationSeconds
        self.turnTimerEndsAt = nil
        self.turnTimerRemainingSeconds = nil
        self.turnTimerPaused = false
        self.turnTimerWasRunningBeforeMatchPause = false
        self.winnerIDs = []
        self.scoreChanges = []
    }
}

struct PlayerStanding: Identifiable {
    var id: UUID
    var name: String
    var played: Int
    var wins: Int
    var draws: Int
    var losses: Int
    var points: Int

    var winRate: Double {
        played == 0 ? 0 : Double(wins) / Double(played)
    }
}

struct LocalGameData: Codable {
    var schemaVersion: Int
    var groups: [PlayerGroup]
    var activeGroupID: UUID
    var wheels: [SavedWheel]
    var matches: [LocalMatch]
    var customGames: [String]
    var spinHistory: [WheelSpinRecord]

    static func starter() -> LocalGameData {
        let group = PlayerGroup(
            name: "Minha mesa",
            players: ["Ana", "Carlos", "Pedro", "Júlia"].map { LocalPlayer(name: $0) }
        )
        return LocalGameData(
            schemaVersion: 1,
            groups: [group],
            activeGroupID: group.id,
            wheels: [WheelTemplate.catalog[0].makeWheel()],
            matches: [],
            customGames: [],
            spinHistory: []
        )
    }

    static func visualFixture() -> LocalGameData {
        var data = starter()
        data.wheels.append(contentsOf: WheelTemplate.catalog.dropFirst().map { $0.makeWheel() })
        data.customGames = WheelTemplate.catalog.compactMap(\.gameName)
        guard let group = data.groups.first else { return data }

        let now = Date()
        let completedParticipants = group.players.enumerated().map { index, player in
            MatchParticipant(id: player.id, playerID: player.id, name: player.name, score: [24, 18, 15, 11][index % 4])
        }
        var completed = LocalMatch(
            groupID: group.id,
            groupName: group.name,
            gameName: "Arnak",
            participants: completedParticipants,
            startedAt: now.addingTimeInterval(-5_400)
        )
        completed.endedAt = now.addingTimeInterval(-1_800)
        completed.status = .finished
        completed.winnerIDs = completedParticipants.first.map { [$0.playerID] } ?? []
        completed.currentRound = 8
        completed.scoreChanges = [
            ScoreChange(participantID: completedParticipants[0].id, delta: 24, scoreAfter: 24, changedAt: now.addingTimeInterval(-2_000)),
            ScoreChange(participantID: completedParticipants[1].id, delta: 18, scoreAfter: 18, changedAt: now.addingTimeInterval(-2_010))
        ]

        let liveParticipants = group.players.enumerated().map { index, player in
            MatchParticipant(id: player.id, playerID: player.id, name: player.name, score: [6, 4, 2, 0][index % 4])
        }
        var live = LocalMatch(
            groupID: group.id,
            groupName: group.name,
            gameName: "Shackleton Base",
            participants: liveParticipants,
            startedAt: now.addingTimeInterval(-1_080)
        )
        live.currentRound = 4
        live.turnTimerEndsAt = now.addingTimeInterval(38)
        data.matches = [live, completed]
        return data
    }
}

final class PlayerStore: ObservableObject {
    @Published private(set) var data: LocalGameData

    private let storageURL: URL?

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let captureArguments: Set<String> = [
            "-capture-wheels", "-capture-wheel", "-capture-matches",
            "-capture-live-match", "-capture-ranking", "-capture-history", "-capture-templates"
        ]
        if arguments.contains(where: { captureArguments.contains($0) }) {
            data = arguments.contains("-capture-templates") ? .starter() : .visualFixture()
            storageURL = nil
            return
        }

        let baseURL: URL
        if arguments.contains("-ui-testing") {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            baseURL = support.appendingPathComponent("START", isDirectory: true).appendingPathComponent("START-ui-test-data.json")
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            baseURL = support.appendingPathComponent("START", isDirectory: true).appendingPathComponent("local-data-v1.json")
        }
        storageURL = baseURL

        if arguments.contains("-reset-local-data") {
            try? FileManager.default.removeItem(at: baseURL)
        }
        if let saved = try? Data(contentsOf: baseURL),
           let decoded = try? JSONDecoder().decode(LocalGameData.self, from: saved),
           decoded.schemaVersion == 1,
           !decoded.groups.isEmpty {
            data = decoded
        } else {
            data = .starter()
            persist()
        }
    }

    var players: [String] {
        get { activeGroup.players.map(\.name) }
        set { replacePlayers(newValue) }
    }

    var displayNames: [String] {
        if players.isEmpty { return ["Jogador 1", "Jogador 2"] }
        if players.count == 1 { return players + ["Jogador 2"] }
        return players
    }

    var activeGroup: PlayerGroup {
        data.groups.first(where: { $0.id == data.activeGroupID }) ?? data.groups[0]
    }

    var availableGames: [String] {
        let names = WheelTemplate.catalog.compactMap(\.gameName)
            + data.customGames
            + data.matches.map(\.gameName)
            + data.wheels.compactMap(\.gameName)
        var seen = Set<String>()
        return names.filter { seen.insert($0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)).inserted }
    }

    var activeMatches: [LocalMatch] {
        data.matches.filter { $0.status != .finished }
            .sorted { $0.startedAt > $1.startedAt }
    }

    var completedMatches: [LocalMatch] {
        data.matches.filter { $0.status == .finished }
            .sorted { ($0.endedAt ?? $0.startedAt) > ($1.endedAt ?? $1.startedAt) }
    }

    func group(_ id: UUID) -> PlayerGroup? {
        data.groups.first(where: { $0.id == id })
    }

    func players(in groupID: UUID) -> [LocalPlayer] {
        group(groupID)?.players ?? []
    }

    func add(name: String) {
        addPlayer(name: name)
    }

    func addPlayer(name: String, to groupID: UUID? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        change { data in
            guard let index = data.groups.firstIndex(where: { $0.id == (groupID ?? data.activeGroupID) }) else { return }
            guard !data.groups[index].players.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
            data.groups[index].players.append(LocalPlayer(name: trimmed))
        }
    }

    func remove(at offsets: IndexSet) {
        change { data in
            guard let groupIndex = data.groups.firstIndex(where: { $0.id == data.activeGroupID }) else { return }
            for offset in offsets.sorted(by: >) where data.groups[groupIndex].players.indices.contains(offset) {
                data.groups[groupIndex].players.remove(at: offset)
            }
        }
    }

    func removePlayer(id: UUID, from groupID: UUID? = nil) {
        change { data in
            guard let index = data.groups.firstIndex(where: { $0.id == (groupID ?? data.activeGroupID) }) else { return }
            data.groups[index].players.removeAll { $0.id == id }
        }
    }

    func replacePlayers(_ names: [String]) {
        let cleaned = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        change { data in
            guard let index = data.groups.firstIndex(where: { $0.id == data.activeGroupID }) else { return }
            let existing = Dictionary(data.groups[index].players.map { ($0.name, $0.id) }, uniquingKeysWith: { first, _ in first })
            data.groups[index].players = cleaned.map { LocalPlayer(id: existing[$0] ?? UUID(), name: $0) }
        }
    }

    @discardableResult
    func createGroup(name: String, copyCurrentPlayers: Bool = true) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !data.groups.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) else { return nil }
        let id = UUID()
        change { data in
            let members = copyCurrentPlayers ? activeGroup.players.map { LocalPlayer(name: $0.name) } : []
            data.groups.append(PlayerGroup(id: id, name: trimmed, players: members))
            data.activeGroupID = id
        }
        return id
    }

    func renameGroup(_ groupID: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        change { data in
            guard let index = data.groups.firstIndex(where: { $0.id == groupID }) else { return }
            data.groups[index].name = trimmed
        }
    }

    func selectGroup(_ groupID: UUID) {
        guard data.groups.contains(where: { $0.id == groupID }) else { return }
        change { $0.activeGroupID = groupID }
    }

    func deleteGroup(_ groupID: UUID) {
        guard data.groups.count > 1 else { return }
        guard !data.matches.contains(where: { $0.groupID == groupID }) else { return }
        change { data in
            data.groups.removeAll { $0.id == groupID }
            if data.activeGroupID == groupID {
                data.activeGroupID = data.groups[0].id
            }
        }
    }

    func wheel(_ id: UUID) -> SavedWheel? {
        data.wheels.first(where: { $0.id == id })
    }

    func createWheel(title: String, gameName: String?, options: [String], isGamePicker: Bool = false) -> UUID? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOptions = options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !cleanTitle.isEmpty, cleanOptions.count >= 2 else { return nil }
        let wheel = SavedWheel(
            title: cleanTitle,
            gameName: gameName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            isGamePicker: isGamePicker,
            removeWinnerAfterSpin: false,
            templateID: nil,
            options: cleanOptions.enumerated().map { WheelOption(title: $0.element, colorIndex: $0.offset) }
        )
        change { data in
            data.wheels.append(wheel)
            if let game = wheel.gameName { register(game, in: &data) }
        }
        return wheel.id
    }

    func saveWheel(_ wheel: SavedWheel) {
        guard !wheel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, wheel.options.count >= 2 else { return }
        change { data in
            if let index = data.wheels.firstIndex(where: { $0.id == wheel.id }) {
                data.wheels[index] = wheel
            } else {
                data.wheels.append(wheel)
            }
            if let game = wheel.gameName { register(game, in: &data) }
        }
    }

    func deleteWheel(_ id: UUID) {
        change { $0.wheels.removeAll { $0.id == id } }
    }

    @discardableResult
    func duplicateWheel(_ id: UUID) -> UUID? {
        guard let original = wheel(id) else { return nil }
        var duplicate = original
        duplicate.id = UUID()
        duplicate.title += " (cópia)"
        duplicate.templateID = nil
        duplicate.options = original.options.map { WheelOption(title: $0.title, colorIndex: $0.colorIndex) }
        change { $0.wheels.append(duplicate) }
        return duplicate.id
    }

    @discardableResult
    func importTemplate(_ template: WheelTemplate) -> UUID {
        if let existing = data.wheels.first(where: { $0.templateID == template.id }) { return existing.id }
        let wheel = template.makeWheel()
        change { data in
            data.wheels.append(wheel)
            if let game = wheel.gameName { register(game, in: &data) }
        }
        return wheel.id
    }

    func recordSpin(wheelID: UUID, optionID: UUID, groupID: UUID? = nil) {
        guard let wheel = wheel(wheelID), let option = wheel.options.first(where: { $0.id == optionID }) else { return }
        change { data in
            data.spinHistory.insert(
                WheelSpinRecord(wheelID: wheelID, wheelTitle: wheel.title, optionTitle: option.title, groupID: groupID ?? data.activeGroupID, spunAt: Date()),
                at: 0
            )
            if data.spinHistory.count > 100 { data.spinHistory.removeLast(data.spinHistory.count - 100) }
            if wheel.removeWinnerAfterSpin {
                guard let wheelIndex = data.wheels.firstIndex(where: { $0.id == wheelID }) else { return }
                data.wheels[wheelIndex].options.removeAll { $0.id == optionID }
            }
        }
    }

    func match(_ id: UUID) -> LocalMatch? {
        data.matches.first(where: { $0.id == id })
    }

    @discardableResult
    func startMatch(gameName: String, groupID: UUID, playerIDs: Set<UUID>, turnDurationSeconds: Int = 60) -> UUID? {
        let cleanGame = gameName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanGame.isEmpty, let group = group(groupID) else { return nil }
        let selected = group.players.filter { playerIDs.contains($0.id) }
        guard selected.count >= 2 else { return nil }
        let participants = selected.map { MatchParticipant(id: $0.id, playerID: $0.id, name: $0.name, score: 0) }
        let session = LocalMatch(
            groupID: group.id,
            groupName: group.name,
            gameName: cleanGame,
            participants: participants,
            turnDurationSeconds: max(10, turnDurationSeconds)
        )
        change { data in
            data.matches.insert(session, at: 0)
            register(cleanGame, in: &data)
        }
        return session.id
    }

    func changeScore(matchID: UUID, participantID: UUID, by delta: Int) {
        guard delta != 0 else { return }
        change { data in
            guard let matchIndex = data.matches.firstIndex(where: { $0.id == matchID }),
                  data.matches[matchIndex].status != .finished,
                  let playerIndex = data.matches[matchIndex].participants.firstIndex(where: { $0.id == participantID }) else { return }
            data.matches[matchIndex].participants[playerIndex].score += delta
            let score = data.matches[matchIndex].participants[playerIndex].score
            data.matches[matchIndex].scoreChanges.append(
                ScoreChange(participantID: participantID, delta: delta, scoreAfter: score, changedAt: Date())
            )
        }
    }

    func undoLastScore(matchID: UUID) {
        change { data in
            guard let matchIndex = data.matches.firstIndex(where: { $0.id == matchID }),
                  data.matches[matchIndex].status != .finished,
                  let changeIndex = data.matches[matchIndex].scoreChanges.indices.last else { return }
            let event = data.matches[matchIndex].scoreChanges.remove(at: changeIndex)
            if let playerIndex = data.matches[matchIndex].participants.firstIndex(where: { $0.id == event.participantID }) {
                data.matches[matchIndex].participants[playerIndex].score -= event.delta
            }
        }
    }

    func correctFinishedScore(matchID: UUID, participantID: UUID, by delta: Int) {
        guard delta != 0 else { return }
        change { data in
            guard let matchIndex = data.matches.firstIndex(where: { $0.id == matchID }),
                  data.matches[matchIndex].status == .finished,
                  let playerIndex = data.matches[matchIndex].participants.firstIndex(where: { $0.id == participantID }) else { return }
            data.matches[matchIndex].participants[playerIndex].score += delta
            let score = data.matches[matchIndex].participants[playerIndex].score
            data.matches[matchIndex].scoreChanges.append(
                ScoreChange(participantID: participantID, delta: delta, scoreAfter: score, changedAt: Date())
            )
        }
    }

    func advanceRound(matchID: UUID) {
        change { data in
            guard let index = data.matches.firstIndex(where: { $0.id == matchID }), data.matches[index].status != .finished else { return }
            data.matches[index].currentRound += 1
        }
    }

    func pauseMatch(matchID: UUID) {
        change { data in
            guard let index = data.matches.firstIndex(where: { $0.id == matchID }), data.matches[index].status == .live else { return }
            let now = Date()
            data.matches[index].status = .paused
            data.matches[index].pausedAt = now
            data.matches[index].turnTimerWasRunningBeforeMatchPause = data.matches[index].turnTimerEndsAt != nil
            if let end = data.matches[index].turnTimerEndsAt {
                data.matches[index].turnTimerRemainingSeconds = max(0, Int(ceil(end.timeIntervalSince(now))))
                data.matches[index].turnTimerEndsAt = nil
                data.matches[index].turnTimerPaused = true
            }
        }
    }

    func resumeMatch(matchID: UUID) {
        change { data in
            guard let index = data.matches.firstIndex(where: { $0.id == matchID }), data.matches[index].status == .paused else { return }
            let now = Date()
            if let pausedAt = data.matches[index].pausedAt {
                data.matches[index].accumulatedPausedSeconds += now.timeIntervalSince(pausedAt)
            }
            data.matches[index].pausedAt = nil
            data.matches[index].status = .live
            if data.matches[index].turnTimerWasRunningBeforeMatchPause {
                let remaining = data.matches[index].turnTimerRemainingSeconds ?? data.matches[index].turnDurationSeconds
                data.matches[index].turnTimerEndsAt = now.addingTimeInterval(TimeInterval(remaining))
                data.matches[index].turnTimerRemainingSeconds = nil
                data.matches[index].turnTimerPaused = false
            }
            data.matches[index].turnTimerWasRunningBeforeMatchPause = false
        }
    }

    func startTurnTimer(matchID: UUID, durationSeconds: Int) {
        change { data in
            guard let index = data.matches.firstIndex(where: { $0.id == matchID }), data.matches[index].status == .live else { return }
            let duration = max(10, durationSeconds)
            data.matches[index].turnDurationSeconds = duration
            data.matches[index].turnTimerEndsAt = Date().addingTimeInterval(TimeInterval(duration))
            data.matches[index].turnTimerRemainingSeconds = nil
            data.matches[index].turnTimerPaused = false
            data.matches[index].turnTimerWasRunningBeforeMatchPause = false
        }
    }

    func pauseTurnTimer(matchID: UUID) {
        change { data in
            guard let index = data.matches.firstIndex(where: { $0.id == matchID }),
                  let end = data.matches[index].turnTimerEndsAt else { return }
            data.matches[index].turnTimerRemainingSeconds = max(0, Int(ceil(end.timeIntervalSinceNow)))
            data.matches[index].turnTimerEndsAt = nil
            data.matches[index].turnTimerPaused = true
        }
    }

    func resumeTurnTimer(matchID: UUID) {
        change { data in
            guard let index = data.matches.firstIndex(where: { $0.id == matchID }),
                  data.matches[index].status == .live,
                  data.matches[index].turnTimerPaused else { return }
            let remaining = data.matches[index].turnTimerRemainingSeconds ?? data.matches[index].turnDurationSeconds
            data.matches[index].turnTimerEndsAt = Date().addingTimeInterval(TimeInterval(remaining))
            data.matches[index].turnTimerRemainingSeconds = nil
            data.matches[index].turnTimerPaused = false
        }
    }

    func stopTurnTimer(matchID: UUID) {
        change { data in
            guard let index = data.matches.firstIndex(where: { $0.id == matchID }) else { return }
            data.matches[index].turnTimerEndsAt = nil
            data.matches[index].turnTimerRemainingSeconds = nil
            data.matches[index].turnTimerPaused = false
            data.matches[index].turnTimerWasRunningBeforeMatchPause = false
        }
    }

    func elapsedSeconds(for match: LocalMatch, now: Date = Date()) -> Int {
        let end = match.endedAt ?? (match.status == .paused ? match.pausedAt ?? now : now)
        let pausedNow = match.status == .paused ? max(0, end.timeIntervalSince(match.pausedAt ?? end)) : 0
        return max(0, Int(end.timeIntervalSince(match.startedAt) - match.accumulatedPausedSeconds - pausedNow))
    }

    func turnSecondsRemaining(for match: LocalMatch, now: Date = Date()) -> Int? {
        if let end = match.turnTimerEndsAt {
            return max(0, Int(ceil(end.timeIntervalSince(now))))
        }
        return match.turnTimerPaused ? match.turnTimerRemainingSeconds : nil
    }

    func finishMatch(matchID: UUID, winnerIDs: Set<UUID>) {
        change { data in
            guard let index = data.matches.firstIndex(where: { $0.id == matchID }), data.matches[index].status != .finished else { return }
            let now = Date()
            if data.matches[index].status == .paused, let pausedAt = data.matches[index].pausedAt {
                data.matches[index].accumulatedPausedSeconds += now.timeIntervalSince(pausedAt)
            }
            let validIDs = Set(data.matches[index].participants.map(\.id))
            data.matches[index].winnerIDs = Array(winnerIDs.intersection(validIDs))
            data.matches[index].endedAt = now
            data.matches[index].pausedAt = nil
            data.matches[index].status = .finished
            data.matches[index].turnTimerEndsAt = nil
            data.matches[index].turnTimerRemainingSeconds = nil
            data.matches[index].turnTimerPaused = false
            data.matches[index].turnTimerWasRunningBeforeMatchPause = false
        }
    }

    func updateFinishedMatchWinners(matchID: UUID, winnerIDs: Set<UUID>) {
        change { data in
            guard let index = data.matches.firstIndex(where: { $0.id == matchID }), data.matches[index].status == .finished else { return }
            let validIDs = Set(data.matches[index].participants.map(\.id))
            data.matches[index].winnerIDs = Array(winnerIDs.intersection(validIDs))
        }
    }

    func deleteMatch(_ matchID: UUID) {
        change { $0.matches.removeAll { $0.id == matchID } }
    }

    func ranking(groupID: UUID, gameName: String) -> [PlayerStanding] {
        let matches = completedMatches.filter {
            $0.groupID == groupID && $0.gameName.localizedCaseInsensitiveCompare(gameName) == .orderedSame
        }
        var standings: [UUID: PlayerStanding] = [:]
        for match in matches {
            let selectedWinners = Set(match.winnerIDs)
            let isWholeTableDraw = selectedWinners.isEmpty || selectedWinners.count == match.participants.count
            for participant in match.participants {
                var standing = standings[participant.playerID] ?? PlayerStanding(
                    id: participant.playerID,
                    name: participant.name,
                    played: 0,
                    wins: 0,
                    draws: 0,
                    losses: 0,
                    points: 0
                )
                standing.name = participant.name
                standing.played += 1
                standing.points += participant.score
                if isWholeTableDraw {
                    standing.draws += 1
                } else if selectedWinners.contains(participant.id) {
                    if selectedWinners.count > 1 {
                        standing.draws += 1
                    } else {
                        standing.wins += 1
                    }
                } else {
                    standing.losses += 1
                }
                standings[participant.playerID] = standing
            }
        }
        return standings.values.sorted {
            if $0.wins != $1.wins { return $0.wins > $1.wins }
            if $0.winRate != $1.winRate { return $0.winRate > $1.winRate }
            if $0.points != $1.points { return $0.points > $1.points }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func change(_ mutation: (inout LocalGameData) -> Void) {
        var updated = data
        mutation(&updated)
        data = updated
        persist()
    }

    private func persist() {
        guard let storageURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: storageURL, options: .atomic)
        } catch {
            #if DEBUG
            print("START local save failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func register(_ gameName: String, in data: inout LocalGameData) {
        guard !data.customGames.contains(where: { $0.localizedCaseInsensitiveCompare(gameName) == .orderedSame }),
              !WheelTemplate.catalog.compactMap(\.gameName).contains(where: { $0.localizedCaseInsensitiveCompare(gameName) == .orderedSame }) else { return }
        data.customGames.append(gameName)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
