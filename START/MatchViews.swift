import SwiftUI

private enum MatchCenterSection: String, CaseIterable, Identifiable, Hashable {
    case live = "Ao vivo"
    case ranking = "Ranking"
    case history = "Histórico"
    var id: String { rawValue }
}

private enum LiveMatchSheet: String, Identifiable {
    case result
    case customTimer
    var id: String { rawValue }
}

struct MatchCenterView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @State private var section: MatchCenterSection
    @State private var selectedGroupID: UUID?
    @State private var selectedGame = ""
    @State private var matchPendingDeletion: UUID?
    @State private var showDeleteConfirmation = false

    init() {
        _section = State(initialValue: ProcessInfo.processInfo.arguments.contains("-capture-history") ? .history : .live)
    }

    private var groupID: UUID { selectedGroupID ?? store.activeGroup.id }

    var body: some View {
        ZStack {
            TableBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    AppScreenHeader(title: "Partidas") { dismiss() }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PLACAR, TEMPO E HISTÓRICO")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(Theme.accent)
                        Text("Acompanhe a mesa")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Tudo salvo localmente para continuar depois.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText)
                    }
                    .padding(.horizontal, 20)

                    groupPicker

                    NavigationLink {
                        MatchSetupView()
                    } label: {
                        Label("NOVA PARTIDA", systemImage: "play.fill")
                            .startPrimaryButton()
                    }
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("new-match")

                    Picker("Partidas", selection: $section) {
                        ForEach(MatchCenterSection.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("match-center-picker")

                    switch section {
                    case .live:
                        liveSection
                    case .ranking:
                        rankingSection
                    case .history:
                        historySection
                    }
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            selectedGroupID = selectedGroupID ?? store.activeGroup.id
            let firstPlayedGame = store.completedMatches.first(where: { $0.groupID == groupID })?.gameName
            selectedGame = selectedGame.isEmpty ? (firstPlayedGame ?? store.availableGames.first ?? "") : selectedGame
        }
        .confirmationDialog("Apagar este resultado?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Apagar partida", role: .destructive) {
                if let matchPendingDeletion { store.deleteMatch(matchPendingDeletion) }
                matchPendingDeletion = nil
            }
            Button("Cancelar", role: .cancel) { matchPendingDeletion = nil }
        } message: {
            Text("O ranking será recalculado sem esta partida.")
        }
    }

    private var groupPicker: some View {
        Menu {
            ForEach(store.data.groups) { group in
                Button {
                    selectedGroupID = group.id
                    store.selectGroup(group.id)
                } label: {
                    if group.id == groupID {
                        Label(group.name, systemImage: "checkmark")
                    } else {
                        Text(group.name)
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "person.2.fill").foregroundColor(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MESA / GRUPO")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundColor(Theme.mutedText)
                    Text(store.group(groupID)?.name ?? store.activeGroup.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "chevron.down").foregroundColor(Theme.accent)
            }
            .padding(12)
            .background(.black.opacity(0.40), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.12), lineWidth: 1))
        }
        .padding(.horizontal, 20)
        .accessibilityIdentifier("match-group-picker")
    }

    private var liveSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PARTIDAS EM ANDAMENTO")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 20)
            let liveMatches = store.activeMatches.filter { $0.groupID == groupID }
            if liveMatches.isEmpty {
                emptyState(title: "Nenhuma partida ao vivo", detail: "Comece uma partida para ver o placar e os relógios aqui.", icon: "timer")
            } else {
                ForEach(liveMatches) { match in
                    NavigationLink {
                        LiveMatchView(matchID: match.id)
                    } label: {
                        MatchSummaryCard(match: match, store: store, showsStatus: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("live-match-\(match.id.uuidString)")
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PARTIDAS ENCERRADAS")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 20)
            let matches = store.completedMatches.filter { $0.groupID == groupID }
            if matches.isEmpty {
                emptyState(title: "Histórico vazio", detail: "Os resultados aparecem aqui quando uma partida for finalizada.", icon: "clock.arrow.circlepath")
            } else {
                ForEach(matches) { match in
                    NavigationLink {
                        LiveMatchView(matchID: match.id)
                    } label: {
                        MatchSummaryCard(match: match, store: store, showsStatus: false)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .contextMenu {
                        Button(role: .destructive) {
                            matchPendingDeletion = match.id
                            showDeleteConfirmation = true
                        } label: {
                            Label("Apagar partida", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Menu {
                ForEach(store.availableGames, id: \.self) { game in
                    Button(game) { selectedGame = game }
                }
            } label: {
                HStack {
                    Image(systemName: "dice.fill").foregroundColor(Theme.accent)
                    Text(selectedGame.isEmpty ? "Escolha um jogo" : selectedGame)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down").foregroundColor(Theme.accent)
                }
                .padding(11)
                .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 13))
            }
            .accessibilityIdentifier("match-ranking-game-picker")
            RankingTableView(groupID: groupID, selectedGame: $selectedGame)
        }
    }

    private func emptyState(title: String, detail: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 25, weight: .semibold)).foregroundColor(Theme.accent)
            Text(title).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(detail).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(Theme.mutedText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(.black.opacity(0.40), in: RoundedRectangle(cornerRadius: 17))
        .padding(.horizontal, 18)
    }
}

struct MatchSetupView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGroupID: UUID?
    @State private var selectedPlayerIDs = Set<UUID>()
    @State private var gameName: String
    @State private var matchID: UUID?

    init(initialGame: String? = nil) {
        _gameName = State(initialValue: initialGame ?? "")
    }

    private var selectedGroup: PlayerGroup { store.group(selectedGroupID ?? store.activeGroup.id) ?? store.activeGroup }

    var body: some View {
        ZStack {
            TableBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppScreenHeader(title: "Nova partida") { dismiss() }
                    Text("Prepare a mesa")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    groupSection
                    gameSection
                    playerSection

                    Button(action: startMatch) {
                        Label("COMEÇAR PARTIDA", systemImage: "play.fill")
                            .startPrimaryButton()
                    }
                    .disabled(gameName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPlayerIDs.count < 2)
                    .opacity(gameName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPlayerIDs.count < 2 ? 0.52 : 1)
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("start-match")
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $matchID) { id in
            LiveMatchView(matchID: id)
        }
        .onAppear {
            if selectedGroupID == nil {
                selectedGroupID = store.activeGroup.id
                selectedPlayerIDs = Set(store.activeGroup.players.map(\.id))
            }
        }
    }

    private var groupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("ESCOLHA A MESA")
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(store.data.groups) { group in
                        let selected = group.id == selectedGroup.id
                        Button {
                            selectedGroupID = group.id
                            selectedPlayerIDs = Set(group.players.map(\.id))
                            store.selectGroup(group.id)
                        } label: {
                            Text(group.name)
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(selected ? Theme.accentText : .white)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 9)
                                .background(selected ? Theme.accent : .black.opacity(0.48), in: Capsule())
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var gameSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel("QUAL JOGO?")
            TextField("Nome do jogo", text: $gameName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)
                .accessibilityIdentifier("match-game-name")
            ScrollView(.horizontal) {
                HStack(spacing: 7) {
                    ForEach(store.availableGames, id: \.self) { game in
                        Button(game) { gameName = game }
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(gameName == game ? Theme.accentText : .white.opacity(0.86))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(gameName == game ? Theme.accent : .black.opacity(0.48), in: Capsule())
                            .accessibilityIdentifier("match-game-option-\(game.slug)")
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("match-game-picker")
        }
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("QUEM VAI JOGAR?")
                Spacer()
                Text("\(selectedPlayerIDs.count) selecionados")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.mutedText)
            }
            .padding(.horizontal, 20)
            ForEach(selectedGroup.players) { player in
                let selected = selectedPlayerIDs.contains(player.id)
                Button {
                    if selected { selectedPlayerIDs.remove(player.id) }
                    else { selectedPlayerIDs.insert(player.id) }
                } label: {
                    HStack(spacing: 10) {
                        Text(String(player.name.prefix(1)).uppercased())
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(Theme.accentText)
                            .frame(width: 31, height: 31)
                            .background(selected ? Theme.accent : Theme.green, in: Circle())
                        Text(player.name).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Spacer()
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selected ? Theme.accent : .white.opacity(0.34))
                    }
                    .padding(10)
                    .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? Theme.accent.opacity(0.54) : .white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .accessibilityIdentifier("match-player-\(player.id.uuidString)")
            }
            if selectedGroup.players.count < 2 {
                Text("Adicione pelo menos 2 jogadores em Editar jogadores.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.mutedText)
                    .padding(.horizontal, 20)
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(1.2)
            .foregroundColor(Theme.accent)
            .padding(.horizontal, 20)
    }

    private func startMatch() {
        guard matchID == nil else { return }
        matchID = store.startMatch(gameName: gameName, groupID: selectedGroup.id, playerIDs: selectedPlayerIDs)
    }
}

struct LiveMatchView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    let matchID: UUID
    @State private var activeSheet: LiveMatchSheet?
    @State private var editingFinishedScore = false

    private var match: LocalMatch? { store.match(matchID) }

    var body: some View {
        ZStack {
            TableBackground()
            if let match {
                if match.status == .finished {
                    finishedView(match)
                } else {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        liveView(match, now: context.date)
                    }
                }
            } else {
                ContentUnavailableView("Partida não encontrada", systemImage: "exclamationmark.triangle")
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            if let match {
                switch sheet {
                case .result:
                    MatchResultPickerView(matchID: match.id, participants: match.participants, isEditing: match.status == .finished)
                        .environmentObject(store)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .preferredColorScheme(.dark)
                case .customTimer:
                    CustomTurnTimerView(matchID: match.id, currentDuration: match.turnDurationSeconds)
                        .environmentObject(store)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                        .preferredColorScheme(.dark)
                }
            }
        }
    }

    private func liveView(_ match: LocalMatch, now: Date) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 13) {
                AppScreenHeader(title: "Partida ao vivo") { dismiss() }
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(match.gameName)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(match.groupName) · \(match.participants.count) jogadores")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText)
                    }
                    Spacer()
                    Text(match.status == .paused ? "PAUSADA" : "AO VIVO")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(match.status == .paused ? Theme.accent : Theme.greenLight)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.48), in: Capsule())
                }
                .padding(.horizontal, 20)

                HStack(spacing: 9) {
                    timePanel(title: "TEMPO DE PARTIDA", value: formattedTime(store.elapsedSeconds(for: match, now: now)), icon: "stopwatch.fill")
                    timePanel(title: "RODADA", value: String(format: "%02d", match.currentRound), icon: "arrow.triangle.2.circlepath")
                }
                .padding(.horizontal, 18)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("PLACAR").font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.2).foregroundColor(Theme.accent)
                        Spacer()
                        Button("Desfazer") { store.undoLastScore(matchID: match.id) }
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.accentLight)
                            .disabled(match.scoreChanges.isEmpty)
                            .accessibilityIdentifier("undo-score")
                    }
                    ForEach(Array(match.participants.enumerated()), id: \.element.id) { index, player in
                        HStack(spacing: 9) {
                            Text(String(player.name.prefix(1)).uppercased())
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundColor(Theme.accentText)
                                .frame(width: 30, height: 30)
                                .background(WheelPalette.colors[index % WheelPalette.colors.count], in: Circle())
                            Text(player.name)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer(minLength: 2)
                            scoreButton("minus", id: "score-minus-\(index)") { store.changeScore(matchID: match.id, participantID: player.id, by: -1) }
                            Text("\(player.score)")
                                .font(.system(size: 21, weight: .black, design: .rounded).monospacedDigit())
                                .foregroundColor(Theme.accent)
                                .frame(minWidth: 38)
                                .accessibilityIdentifier("score-value-\(index)")
                            scoreButton("plus", id: "score-plus-\(index)") { store.changeScore(matchID: match.id, participantID: player.id, by: 1) }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.43), in: RoundedRectangle(cornerRadius: 12))
                    }
                    if !match.scoreChanges.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ÚLTIMOS AJUSTES")
                                .font(.system(size: 7, weight: .heavy, design: .rounded))
                                .tracking(0.9)
                                .foregroundColor(Theme.mutedText)
                            ForEach(Array(match.scoreChanges.suffix(3).reversed())) { change in
                                let name = match.participants.first(where: { $0.id == change.participantID })?.name ?? "Jogador"
                                Text("\(name)  \(change.delta > 0 ? "+" : "")\(change.delta)  →  \(change.scoreAfter) pts")
                                    .font(.system(size: 9, weight: .medium, design: .rounded).monospacedDigit())
                                    .foregroundColor(.white.opacity(0.72))
                            }
                        }
                        .padding(.top, 3)
                        .accessibilityIdentifier("score-change-history")
                    }
                }
                .padding(12)
                .background(Theme.card.opacity(0.82), in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.11), lineWidth: 1))
                .padding(.horizontal, 18)

                turnTimerPanel(match, now: now)
                    .padding(.horizontal, 18)

                Button {
                    if match.status == .paused { store.resumeMatch(matchID: match.id) }
                    else { store.pauseMatch(matchID: match.id) }
                } label: {
                    Label(match.status == .paused ? "RETOMAR PARTIDA" : "PAUSAR PARTIDA", systemImage: match.status == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .accessibilityIdentifier("toggle-match-pause")

                Button { store.advanceRound(matchID: match.id) } label: {
                    Label("PRÓXIMA RODADA", systemImage: "arrow.right.circle.fill")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.accentLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .disabled(match.status == .paused)
                .accessibilityIdentifier("next-round")

                Button {
                    activeSheet = .result
                } label: {
                    Label("ENCERRAR E REGISTRAR RESULTADO", systemImage: "flag.checkered")
                        .startPrimaryButton()
                }
                .padding(.horizontal, 20)
                .disabled(match.status == .paused)
                .accessibilityIdentifier("finish-match")
                Spacer(minLength: 18)
            }
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("live-match-screen")
    }

    private func timePanel(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.system(size: 7, weight: .heavy, design: .rounded))
                .tracking(0.7)
                .foregroundColor(Theme.mutedText)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 23, weight: .black, design: .rounded).monospacedDigit())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent.opacity(0.18), lineWidth: 1))
    }

    private func turnTimerPanel(_ match: LocalMatch, now: Date) -> some View {
        let remaining = store.turnSecondsRemaining(for: match, now: now)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("TIMER DE TURNO", systemImage: "hourglass")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundColor(Theme.accent)
                Spacer()
                Menu {
                    ForEach([30, 60, 90, 120, 180, 300], id: \.self) { seconds in
                        Button(timerPresetTitle(seconds)) { store.startTurnTimer(matchID: match.id, durationSeconds: seconds) }
                    }
                    Button("Personalizar…") { activeSheet = .customTimer }
                } label: {
                    Label("Duração", systemImage: "slider.horizontal.3")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.accentLight)
                }
                .accessibilityIdentifier("turn-timer-presets")
                .disabled(match.status == .paused)
            }
            HStack(alignment: .center) {
                Text(remaining.map(formattedTime) ?? "--:--")
                    .font(.system(size: 31, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundColor((remaining ?? 1) == 0 ? Color.red.opacity(0.9) : .white)
                    .accessibilityIdentifier("turn-timer-value")
                Spacer()
                Button {
                    if remaining == 0 { store.startTurnTimer(matchID: match.id, durationSeconds: match.turnDurationSeconds) }
                    else if match.turnTimerEndsAt != nil { store.pauseTurnTimer(matchID: match.id) }
                    else if match.turnTimerPaused { store.resumeTurnTimer(matchID: match.id) }
                    else { store.startTurnTimer(matchID: match.id, durationSeconds: match.turnDurationSeconds) }
                } label: {
                    Image(systemName: match.turnTimerEndsAt != nil && remaining != 0 ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Theme.accentText)
                        .frame(width: 40, height: 40)
                        .background(Theme.accent, in: Circle())
                }
                .accessibilityLabel(match.turnTimerEndsAt != nil && remaining != 0 ? "Pausar timer de turno" : "Iniciar timer de turno")
                .accessibilityIdentifier("toggle-turn-timer")
                .disabled(match.status == .paused)
                Button { store.stopTurnTimer(matchID: match.id) } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.84))
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.10), in: Circle())
                }
                .accessibilityLabel("Zerar timer de turno")
                .disabled(match.status == .paused)
            }
        }
        .padding(12)
        .background(Theme.card.opacity(0.84), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12), lineWidth: 1))
    }

    private func scoreButton(_ symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(symbol == "plus" ? Theme.accentText : .white)
                .frame(width: 30, height: 30)
                .background(symbol == "plus" ? Theme.accent : .white.opacity(0.10), in: Circle())
        }
        .accessibilityIdentifier(id)
    }

    private func finishedView(_ match: LocalMatch) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AppScreenHeader(title: "Resultado") { dismiss() }
                VStack(alignment: .leading, spacing: 6) {
                    Text("PARTIDA ENCERRADA")
                        .font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.4).foregroundColor(Theme.accent)
                    Text(match.gameName)
                        .font(.system(size: 25, weight: .black, design: .rounded)).foregroundColor(.white)
                    Text("\(match.groupName) · \(formattedTime(store.elapsedSeconds(for: match)))")
                        .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Theme.mutedText)
                }
                .padding(.horizontal, 20)
                HStack {
                    Text("PLACAR FINAL")
                        .font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.2).foregroundColor(Theme.accent)
                    Spacer()
                    Button(editingFinishedScore ? "Concluir edição" : "Editar pontos") {
                        editingFinishedScore.toggle()
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accentLight)
                    .accessibilityIdentifier("toggle-final-score-edit")
                }
                .padding(.horizontal, 20)
                ForEach(match.participants.sorted(by: { $0.score > $1.score })) { player in
                    HStack {
                        Image(systemName: match.winnerIDs.contains(player.id) ? "crown.fill" : "person.fill")
                            .foregroundColor(match.winnerIDs.contains(player.id) ? Theme.accent : Theme.mutedText)
                        Text(player.name).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Spacer()
                        if editingFinishedScore {
                            scoreButton("minus", id: "final-score-minus-\(player.id.uuidString)") {
                                store.correctFinishedScore(matchID: match.id, participantID: player.id, by: -1)
                            }
                        }
                        Text("\(player.score)").font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(Theme.accent)
                        if editingFinishedScore {
                            scoreButton("plus", id: "final-score-plus-\(player.id.uuidString)") {
                                store.correctFinishedScore(matchID: match.id, participantID: player.id, by: 1)
                            }
                        }
                    }
                    .padding(12)
                    .startCard(padding: 10)
                    .padding(.horizontal, 18)
                }
                Button { activeSheet = .result } label: {
                    Label("CORRIGIR VENCEDOR / EMPATE", systemImage: "pencil")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.accentLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .padding(.horizontal, 20)
                .accessibilityIdentifier("edit-match-winner")
                NavigationLink {
                    RankingView(initialGroupID: match.groupID, initialGame: match.gameName)
                } label: {
                    Label("VER RANKING DE \(match.gameName.uppercased())", systemImage: "list.number")
                        .startPrimaryButton()
                }
                .padding(.horizontal, 20)
                .accessibilityIdentifier("view-match-ranking")
                Spacer(minLength: 20)
            }
            .padding(.bottom, 22)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }
}

