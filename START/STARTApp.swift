import SwiftUI

@main
struct STARTApp: App {
    @StateObject private var players = PlayerStore()

    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                ZStack {
                    Theme.background.ignoresSafeArea()
                    AppLaunchView(players: players)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .preferredColorScheme(.dark)
        }
    }
}

private enum AppLaunchPhase: Equatable {
    case loading
    case onboarding
    case home
}

struct AppLaunchView: View {
    @ObservedObject var players: PlayerStore
    @AppStorage("start.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var phase: AppLaunchPhase = .loading

    private var launchArguments: [String] { ProcessInfo.processInfo.arguments }
    private var isOnboardingCapture: Bool { launchArguments.contains("-capture-onboarding") }
    private var isVisualCapture: Bool {
        launchArguments.contains("-screenshot-mode") || (launchArguments.contains(where: { $0.hasPrefix("-capture-") }) && !isOnboardingCapture)
    }

    var body: some View {
        ZStack {
            TableBackground()
            Group {
                switch phase {
                case .loading:
                    AppLoadingView()
                case .onboarding:
                    AppOnboardingView(onComplete: completeOnboarding)
                case .home:
                    ContentView()
                        .environmentObject(players)
                        .buttonStyle(StartButtonMotionStyle())
                }
            }
            .transition(.opacity)
        }
        .background(Theme.background)
        .animation(.easeInOut(duration: 0.3), value: phase)
        .task {
            if launchArguments.contains("-reset-onboarding") || isOnboardingCapture {
                hasCompletedOnboarding = false
            }
            if isOnboardingCapture {
                phase = .onboarding
                return
            }
            if isVisualCapture {
                phase = .home
                return
            }
            try? await Task.sleep(nanoseconds: 720_000_000)
            guard !Task.isCancelled else { return }
            phase = hasCompletedOnboarding ? .home : .onboarding
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        phase = .loading
        Task {
            try? await Task.sleep(nanoseconds: 460_000_000)
            guard !Task.isCancelled else { return }
            phase = .home
        }
    }
}

private struct AppLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 20) {
            StartLogo()
                .scaleEffect(isPulsing ? 1 : 0.94)
                .animation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true), value: isPulsing)

            VStack(spacing: 8) {
                Text("PREPARANDO A MESA")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2.1)
                    .foregroundColor(Theme.accent)
                ProgressView()
                    .tint(Theme.accentLight)
                    .accessibilityLabel("Carregando o START")
            }
        }
        .onAppear { isPulsing = !reduceMotion }
    }
}

private struct OnboardingTip: Identifiable {
    let id: Int
    let eyebrow: String
    let title: String
    let detail: String
    let symbol: String
}

private struct AppOnboardingView: View {
    let onComplete: () -> Void
    @State private var selectedPage = 0

    private let tips = [
        OnboardingTip(id: 0, eyebrow: "SORTEIO JUSTO", title: "A primeira vez é no acaso.", detail: "Role dados de D4 a D20 e deixe o resultado decidir quem começa.", symbol: "die.face.5.fill"),
        OnboardingTip(id: 1, eyebrow: "TODO MUNDO JOGA", title: "Escolham juntos.", detail: "Toquem na tela ao mesmo tempo ou revelem uma carta por pessoa.", symbol: "hand.tap.fill"),
        OnboardingTip(id: 2, eyebrow: "SEMPRE À MÃO", title: "A mesa não precisa de internet.", detail: "Dados, cartas e situações ficam prontos para a próxima partida.", symbol: "rectangle.stack.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                StartLogo(compact: true)
                Spacer()
                Button("PULAR", action: onComplete)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.70))
                    .accessibilityIdentifier("onboarding-skip")
            }
            .padding(.top, 12)

            TabView(selection: $selectedPage) {
                ForEach(tips) { tip in
                    onboardingPage(tip)
                        .tag(tip.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityIdentifier("onboarding-pages")

            HStack(spacing: 7) {
                ForEach(tips) { tip in
                    Capsule()
                        .fill(selectedPage == tip.id ? Theme.accent : .white.opacity(0.22))
                        .frame(width: selectedPage == tip.id ? 22 : 6, height: 6)
                }
            }
            .padding(.bottom, 24)

            Button(action: advance) {
                HStack {
                    Text(selectedPage == tips.count - 1 ? "COMEÇAR A JOGAR" : "CONTINUAR")
                    Spacer()
                    Image(systemName: selectedPage == tips.count - 1 ? "sparkles" : "arrow.right")
                }
                .startPrimaryButton()
            }
            .buttonStyle(StartButtonMotionStyle())
            .accessibilityIdentifier(selectedPage == tips.count - 1 ? "onboarding-start" : "onboarding-next")
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 22)
    }

    private func onboardingPage(_ tip: OnboardingTip) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.accent.opacity(0.24), .clear], center: .center, startRadius: 8, endRadius: 138))
                    .frame(width: 276, height: 276)
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(colors: [Theme.cardRaised.opacity(0.82), .black.opacity(0.76)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Theme.accent.opacity(0.34), lineWidth: 1))
                    .frame(width: 180, height: 210)
                    .overlay {
                        Image(systemName: tip.symbol)
                            .font(.system(size: 64, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Theme.accentLight)
                    }
                    .rotationEffect(.degrees(selectedPage == tip.id ? 0 : -4))
                    .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 14)
            }
            .frame(maxHeight: 290)

            VStack(spacing: 9) {
                Text(tip.eyebrow)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundColor(Theme.accent)
                Text(tip.title)
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                Text(tip.detail)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 330)
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("onboarding-page-\(tip.id)")
    }

    private func advance() {
        if selectedPage == tips.count - 1 {
            onComplete()
        } else {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                selectedPage += 1
            }
        }
    }
}
