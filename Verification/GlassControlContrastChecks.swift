import Foundation

let bg = GlassControlPalette.fieldBackground
let text = GlassControlPalette.fieldText
let hint = GlassControlPalette.fieldPlaceholder
let ratioText = bg.contrastRatio(against: text)
let ratioHint = bg.contrastRatio(against: hint)
precondition(ratioText >= 7, "Search text contrast insufficient")
precondition(ratioHint >= 4.5, "Search placeholder contrast insufficient")
print(String(format: "PASS search-field contrast: text %.2f:1, placeholder %.2f:1", ratioText, ratioHint))
