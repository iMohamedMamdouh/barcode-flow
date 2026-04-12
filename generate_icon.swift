import Cocoa

let logoPath = "assets/image /logo_white.png"
let outputPath = "assets/images/app_icon.png"
let iconSize = 1024
let bgColor = NSColor(red: 27.0/255.0, green: 94.0/255.0, blue: 32.0/255.0, alpha: 1.0)

guard let logoImage = NSImage(contentsOfFile: logoPath) else {
    print("ERROR: Cannot load logo from \(logoPath)")
    exit(1)
}

let size = NSSize(width: iconSize, height: iconSize)
let icon = NSImage(size: size)

icon.lockFocus()

bgColor.setFill()
NSRect(origin: .zero, size: size).fill()

let logoOrigW = logoImage.size.width
let logoOrigH = logoImage.size.height
let aspect = logoOrigW / logoOrigH

let padding = CGFloat(iconSize) * 0.15
let maxW = CGFloat(iconSize) - padding * 2
let maxH = CGFloat(iconSize) - padding * 2

let drawW: CGFloat
let drawH: CGFloat
if aspect > 1 {
    drawW = maxW
    drawH = maxW / aspect
} else {
    drawH = maxH
    drawW = maxH * aspect
}

let x = (CGFloat(iconSize) - drawW) / 2.0
let y = (CGFloat(iconSize) - drawH) / 2.0

logoImage.draw(
    in: NSRect(x: x, y: y, width: drawW, height: drawH),
    from: .zero,
    operation: .sourceOver,
    fraction: 1.0
)

icon.unlockFocus()

guard let tiffData = icon.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("ERROR: Cannot generate PNG")
    exit(1)
}

let url = URL(fileURLWithPath: outputPath)
try! pngData.write(to: url)
print("App icon generated: \(outputPath) (\(pngData.count) bytes)")
