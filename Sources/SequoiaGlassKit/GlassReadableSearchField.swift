import AppKit

/// Applies a predictable native search-field appearance independent of the
/// underlying wallpaper. This styles an APP-OWNED search field; it does not
/// change Finder or other applications. No capture or polling is used.
@MainActor
public enum GlassReadableSearchField {
    public static func apply(to field: NSSearchField, placeholder: String) {
        let p = GlassControlPalette.self
        let bg = p.fieldBackground
        let fg = p.fieldText
        let hint = p.fieldPlaceholder

        field.appearance = NSAppearance(named: .aqua)
        field.isBezeled = true
        field.drawsBackground = true
        field.backgroundColor = NSColor(
            calibratedRed: CGFloat(bg.red), green: CGFloat(bg.green), blue: CGFloat(bg.blue), alpha: 1)
        field.textColor = NSColor(
            calibratedRed: CGFloat(fg.red), green: CGFloat(fg.green), blue: CGFloat(fg.blue), alpha: 1)
        field.font = .systemFont(ofSize: 13)
        field.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor(
                    calibratedRed: CGFloat(hint.red), green: CGFloat(hint.green), blue: CGFloat(hint.blue), alpha: 1),
                .font: NSFont.systemFont(ofSize: 13)
            ])
    }
}
