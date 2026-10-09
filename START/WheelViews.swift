import SwiftUI

enum WheelPalette {
    static let colors: [Color] = [
        Color(red: 0.07, green: 0.55, blue: 0.82),
        Color(red: 0.91, green: 0.28, blue: 0.34),
        Color(red: 0.38, green: 0.31, blue: 0.72),
        Color(red: 0.91, green: 0.26, blue: 0.58),
        Color(red: 0.94, green: 0.51, blue: 0.12),
        Color(red: 0.35, green: 0.71, blue: 0.31),
        Color(red: 0.12, green: 0.68, blue: 0.67),
        Color(red: 0.79, green: 0.67, blue: 0.18)
    ]

    static func color(_ index: Int) -> Color { colors[index % colors.count] }
}

private enum WheelLibrarySheet: Identifiable {
    case editor(UUID?)
    case players

    var id: String {
        switch self {
        case .editor(let wheelID): return "editor-\(wheelID?.uuidString ?? "new")"
        case .players: return "players"
        }
    }
}

struct WheelsLibraryView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection = 0
    @State private var activeSheet: WheelLibrarySheet?

    init() {
        _selectedSection = State(initialValue: ProcessInfo.processInfo.arguments.contains("-capture-templates") ? 1 : 0)
    }

    var body: some View {
        ZStack {
            TableBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    AppScreenHeader(title: "Roletas") { dismiss() }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("SORTEIE O PRÓXIMO PASSO")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(1.6)
                            .foregroundColor(Theme.accent)
                        Text("Roletas da mesa")
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Escolha um jogo ou sorteie uma opção dentro dele.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText)
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 8) {
                        Label(store.activeGroup.name, systemImage: "person.2.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.accentLight)
                        Spacer()
                        Button("Mesas") { activeSheet = .players }
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.horizontal, 20)

                    Picker("Biblioteca", selection: $selectedSection) {
                        Text("Minhas roletas").tag(0)
                        Text("Templates").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("wheel-library-picker")

                    if selectedSection == 0 {
                        Button {
                            activeSheet = .editor(nil)
                        } label: {
                            Label("CRIAR ROLETA", systemImage: "plus.circle.fill")
                                .startPrimaryButton()
                        }
                        .padding(.horizontal, 20)
                        .accessibilityIdentifier("create-wheel")

                        ForEach(store.data.wheels) { wheel in
                            wheelCard(wheel)
                        }
                        if store.data.wheels.isEmpty {
                            ContentUnavailableView("Sua mesa ainda não tem roletas", systemImage: "circle.dashed", description: Text("Crie uma ou adicione um template para começar."))
                                .padding(.top, 16)
                        }
                    } else {
                        Text("Templates offline · adicione uma cópia editável à sua mesa.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText)
                            .padding(.horizontal, 20)
                        ForEach(WheelTemplate.catalog) { template in
                            templateCard(template)
                        }
                    }
                    Spacer(minLength: 22)
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editor(let wheelID):
                WheelEditorView(wheelID: wheelID)
                    .environmentObject(store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .preferredColorScheme(.dark)
            case .players:
                PlayerManagerView()
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .preferredColorScheme(.dark)
            }
        }
    }

    private func wheelCard(_ wheel: SavedWheel) -> some View {
        HStack(spacing: 13) {
            NavigationLink {
                WheelPlayView(wheelID: wheel.id)
            } label: {
                HStack(spacing: 13) {
                    WheelArtwork(options: wheel.options, rotation: 0)
                        .frame(width: 88, height: 88)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(wheel.title)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Text(wheel.gameName ?? (wheel.isGamePicker ? "Escolher jogo" : "Roleta personalizada"))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mutedText)
                        Text("\(wheel.options.count) OPÇÕES")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(Theme.accent)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Theme.accent)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("wheel-open-\(wheel.id.uuidString)")
            VStack(spacing: 7) {
                Button {
                    activeSheet = .editor(wheel.id)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.accentText)
                        .frame(width: 37, height: 37)
                        .background(Theme.accent, in: Circle())
                }
                .accessibilityLabel("Editar \(wheel.title)")
                Button { _ = store.duplicateWheel(wheel.id) } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 37, height: 37)
                        .background(Theme.green, in: Circle())
                }
                .accessibilityLabel("Duplicar \(wheel.title)")
                Button { store.deleteWheel(wheel.id) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 37, height: 37)
                        .background(Color(red: 0.78, green: 0.20, blue: 0.26), in: Circle())
                }
                .accessibilityLabel("Apagar \(wheel.title)")
            }
        }
        .padding(12)
        .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.14), lineWidth: 1))
        .padding(.horizontal, 18)
    }

    private func templateCard(_ template: WheelTemplate) -> some View {
        let isInstalled = store.data.wheels.contains(where: { $0.templateID == template.id })
        return HStack(spacing: 12) {
            WheelArtwork(options: template.options.enumerated().map { WheelOption(title: $0.element, colorIndex: $0.offset) }, rotation: 0)
                .frame(width: 74, height: 74)
            VStack(alignment: .leading, spacing: 4) {
                Text(template.gameName ?? template.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(template.title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent)
                Text(template.description)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.mutedText)
                    .lineLimit(2)
            }
            Spacer(minLength: 3)
            Button {
                _ = store.importTemplate(template)
            } label: {
                Image(systemName: isInstalled ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(isInstalled ? Theme.greenLight : Theme.accent)
            }
            .disabled(isInstalled)
            .accessibilityLabel(isInstalled ? "Template adicionado" : "Adicionar template \(template.title)")
            .accessibilityIdentifier("install-template-\(template.id)")
        }
        .padding(11)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.12), lineWidth: 1))
        .padding(.horizontal, 18)
    }
}

