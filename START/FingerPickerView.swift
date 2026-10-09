import SwiftUI
import UIKit

struct FingerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var winnerIndex: Int?
    @State private var touchCount = 0
    @State private var status = "Toquem e segurem na tela"

    var body: some View {
        GeometryReader { geometry in
            let arenaHeight = max(310, min(440, geometry.size.height * 0.52))

            ZStack {
                TableBackground()
                ScrollView {
                    VStack(spacing: 0) {
                        AppScreenHeader(title: "Dedos") { dismiss() }
                        Spacer(minLength: 16)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("TODO MUNDO AO MESMO TEMPO")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1.6)
                                .foregroundColor(Theme.accent)
                            Text("Dedos na mesa")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("Cada pessoa segura um ponto. O START escolhe um dedo.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        Spacer(minLength: 20)

                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(LinearGradient(colors: [.black.opacity(0.75), Theme.cardRaised.opacity(0.90)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Theme.accent.opacity(0.32), lineWidth: 1)

                            MultiTouchView(winnerIndex: $winnerIndex, touchCount: $touchCount, status: $status)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .accessibilityIdentifier("finger-area")

                            VStack(spacing: 4) {
                                Text(status.uppercased())
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .tracking(1.1)
                                    .foregroundColor(winnerIndex == nil ? .white.opacity(0.88) : Theme.accent)
                                    .accessibilityIdentifier("finger-result")
                                Text(touchCount >= 2 ? "\(touchCount) DEDOS NA MESA" : "2 A 8 JOGADORES")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .tracking(1)
                                    .foregroundColor(.white.opacity(0.56))
                            }
                            .padding(.top, 15)
                            .allowsHitTesting(false)
                        }
                        .frame(height: arenaHeight)
                        .padding(.horizontal, 18)
                        .overlay(alignment: .bottom) {
                            if winnerIndex != nil {
                                Text("DEDO \((winnerIndex ?? 0) + 1) COMEÇA! ✨")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .tracking(0.8)
                                    .foregroundColor(Theme.accentText)
                                    .padding(.horizontal, 19)
                                    .padding(.vertical, 11)
                                    .background(Theme.accent, in: Capsule())
                                    .offset(y: -17)
                                    .accessibilityIdentifier("finger-winner")
                            }
                        }
                        Spacer(minLength: 14)

                        HStack(spacing: 7) {
                            Image(systemName: "hand.point.up.left.fill").foregroundColor(Theme.accent)
                            Text("Segurem por 2 segundos. Quem soltar antes sai do sorteio.")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 21)
                        Spacer(minLength: 12)

                        Button {
                            winnerIndex = nil
                            touchCount = 0
                            status = "Toquem e segurem na tela"
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("NOVA ESCOLHA")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .startPrimaryButton()
                        }
                        .padding(.horizontal, 20)
                        .accessibilityIdentifier("finger-reset")
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
    }
}

struct MultiTouchView: UIViewRepresentable {
    @Binding var winnerIndex: Int?
    @Binding var touchCount: Int
    @Binding var status: String

    func makeUIView(context: Context) -> TouchCanvas {
        let view = TouchCanvas()
        view.onUpdate = { count, winner, message in
            DispatchQueue.main.async {
                touchCount = count
                winnerIndex = winner
                status = message
            }
        }
        return view
    }

    func updateUIView(_ uiView: TouchCanvas, context: Context) {
        if winnerIndex == nil && touchCount == 0 { uiView.reset() }
    }
}

final class TouchCanvas: UIView {
    var onUpdate: ((Int, Int?, String) -> Void)?

    private var touchesById: [Int: CGPoint] = [:]
    private var participantOrder: [Int] = []
    private var winnerID: Int?
    private var lockTimer: Timer?
    private let colors: [UIColor] = [
        UIColor(red: 0.25, green: 0.91, blue: 0.48, alpha: 1),
        UIColor(red: 0.22, green: 0.68, blue: 1, alpha: 1),
        UIColor(red: 1, green: 0.33, blue: 0.29, alpha: 1),
        UIColor(red: 0.72, green: 0.43, blue: 1, alpha: 1),
        UIColor(red: 1, green: 0.64, blue: 0.20, alpha: 1),
        UIColor(red: 0.24, green: 0.88, blue: 0.84, alpha: 1),
        UIColor(red: 1, green: 0.43, blue: 0.67, alpha: 1),
        UIColor(red: 1, green: 0.82, blue: 0.25, alpha: 1)
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        contentMode = .redraw
    }

    func reset() {
        touchesById.removeAll()
        participantOrder.removeAll()
        winnerID = nil
        lockTimer?.invalidate()
        lockTimer = nil
        setNeedsDisplay()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let id = touch.hash
            if touchesById[id] == nil { participantOrder.append(id) }
            touchesById[id] = touch.location(in: self)
        }
        winnerID = nil
        evaluate()
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { touchesById[touch.hash] = touch.location(in: self) }
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { touchesById.removeValue(forKey: touch.hash) }
        participantOrder.removeAll { touchesById[$0] == nil }
        if touchesById.count < 2 && winnerID == nil {
            lockTimer?.invalidate()
            lockTimer = nil
            onUpdate?(touchesById.count, nil, touchesById.isEmpty ? "Toquem e segurem na tela" : "Mais uma pessoa para começar")
        }
        setNeedsDisplay()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func evaluate() {
        let count = touchesById.count
        guard count >= 2 else {
            onUpdate?(count, nil, count == 0 ? "Toquem e segurem na tela" : "Mais uma pessoa para começar")
            return
        }
        lockTimer?.invalidate()
        onUpdate?(count, nil, "Segurem… sorteando")
        lockTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            let active = self.participantOrder.filter { self.touchesById[$0] != nil }
            guard active.count >= 2, let picked = active.randomElement(), let index = active.firstIndex(of: picked) else { return }
            self.winnerID = picked
            self.onUpdate?(active.count, index, "Temos um dedo vencedor!")
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let active = participantOrder.filter { touchesById[$0] != nil }
        if active.isEmpty {
            drawTargets(in: rect, context: context)
            return
        }

        for (index, id) in active.enumerated() {
            guard let point = touchesById[id] else { continue }
            let color = colors[index % colors.count]
            let isWinner = id == winnerID
            let radius: CGFloat = isWinner ? 45 : 33
            let glow = CGRect(x: point.x - radius - 12, y: point.y - radius - 12, width: (radius + 12) * 2, height: (radius + 12) * 2)
            context.setShadow(offset: .zero, blur: isWinner ? 20 : 12, color: color.withAlphaComponent(0.65).cgColor)
            context.setFillColor(color.withAlphaComponent(isWinner ? 0.98 : 0.78).cgColor)
            context.fillEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
            context.setShadow(offset: .zero, blur: 0, color: UIColor.clear.cgColor)
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.80).cgColor)
            context.setLineWidth(isWinner ? 3 : 2)
            context.strokeEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
            context.setFillColor(UIColor.white.cgColor)
            let label = "\(index + 1)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: isWinner ? 23 : 19, weight: .black), .foregroundColor: UIColor.white]
            let size = label.size(withAttributes: attributes)
            label.draw(at: CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2), withAttributes: attributes)
            if isWinner {
                let star = UIImage(systemName: "sparkle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                star?.draw(in: CGRect(x: glow.midX - 11, y: glow.minY - 8, width: 22, height: 22))
            }
        }
    }

    private func drawTargets(in rect: CGRect, context: CGContext) {
        let positions: [CGPoint] = [
            CGPoint(x: rect.width * 0.24, y: rect.height * 0.35),
            CGPoint(x: rect.width * 0.76, y: rect.height * 0.35),
            CGPoint(x: rect.width * 0.24, y: rect.height * 0.68),
            CGPoint(x: rect.width * 0.76, y: rect.height * 0.68)
        ]
        for (index, point) in positions.enumerated() {
            let color = colors[index]
            let radius: CGFloat = 26
            context.setFillColor(color.withAlphaComponent(0.10).cgColor)
            context.fillEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
            context.setStrokeColor(color.withAlphaComponent(0.78).cgColor)
            context.setLineWidth(2)
            context.strokeEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
            let number = "\(index + 1)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: .black), .foregroundColor: UIColor.white.withAlphaComponent(0.9)]
            let size = number.size(withAttributes: attributes)
            number.draw(at: CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2), withAttributes: attributes)
        }

        let instruction = "TOQUE E SEGURE" as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.43)]
        let size = instruction.size(withAttributes: attributes)
        instruction.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.height - 29), withAttributes: attributes)
    }
}

#Preview {
    NavigationStack { FingerPickerView() }
}