private struct CustomTurnTimerView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    let matchID: UUID
    @State private var minutes: Int
    @State private var seconds: Int

    init(matchID: UUID, currentDuration: Int) {
        self.matchID = matchID
        _minutes = State(initialValue: currentDuration / 60)
        _seconds = State(initialValue: currentDuration % 60)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TableBackground()
                VStack(spacing: 18) {
                    Text("Duração do turno")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    HStack(spacing: 22) {
                        Stepper(value: $minutes, in: 0...30) {
                            Text("\(minutes) min")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Stepper(value: $seconds, in: 0...59, step: 5) {
                            Text("\(seconds) seg")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .tint(Theme.accent)
                    Button {
                        let duration = max(10, minutes * 60 + seconds)
                        store.startTurnTimer(matchID: matchID, durationSeconds: duration)
                        dismiss()
                    } label: {
                        Label("INICIAR TIMER", systemImage: "hourglass")
                            .startPrimaryButton()
                    }
                    .accessibilityIdentifier("start-custom-timer")
                    Spacer()
                }
                .padding(22)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancelar") { dismiss() }.foregroundColor(Theme.accent)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

private struct MatchResultPickerView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    let matchID: UUID
    let participants: [MatchParticipant]
    let isEditing: Bool
    @State private var winnerIDs = Set<UUID>()

    var body: some View {
        NavigationStack {
            ZStack {
                TableBackground()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quem venceu?")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Selecione um vencedor ou vários em caso de empate. Deixe todos sem seleção para registrar um empate geral.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.mutedText)
                    ForEach(participants.sorted(by: { $0.score > $1.score })) { player in
                        let selected = winnerIDs.contains(player.id)
                        Button {
                            if selected { winnerIDs.remove(player.id) }
                            else { winnerIDs.insert(player.id) }
                        } label: {
                            HStack {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selected ? Theme.accent : .white.opacity(0.38))
                                Text(player.name).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                                Spacer()
                                Text("\(player.score) pts").font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundColor(Theme.accentLight)
                            }
                            .padding(11)
                            .background(.black.opacity(0.44), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityIdentifier("winner-select-\(player.id.uuidString)")
                    }
                    Spacer()
                    Button {
                        if isEditing {
                            store.updateFinishedMatchWinners(matchID: matchID, winnerIDs: winnerIDs)
                        } else {
                            store.finishMatch(matchID: matchID, winnerIDs: winnerIDs)
                        }
                        dismiss()
                    } label: {
                        Label(isEditing ? "ATUALIZAR RESULTADO" : "SALVAR RESULTADO", systemImage: "checkmark")
                            .startPrimaryButton()
                    }
                    .accessibilityIdentifier("confirm-match-result")
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancelar") { dismiss() }.foregroundColor(Theme.accent)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if isEditing {
                    winnerIDs = Set(store.match(matchID)?.winnerIDs ?? [])
                    return
                }
                guard winnerIDs.isEmpty, let highest = participants.map(\.score).max() else { return }
                winnerIDs = Set(participants.filter { $0.score == highest }.map(\.id))
            }
        }
    }
}

struct RankingView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGroupID: UUID?
    @State private var selectedGame: String

    init(initialGroupID: UUID? = nil, initialGame: String = "") {
        _selectedGroupID = State(initialValue: initialGroupID)
        _selectedGame = State(initialValue: initialGame)
    }

    private var groupID: UUID { selectedGroupID ?? store.activeGroup.id }
    private var gameName: String { selectedGame.isEmpty ? (store.availableGames.first ?? "Arnak") : selectedGame }

    var body: some View {
        ZStack {
            TableBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    AppScreenHeader(title: "Ranking") { dismiss() }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CLASSIFICAÇÃO LOCAL")
                            .font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.4).foregroundColor(Theme.accent)
                        Text("Quem lidera a mesa?")
                            .font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                        Text("Vitórias primeiro · partidas, empates e pontos também contam.")
                            .font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(Theme.mutedText)
                    }
                    .padding(.horizontal, 20)
                    selectionMenus
                    RankingTableView(groupID: groupID, selectedGame: $selectedGame)
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            selectedGroupID = selectedGroupID ?? store.activeGroup.id
            let firstPlayedGame = store.completedMatches.first(where: { $0.groupID == groupID })?.gameName
            selectedGame = selectedGame.isEmpty ? (firstPlayedGame ?? store.availableGames.first ?? "Arnak") : selectedGame
        }
        .accessibilityIdentifier("ranking-screen")
    }

    private var selectionMenus: some View {
        VStack(spacing: 8) {
            Menu {
                ForEach(store.data.groups) { group in
                    Button(group.name) {
                        selectedGroupID = group.id
                        store.selectGroup(group.id)
                    }
                }
            } label: {
                selectionRow(title: "GRUPO", value: store.group(groupID)?.name ?? store.activeGroup.name, icon: "person.2.fill")
            }
            .accessibilityIdentifier("ranking-group-picker")
            Menu {
                ForEach(store.availableGames, id: \.self) { game in
                    Button(game) { selectedGame = game }
                }
            } label: {
                selectionRow(title: "JOGO", value: gameName, icon: "dice.fill")
            }
            .accessibilityIdentifier("ranking-game-picker")
        }
        .padding(.horizontal, 20)
    }

    private func selectionRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 7, weight: .heavy, design: .rounded)).tracking(1).foregroundColor(Theme.mutedText)
                Text(value).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
            }
            Spacer()
            Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.accent)
        }
        .padding(11)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 13))
    }
}

