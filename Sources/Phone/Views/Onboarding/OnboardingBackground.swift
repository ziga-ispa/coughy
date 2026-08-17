import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let brand = Color(hex: "FFD2D7")
    static let deepNavy = Color(hex: "003451")
}

struct OnboardingBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OnboardingNextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brand)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 32)
    }
}

struct OnboardingSkipButton: View {
    let action: () -> Void

    var body: some View {
        Button("Skip for Now", action: action)
            .font(.system(size: 15))
            .foregroundColor(.white)
    }
}
