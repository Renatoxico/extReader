import SwiftUI

enum Noturno {
    static let emerald = Color(hex: 0x10B981)
    static let mint = Color(hex: 0x6EE7B7)
    static let amber = Color(hex: 0xE3B25B)
    static let surface = Color(hex: 0x111312)
    static let surface2 = Color(hex: 0x1A1C1B)
    static let text = Color(hex: 0xF5F5F5)
    static let secondary = Color(hex: 0x8E8E93)
    static let tertiary = Color(hex: 0x5C5C61)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.85)
    static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "BRL").locale(Locale(identifier: "pt_BR")))
    }
    static func date(_ date: Date, _ format: String = "dd MMM") -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "pt_BR"); f.timeZone = NightDates.calendar.timeZone; f.dateFormat = format
        return f.string(from: date).replacingOccurrences(of: ".", with: "")
    }

}
extension Color {
    init(hex: UInt) { self.init(red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255, blue: Double(hex & 255)/255) }
}
struct NoturnoBackground: View {
    var tint: Color = Noturno.emerald
    var top = false
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                RadialGradient(colors: [tint.opacity(top ? 0.3 : 0.16), .clear], center: top ? .top : .bottom, startRadius: 0, endRadius: proxy.size.height * 0.65)
            }
        }.ignoresSafeArea()
    }
}
struct NoturnoPress: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(reduceMotion ? nil : Noturno.spring, value: configuration.isPressed)
    }
}
extension View {
    func nightCard() -> some View {
        padding(16).background(Noturno.surface, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.07), lineWidth: 0.5))
    }
    func moneyFont(_ size: CGFloat = 17) -> some View {
        modifier(NightMoneyFont(size: size))
    }
}
struct NightTile: View {
    let category: String
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 36
    private var color: Color { .forCategory(category) }
    var body: some View {
        Image(systemName: .iconName(forCategory: category))
            .font(.body.weight(.semibold)).foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 11))
            .accessibilityHidden(true)
    }
}
struct NightStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(Noturno.secondary)
            Text(value).moneyFont(16)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(Noturno.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct NightMoneyFont: ViewModifier {
    let size: CGFloat
    @ScaledMetric(relativeTo: .title) private var scale: CGFloat = 1
    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: .heavy, design: .rounded)).minimumScaleFactor(0.65)
    }
}

extension View {
    @ViewBuilder func nightZoomSource(id: String, namespace: Namespace.ID) -> some View {
        if #available(iOS 18, *) { matchedTransitionSource(id: id, in: namespace) }
        else { self }
    }
    func nightZoom(id: String, namespace: Namespace.ID) -> some View { modifier(NightZoom(id: id, namespace: namespace)) }
}
private struct NightZoom: ViewModifier {
    let id: String
    let namespace: Namespace.ID
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18, *), !reduceMotion { content.navigationTransition(.zoom(sourceID: id, in: namespace)) }
        else { content }
    }
}
