import SwiftUI

/// Docket's identity: a chalkboard-green/pencil-yellow classroom palette —
/// evokes a supply closet inventory sheet. Distinct from every sibling
/// app's colors (no sage/teal/terracotta reused).
enum DKTheme {
    static let backdrop = Color(red: 0.949, green: 0.945, blue: 0.925)   // paper-cream
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.906, green: 0.898, blue: 0.867)
    static let ink = Color(red: 0.129, green: 0.176, blue: 0.145)        // chalkboard-ink
    static let inkFaded = Color(red: 0.129, green: 0.176, blue: 0.145).opacity(0.55)
    static let rule = Color.black.opacity(0.08)

    static let chalkGreen = Color(red: 0.129, green: 0.318, blue: 0.235) // classic chalkboard-green
    static let chalkGreenBright = Color(red: 0.180, green: 0.408, blue: 0.298)
    static let pencilYellow = Color(red: 0.937, green: 0.769, blue: 0.239) // pencil-yellow accent
    static let danger = Color(red: 0.749, green: 0.278, blue: 0.220)
    static let success = Color(red: 0.129, green: 0.318, blue: 0.235)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
