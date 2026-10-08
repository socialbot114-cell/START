import SwiftUI

enum Theme {
    static let background = Color(red: 0.06, green: 0.10, blue: 0.08)
    static let card = Color(red: 0.11, green: 0.17, blue: 0.14)
    static let cardBorder = Color.white.opacity(0.08)
    static let accent = Color(red: 1.0, green: 0.77, blue: 0.19)
    static let accentText = Color(red: 0.12, green: 0.08, blue: 0.0)
    static let deepGreen = Color(red: 0.10, green: 0.35, blue: 0.25)
    static let brightGreen = Color(red: 0.20, green: 0.85, blue: 0.45)
    static let mutedText = Color.white.opacity(0.65)

    static let cornerRadius: CGFloat = 20
}

struct StartCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

extension View {
    func startCard() -> some View {
        modifier(StartCardStyle())
    }

    func startPrimaryButton() -> some View {
        self
            .font(.headline)
            .foregroundColor(Theme.accentText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