struct WheelPlayView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    let wheelID: UUID?

    @State private var rotation = 0.0
    @State private var presentedOptions: [WheelOption]?
    @State private var isSpinning = false
    @State private var selectedResult: String?
    @State private var activeSheet: WheelLibrarySheet?

    private var wheel: SavedWheel? {
        if let wheelID, let wheel = store.wheel(wheelID) { return wheel }
        return store.data.wheels.first(where: { $0.isGamePicker }) ?? store.data.wheels.first
    }

    var body: some View {
        ZStack {
            TableBackground()
            if let wheel {
                let visibleOptions = presentedOptions ?? wheel.options
                GeometryReader { geometry in
                    VStack(spacing: 14) {
                        AppScreenHeader(title: "Roleta") { dismiss() }
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(wheel.title)
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                Text(wheel.gameName ?? "\(visibleOptions.count) opções · chances iguais")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.mutedText)
                            }
                            Spacer()
                            Button { activeSheet = .players } label: {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.accent)
                                    .frame(width: 40, height: 40)
                                    .background(.black.opacity(0.38), in: Circle())
                            }
                            .disabled(isSpinning)
                            Button {
                                presentedOptions = nil
                                activeSheet = .editor(wheel.id)
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.accentText)
                                    .frame(width: 40, height: 40)
                                    .background(Theme.accent, in: Circle())
                            }
                            .disabled(isSpinning)
                        }
                        .padding(.horizontal, 20)
                        Spacer(minLength: 4)

                        ZStack(alignment: .top) {
                            WheelArtwork(options: visibleOptions, rotation: rotation)
                                .frame(width: min(geometry.size.width - 50, geometry.size.height * 0.48), height: min(geometry.size.width - 50, geometry.size.height * 0.48))
                                .padding(.top, 16)
                            Triangle()
                                .fill(.white)
                                .frame(width: 31, height: 30)
                                .overlay(Triangle().stroke(.black.opacity(0.72), lineWidth: 2))
                                .shadow(color: .black.opacity(0.56), radius: 4, y: 2)
                                .zIndex(2)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("roulette-wheel")

                        if let selectedResult {
                            VStack(spacing: 4) {
                                Text(wheel.isGamePicker ? "JOGO SORTEADO" : "OPÇÃO SORTEADA")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .tracking(1.4)
                                    .foregroundColor(Theme.accent)
                                Text(selectedResult)
                                    .font(.system(size: 23, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .accessibilityIdentifier("wheel-selected-result")
                            }
                            .padding(.horizontal, 22)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            Text("QUEM SABE O QUE VEM AGORA?")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1.3)
                                .foregroundColor(.white.opacity(0.68))
                        }

                        Button { spin(wheel) } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text(isSpinning ? "SORTEANDO…" : "GIRAR ROLETA")
                                Spacer()
                                Image(systemName: "sparkles")
                            }
                            .startPrimaryButton()
                        }
                        .disabled(isSpinning || wheel.options.count < 2)
                        .padding(.horizontal, 20)
                        .accessibilityIdentifier("spin-wheel")

                        if wheel.isGamePicker, let selectedResult, !isSpinning {
                            NavigationLink {
                                MatchSetupView(initialGame: selectedResult)
                            } label: {
                                Label("COMEÇAR PARTIDA DE \(selectedResult.uppercased())", systemImage: "play.fill")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(Theme.accentLight)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .padding(.horizontal, 20)
                            .accessibilityIdentifier("start-selected-game")
                        }

                        if wheel.removeWinnerAfterSpin {
                            Text("A opção sorteada sai da roleta.")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.mutedText)
                        }
                        let recentSpins = store.data.spinHistory.filter { $0.wheelID == wheel.id }.prefix(3)
                        if !recentSpins.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ÚLTIMOS RESULTADOS")
                                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                                    .tracking(1)
                                    .foregroundColor(Theme.mutedText)
                                ForEach(Array(recentSpins)) { record in
                                    Text("\(record.optionTitle) · \(record.spunAt.formatted(date: .omitted, time: .shortened))")
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        Spacer(minLength: 10)
                    }
                    .frame(maxWidth: 560, maxHeight: .infinity)
                    .frame(maxWidth: .infinity)
                }
            } else {
                ContentUnavailableView("Nenhuma roleta disponível", systemImage: "circle.dashed", description: Text("Adicione um template ou crie sua roleta."))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editor(let wheelID):
                WheelEditorView(wheelID: wheelID)
                    .environmentObject(store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .preferredColorScheme(.dark)
            case .players:
                PlayerManagerView()
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .preferredColorScheme(.dark)
            }
        }
    }

    private func spin(_ wheel: SavedWheel) {
        guard wheel.options.count > 1, !isSpinning else { return }
        presentedOptions = wheel.options
        selectedResult = nil
        isSpinning = true
        let index = Int.random(in: 0..<wheel.options.count)
        let option = wheel.options[index]
        let groupID = store.activeGroup.id
        let slice = 360.0 / Double(wheel.options.count)
        let desired = (360 - (Double(index) + 0.5) * slice).truncatingRemainder(dividingBy: 360)
        let current = rotation.truncatingRemainder(dividingBy: 360)
        let correction = (desired - current + 360).truncatingRemainder(dividingBy: 360)
        let target = rotation + 5 * 360 + correction
        GameFeedback.play(.diceRoll)
        withAnimation(.timingCurve(0.12, 0.66, 0.18, 1.0, duration: 4.2)) {
            rotation = target
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_250_000_000)
            guard !Task.isCancelled else { return }
            store.recordSpin(wheelID: wheel.id, optionID: option.id, groupID: groupID)
            selectedResult = option.title
            isSpinning = false
            GameFeedback.play(.winner)
            GameFeedback.success()
        }
    }
}

