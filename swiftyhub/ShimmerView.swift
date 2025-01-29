import SwiftUI

struct ShimmerView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 100)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(RoundedRectangle(cornerRadius: 10))
                .offset(x: -200)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: UUID())
            )
    }
}
