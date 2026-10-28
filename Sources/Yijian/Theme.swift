import SwiftUI

// Select the stable property wrapper, also available in Command Line Tools SDKs
// that declare the newer State macro but do not ship its compiler plugin.
typealias ViewState<Value> = SwiftUI.State<Value>

enum Theme {
    static let background = Color(hex: 0xF6F5F0)
    static let paper = Color(hex: 0xFFFEFA)
    static let ink = Color(hex: 0x243A32)
    static let muted = Color(hex: 0x667068)
    static let accent = Color(hex: 0x376B51)
    static let pale = Color(hex: 0xE7EDE3)
    static let border = Color(hex: 0xDADFD5)
    static let gold = Color(hex: 0xB88333)
    static let wood = Color(hex: 0xEED9B1)
}
extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1) }
}
struct SoftButton: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 16).padding(.vertical, 11)
            .foregroundStyle(prominent ? Color.white : Theme.ink)
            .background(prominent ? Theme.accent : Theme.pale, in: RoundedRectangle(cornerRadius: 9))
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(Theme.paper, in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(Theme.border, lineWidth: 1)) }
}
struct Eyebrow: View {
    let text: String
    var body: some View { Text(text).font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(2).foregroundStyle(Theme.muted) }
}
struct SmallIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 14, weight: .medium)).frame(width: 36, height: 34).contentShape(Rectangle()) }
            .buttonStyle(.plain).foregroundStyle(Theme.ink).background(Theme.pale, in: RoundedRectangle(cornerRadius: 8)).help(label).accessibilityLabel(label)
    }
}