struct WheelEditorView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    let wheelID: UUID?

    @State private var title = ""
    @State private var gameName = ""
    @State private var isGamePicker = false
    @State private var removeWinnerAfterSpin = false
    @State private var optionTitles: [String] = ["Opção 1", "Opção 2", "Opção 3"]
    @State private var didLoad = false

    init(wheelID: UUID?) {
        self.wheelID = wheelID
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TableBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(wheelID == nil ? "Monte sua roleta" : "Editar roleta")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        TextField("Nome da roleta", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("wheel-title-field")
                        TextField("Jogo relacionado (opcional)", text: $gameName)
                            .textFieldStyle(.roundedBorder)
                        Toggle("Esta roleta escolhe um jogo", isOn: $isGamePicker)
                            .tint(Theme.accent)
                        Toggle("Remover a opção sorteada", isOn: $removeWinnerAfterSpin)
                            .tint(Theme.accent)
                        HStack {
                            Text("OPÇÕES")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .tracking(1.2)
                                .foregroundColor(Theme.accent)
                            Spacer()
                            Text("Mínimo de 2")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.mutedText)
                        }
                        ForEach(optionTitles.indices, id: \.self) { index in
                            HStack(spacing: 8) {
                                Button {
                                    guard index > 0 else { return }
                                    optionTitles.swapAt(index, index - 1)
                                } label: {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.white.opacity(index > 0 ? 0.85 : 0.28))
                                }
                                .disabled(index == 0)
                                .accessibilityLabel("Mover opção \(index + 1) para cima")
                                Button {
                                    guard index + 1 < optionTitles.count else { return }
                                    optionTitles.swapAt(index, index + 1)
                                } label: {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.white.opacity(index + 1 < optionTitles.count ? 0.85 : 0.28))
                                }
                                .disabled(index + 1 >= optionTitles.count)
                                .accessibilityLabel("Mover opção \(index + 1) para baixo")
                                Circle().fill(WheelPalette.color(index)).frame(width: 12, height: 12)
                                TextField("Opção \(index + 1)", text: $optionTitles[index])
                                    .textFieldStyle(.roundedBorder)
                                    .accessibilityIdentifier("wheel-option-\(index)")
                                Button {
                                    guard optionTitles.count > 2 else { return }
                                    optionTitles.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red.opacity(0.85))
                                        .font(.system(size: 20))
                                }
                                .disabled(optionTitles.count <= 2)
                            }
                        }
                        Button {
                            optionTitles.append("Opção \(optionTitles.count + 1)")
                        } label: {
                            Label("ADICIONAR OPÇÃO", systemImage: "plus")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(Theme.accent)
                                .padding(.vertical, 8)
                        }
                        .accessibilityIdentifier("add-wheel-option")
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.foregroundColor(Theme.mutedText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salvar") { save() }
                        .foregroundColor(Theme.accent)
                        .fontWeight(.bold)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || optionTitles.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count < 2)
                        .accessibilityIdentifier("save-wheel")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear(perform: loadWheel)
        }
    }

    private func loadWheel() {
        guard !didLoad else { return }
        didLoad = true
        guard let wheelID, let wheel = store.wheel(wheelID) else { return }
        title = wheel.title
        gameName = wheel.gameName ?? ""
        isGamePicker = wheel.isGamePicker
        removeWinnerAfterSpin = wheel.removeWinnerAfterSpin
        optionTitles = wheel.options.map(\.title)
    }

    private func save() {
        let options = optionTitles.enumerated().compactMap { index, option -> WheelOption? in
            let cleaned = option.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else { return nil }
            return WheelOption(title: cleaned, colorIndex: index)
        }
        if let wheelID, var wheel = store.wheel(wheelID) {
            wheel.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            wheel.gameName = gameName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : gameName.trimmingCharacters(in: .whitespacesAndNewlines)
            wheel.isGamePicker = isGamePicker
            wheel.removeWinnerAfterSpin = removeWinnerAfterSpin
            wheel.options = options
            store.saveWheel(wheel)
        } else {
            guard let newID = store.createWheel(title: title, gameName: gameName, options: options.map(\.title), isGamePicker: isGamePicker),
                  var wheel = store.wheel(newID) else { return }
            wheel.removeWinnerAfterSpin = removeWinnerAfterSpin
            store.saveWheel(wheel)
        }
        dismiss()
    }
}