private struct RankingTableView: View {
    @EnvironmentObject private var store: PlayerStore
    let groupID: UUID
    @Binding var selectedGame: String

    private var standings: [PlayerStanding] { store.ranking(groupID: groupID, gameName: selectedGame.isEmpty ? (store.availableGames.first ?? "") : selectedGame) }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(selectedGame.isEmpty ? "RANKING" : selectedGame.uppercased())
                    .font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.1).foregroundColor(Theme.accent)
                Spacer()
                Text("V · E · D · PTS")
                    .font(.system(size: 7, weight: .heavy, design: .rounded)).foregroundColor(Theme.mutedText)
            }
            if standings.isEmpty {
                VStack(spacing: 7) {
                    Image(systemName: "chart.bar.xaxis").font(.system(size: 24)).foregroundColor(Theme.accent.opacity(0.85))
                    Text("Ainda sem resultados")
                        .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text("Finalize uma partida deste jogo para criar o ranking.")
                        .font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(Theme.mutedText).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .accessibilityIdentifier("ranking-empty")
            } else {
                ForEach(Array(standings.enumerated()), id: \.element.id) { index, standing in
                    HStack(spacing: 9) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 11, weight: .black, design: .rounded).monospacedDigit())
                            .foregroundColor(index == 0 ? Theme.accent : Theme.mutedText)
                            .frame(width: 25)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(standing.name).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
                            Text("\(standing.played) partidas · \(Int(standing.winRate * 100))% vitórias")
                                .font(.system(size: 8, weight: .medium, design: .rounded)).foregroundColor(Theme.mutedText)
                        }
                        Spacer(minLength: 2)
                        Text("\(standing.wins)·\(standing.draws)·\(standing.losses)")
                            .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundColor(.white.opacity(0.80))
                        Text("\(standing.points)")
                            .font(.system(size: 14, weight: .black, design: .rounded).monospacedDigit())
                            .foregroundColor(Theme.accent)
                            .frame(minWidth: 31, alignment: .trailing)
                    }
                    .padding(9)
                    .background(index == 0 ? Theme.accent.opacity(0.10) : .black.opacity(0.38), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(index == 0 ? Theme.accent.opacity(0.24) : .white.opacity(0.08), lineWidth: 1))
                }
            }
        }
        .padding(12)
        .background(Theme.card.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.12), lineWidth: 1))
        .padding(.horizontal, 18)
    }
}

