import SwiftUI

enum Theme {
    static let background = Color(red: 0.055, green: 0.043, blue: 0.035)
    static let card = Color(red: 0.055, green: 0.075, blue: 0.065)
    static let cardRaised = Color(red: 0.105, green: 0.145, blue: 0.12)
    static let cardBorder = Color.white.opacity(0.13)
    static let accent = Color(red: 1.0, green: 0.72, blue: 0.16)
    static let accentLight = Color(red: 1.0, green: 0.84, blue: 0.36)
    static let accentText = Color(red: 0.14, green: 0.075, blue: 0.015)
    static let green = Color(red: 0.12, green: 0.46, blue: 0.29)
    static let greenLight = Color(red: 0.28, green: 0.84, blue: 0.48)
    static let mutedText = Color.white.opacity(0.68)
    static let cornerRadius: CGFloat = 20
}

struct StartCardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card.opacity(0.90))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: .black.opacity(0.22), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func startCard(padding: CGFloat = 16) -> some View {
        modifier(StartCardStyle(padding: padding))
    }

    func startPrimaryButton() -> some View {
        self
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundColor(Theme.accentText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [Theme.accentLight, Theme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.24), lineWidth: 1))
            .shadow(color: Theme.accent.opacity(0.20), radius: 14, x: 0, y: 6)
    }
}

struct TableBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.25, green: 0.115, blue: 0.055),
                        Color(red: 0.13, green: 0.065, blue: 0.035),
                        Color(red: 0.20, green: 0.09, blue: 0.038)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Canvas { context, size in
                    let plankHeight: CGFloat = 82
                    for row in 0...(Int(size.height / plankHeight) + 1) {
                        let y = CGFloat(row) * plankHeight
                        var seam = Path()
                        seam.move(to: CGPoint(x: 0, y: y))
                        seam.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(seam, with: .color(Color(red: 0.035, green: 0.018, blue: 0.009).opacity(0.72)), lineWidth: 2)

                        let offset = row.isMultiple(of: 2) ? size.width * 0.31 : size.width * 0.68
                        var joint = Path()
                        joint.move(to: CGPoint(x: offset, y: y))
                        joint.addLine(to: CGPoint(x: offset, y: y + plankHeight))
                        context.stroke(joint, with: .color(Theme.accent.opacity(0.07)), lineWidth: 1)

                        for grain in 0..<5 {
                            let startX = CGFloat((row * 97 + grain * 151) % 820) / 820 * size.width
                            let length = CGFloat(90 + ((row * 31 + grain * 67) % 220))
                            let grainY = y + CGFloat(12 + grain * 13)
                            var line = Path()
                            line.move(to: CGPoint(x: startX, y: grainY))
                            line.addCurve(
                                to: CGPoint(x: min(size.width, startX + length), y: grainY + CGFloat((grain % 2 == 0) ? 2 : -2)),
                                control1: CGPoint(x: startX + length * 0.28, y: grainY - 3),
                                control2: CGPoint(x: startX + length * 0.7, y: grainY + 3)
                            )
                            context.stroke(line, with: .color(Theme.accentLight.opacity(0.045)), lineWidth: 1)
                        }
                    }
                }

                RadialGradient(
                    colors: [.clear, .black.opacity(0.76)],
                    center: .center,
                    startRadius: proxy.size.width * 0.18,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.76
                )

                LinearGradient(colors: [.black.opacity(0.22), .clear, .black.opacity(0.36)], startPoint: .top, endPoint: .bottom)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .ignoresSafeArea()
        }
        .accessibilityHidden(true)
    }
}