private struct WheelArtwork: View {
    let options: [WheelOption]
    let rotation: Double

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    let slice = 360.0 / Double(max(options.count, 1))
                    WheelSlice(startDegrees: -90 + Double(index) * slice, endDegrees: -90 + Double(index + 1) * slice)
                        .fill(WheelPalette.color(option.colorIndex))
                        .overlay {
                            WheelSlice(startDegrees: -90 + Double(index) * slice, endDegrees: -90 + Double(index + 1) * slice)
                                .stroke(Color.black.opacity(0.45), lineWidth: max(1, size * 0.008))
                        }
                        .overlay {
                            GeometryReader { sliceGeometry in
                                let center = -90 + (Double(index) + 0.5) * slice
                                let radians = center * .pi / 180
                                let radius = size * 0.30
                                Text(option.title)
                                    .font(.system(size: max(6, min(12, size * 0.042)), weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.55)
                                    .multilineTextAlignment(.center)
                                    .frame(width: size * 0.34)
                                    .rotationEffect(.degrees(center + 90))
                                    .position(
                                        x: sliceGeometry.size.width / 2 + CGFloat(cos(radians)) * radius,
                                        y: sliceGeometry.size.height / 2 + CGFloat(sin(radians)) * radius
                                    )
                            }
                        }
                }
                Circle()
                    .fill(Theme.cardRaised)
                    .frame(width: size * 0.30, height: size * 0.30)
                    .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
                    .overlay {
                        Text("START")
                            .font(.system(size: max(8, size * 0.055), weight: .black, design: .rounded))
                            .tracking(1.4)
                            .foregroundColor(Theme.accent)
                    }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(.black.opacity(0.72), lineWidth: max(3, size * 0.025)))
            .shadow(color: .black.opacity(0.4), radius: size * 0.05, x: 0, y: size * 0.03)
            .rotationEffect(.degrees(rotation))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Roleta com \(options.count) opções")
    }
}

private struct WheelSlice: Shape {
    let startDegrees: Double
    let endDegrees: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: .degrees(startDegrees), endAngle: .degrees(endDegrees), clockwise: false)
        path.closeSubpath()
        return path
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