private struct MatchSummaryCard: View {
    let match: LocalMatch
    @ObservedObject var store: PlayerStore
    let showsStatus: Bool

    private var leaders: String {
        if match.status == .finished {
            let names = match.participants.filter { match.winnerIDs.contains($0.id) }.map(\.name)
            return names.isEmpty ? "Empate" : names.joined(separator: ", ")
        }
        return match.participants.sorted { $0.score > $1.score }.prefix(2).map { "\($0.name) \($0.score)" }.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: showsStatus ? "dot.radiowaves.left.and.right" : "checkmark.circle.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(showsStatus ? Theme.greenLight : Theme.accent)
                .frame(width: 39, height: 39)
                .background(.black.opacity(0.38), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(match.gameName).font(.system(size: 13, weight: .black, design: .rounded)).foregroundColor(.white)
                Text(leaders).font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundColor(Theme.accentLight).lineLimit(1)
                Text(match.groupName + " · " + match.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 8, weight: .medium, design: .rounded)).foregroundColor(Theme.mutedText)
            }
            Spacer(minLength: 0)
            if showsStatus {
                Text("AO VIVO").font(.system(size: 7, weight: .black, design: .rounded)).tracking(0.5).foregroundColor(Theme.greenLight)
            } else {
                Text(formattedTime(store.elapsedSeconds(for: match)))
                    .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit()).foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.44), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.12), lineWidth: 1))
        .padding(.horizontal, showsStatus ? 18 : 0)
    }
}

private func formattedTime(_ seconds: Int) -> String {
    String(format: "%02d:%02d", max(0, seconds) / 60, max(0, seconds) % 60)
}

private func timerPresetTitle(_ seconds: Int) -> String {
    seconds < 60 ? "\(seconds) segundos" : "\(seconds / 60) minuto\(seconds == 60 ? "" : "s")"
}

private extension String {
    var slug: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: " ", with: "-")
    }
}
