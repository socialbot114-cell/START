import SwiftUI
import UIKit

struct FingerPickerView: View {
    @State private var winnerIndex: Int? = nil
    @State private var touchCount: Int = 0
    @State private var status: String = "Coloquem seus dedos na tela..."

    var body: some View {
        VStack(spacing: 16) {
            Text("Todos colocam o dedo na tela. O START escolhe alguém de forma visual e divertida.")
                .font(.subheadline)
                .foregroundColor(Theme.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)

            ZStack {
                MultiTouchView(winnerIndex: $winnerIndex, touchCount: $touchCount, status: $status)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .accessibilityIdentifier("finger-area")

                VStack(spacing: 8) {
                    Text(status)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("finger-result")
                    if touchCount > 0 {
                        Text("\(touchCount) dedo(s) na tela")
                            .font(.caption)
                            .foregroundColor(Theme.mutedText)
                    }
                }
                .padding()
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 380)

            Button("Reiniciar") {
                winnerIndex = nil
                touchCount = 0
                status = "Coloquem seus dedos na tela..."
            }
            .startPrimaryButton()
            .padding(.horizontal, 16)
            .accessibilityIdentifier("finger-reset")

            Spacer()
        }
        .padding(.top, 12)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Dedos na Tela")
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
                self.touchCount = count
                self.winnerIndex = winner
                self.status = message
            }
        }
        return view
    }

    func updateUIView(_ uiView: TouchCanvas, context: Context) {
        if winnerIndex == nil && touchCount == 0 {
            uiView.reset()
        }
    }
}

final class TouchCanvas: UIView {
    var onUpdate: ((Int, Int?, String) -> Void)?

    private var touchesById: [Int: CGPoint] = [:]
    private var lockTimer: Timer?
    private var winner: Int? = nil
    private let colors: [UIColor] = [.systemGreen, .systemBlue, .systemRed, .systemPurple, .systemOrange, .systemTeal, .systemPink, .systemYellow]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isMultipleTouchEnabled = true
    }

    func reset() {
        touchesById.removeAll()
        winner = nil
        lockTimer?.invalidate()
        lockTimer = nil
        setNeedsDisplay()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchesById[t.hash] = t.location(in: self)
        }
        evaluate()
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchesById[t.hash] = t.location(in: self)
        }
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchesById.removeValue(forKey: t.hash)
        }
        if touchesById.count < 2 {
            lockTimer?.invalidate()
            lockTimer = nil
            winner = nil
        }
        evaluateDisplayOnly()
        setNeedsDisplay()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func evaluate() {
        let count = touchesById.count
        guard count >= 2 else {
            onUpdate?(count, nil, count == 0 ? "Coloquem seus dedos na tela..." : "Chame mais gente: precisa de ao menos 2 dedos.")
            return
        }
        lockTimer?.invalidate()
        onUpdate?(count, nil, "Segurem... escolhendo em 3, 2, 1")
        lockTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self else { return }
            let keys = Array(self.touchesById.keys)
            let pick = keys.randomElement()
            let idx = keys.firstIndex(of: pick!) ?? 0
            self.winner = idx
            self.onUpdate?(self.touchesById.count, idx, "Dedo \(idx + 1) começa! 🎉")
            self.setNeedsDisplay()
        }
    }

    private func evaluateDisplayOnly() {
        if touchesById.isEmpty {
            onUpdate?(0, nil, "Coloquem seus dedos na tela...")
        }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let keys = Array(touchesById.keys)
        for (i, key) in keys.enumerated() {
            let p = touchesById[key] ?? CGPoint(x: rect.midX, y: rect.midY)
            let isWin = (winner == i)
            let radius: CGFloat = isWin ? 52 : 34
            let color = colors[i % colors.count]
            ctx.setFillColor(color.withAlphaComponent(isWin ? 0.95 : 0.75).cgColor)
            ctx.addArc(center: p, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.fillPath()
            ctx.setFillColor(UIColor.white.cgColor)
            let label = "\(i + 1)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: UIColor.white]
            let size = label.size(withAttributes: attrs)
            label.draw(at: CGPoint(x: p.x - size.width / 2, y: p.y - size.height / 2), withAttributes: attrs)
        }
    }
}

#Preview {
    NavigationStack { FingerPickerView() }
}
