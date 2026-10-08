import SwiftUI

struct StartPawn: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let head = CGRect(x: rect.midX - rect.width * 0.17, y: rect.minY + rect.height * 0.17, width: rect.width * 0.34, height: rect.height * 0.28)
        path.addEllipse(in: head)
        path.move(to: CGPoint(x: rect.midX - rect.width * 0.09, y: rect.minY + rect.height * 0.44))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.13, y: rect.minY + rect.height * 0.86))
        path.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.maxY), control: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - rect.width * 0.13, y: rect.minY + rect.height * 0.86), control: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.09, y: rect.minY + rect.height * 0.44))
        path.closeSubpath()
        return path
    }
}

struct StartLogo: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 1 : 2) {
            Text("ST")
            ZStack(alignment: .top) {
                StartPawn().fill(Theme.accent)
                    .frame(width: compact ? 25 : 38, height: compact ? 31 : 46)
                    .offset(y: compact ? 6 : 9)
                HStack(spacing: compact ? 4 : 5) {
                    Capsule().frame(width: 2, height: compact ? 7 : 9).rotationEffect(.degrees(-25))
                    Capsule().frame(width: 2, height: compact ? 9 : 12)
                    Capsule().frame(width: 2, height: compact ? 7 : 9).rotationEffect(.degrees(25))
                }
                .foregroundColor(Theme.accent)
            }
            .frame(width: compact ? 27 : 42, height: compact ? 42 : 58)
            Text("RT")
        }
        .font(.system(size: compact ? 29 : 44, weight: .black, design: .rounded))
        .tracking(compact ? -1.8 : -2.8)
        .foregroundColor(.white)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("START")
    }
}

struct AppScreenHeader: View {
    let title: String
    var back: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let back {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.accent)
                        .frame(width: 40, height: 40)
                        .background(.black.opacity(0.32), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                }
                .accessibilityLabel("Voltar")
            }
            StartLogo(compact: true)
            Spacer(minLength: 4)
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded, weight: .bold))
                .tracking(1.1)
                .foregroundColor(.white.opacity(0.90))
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
}
