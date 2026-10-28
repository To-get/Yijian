import AppKit
import Foundation

// Original, reproducible artwork. Coordinates use a 1024-point canvas.
func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}

func shadow(_ blur: CGFloat, y: CGFloat, opacity: CGFloat, draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(opacity)
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = NSSize(width: 0, height: y)
    shadow.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func drawIcon(pixels: Int) {
    let tile = NSBezierPath(roundedRect: NSRect(x: 60, y: 60, width: 904, height: 904), xRadius: 204, yRadius: 204)
    shadow(18, y: -8, opacity: 0.2) { color(0x173B33).setFill(); tile.fill() }
    NSGradient(starting: color(0x426F5C), ending: color(0x112F29))!.draw(in: tile, angle: -70)
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    if pixels >= 64 {
        let grid = NSBezierPath()
        grid.lineWidth = 5
        for offset in 0...4 {
            let p = 230 + CGFloat(offset) * 141
            grid.move(to: NSPoint(x: p, y: 230)); grid.line(to: NSPoint(x: p, y: 794))
            grid.move(to: NSPoint(x: 230, y: p)); grid.line(to: NSPoint(x: 794, y: p))
        }
        color(0xD9C891, alpha: 0.2).setStroke(); grid.stroke()
        for (x, y) in [(230,794),(794,794),(230,230),(794,230)] {
            color(0xD9C891, alpha: 0.45).setFill()
            NSBezierPath(ovalIn: NSRect(x: x - 7, y: y - 7, width: 14, height: 14)).fill()
        }
    }
    NSGraphicsContext.restoreGraphicsState()

    // The ivory knight gives the silhouette its identity, even at Dock size.
    let knight = NSBezierPath()
    knight.move(to: NSPoint(x: 349, y: 727))
    knight.line(to: NSPoint(x: 416, y: 842))
    knight.curve(to: NSPoint(x: 455, y: 753), controlPoint1: NSPoint(x: 438, y: 835), controlPoint2: NSPoint(x: 452, y: 784))
    knight.curve(to: NSPoint(x: 623, y: 637), controlPoint1: NSPoint(x: 540, y: 755), controlPoint2: NSPoint(x: 602, y: 721))
    knight.curve(to: NSPoint(x: 702, y: 378), controlPoint1: NSPoint(x: 652, y: 534), controlPoint2: NSPoint(x: 637, y: 466))
    knight.line(to: NSPoint(x: 697, y: 329))
    knight.line(to: NSPoint(x: 365, y: 329))
    knight.curve(to: NSPoint(x: 456, y: 508), controlPoint1: NSPoint(x: 372, y: 424), controlPoint2: NSPoint(x: 452, y: 443))
    knight.line(to: NSPoint(x: 435, y: 546))
    knight.line(to: NSPoint(x: 379, y: 510))
    knight.curve(to: NSPoint(x: 307, y: 531), controlPoint1: NSPoint(x: 354, y: 493), controlPoint2: NSPoint(x: 320, y: 504))
    knight.line(to: NSPoint(x: 282, y: 578))
    knight.curve(to: NSPoint(x: 310, y: 646), controlPoint1: NSPoint(x: 269, y: 604), controlPoint2: NSPoint(x: 286, y: 625))
    knight.line(to: NSPoint(x: 371, y: 707))
    knight.close()
    shadow(22, y: -13, opacity: 0.3) {
        NSGradient(starting: color(0xFFF9E6), ending: color(0xD9CBA5))!.draw(in: knight, angle: -65)
    }
    if pixels >= 32 {
        let mane = NSBezierPath(); mane.lineWidth = 10; mane.lineCapStyle = .round
        mane.move(to: NSPoint(x: 486, y: 707))
        mane.curve(to: NSPoint(x: 592, y: 396), controlPoint1: NSPoint(x: 604, y: 674), controlPoint2: NSPoint(x: 557, y: 500))
        color(0xB5A073, alpha: 0.7).setStroke(); mane.stroke()
        color(0x244D40).setFill()
        NSBezierPath(ovalIn: NSRect(x: 386, y: 671, width: 23, height: 23)).fill()
    }
    let base = NSBezierPath(roundedRect: NSRect(x: 338, y: 271, width: 385, height: 65), xRadius: 22, yRadius: 22)
    shadow(12, y: -7, opacity: 0.25) { color(0xE6D7B2).setFill(); base.fill() }

    // Xiangqi seal and Go stone complete the three-game emblem.
    let sealRect = NSRect(x: 202, y: 194, width: 248, height: 248)
    let seal = NSBezierPath(ovalIn: sealRect)
    shadow(17, y: -11, opacity: 0.35) {
        NSGradient(starting: color(0xCC7157), ending: color(0x922E29))!.draw(in: seal, angle: -80)
    }
    color(0xF3D4A0).setStroke()
    let ring = NSBezierPath(ovalIn: sealRect.insetBy(dx: 19, dy: 19)); ring.lineWidth = 7; ring.stroke()
    if pixels >= 64 {
        let text = "将" as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 129, weight: .medium), .foregroundColor: color(0xFFF0CD)]
        let size = text.size(withAttributes: attributes)
        text.draw(at: NSPoint(x: sealRect.midX - size.width / 2, y: sealRect.midY - size.height / 2 + 3), withAttributes: attributes)
    }
    let stone = NSBezierPath(ovalIn: NSRect(x: 606, y: 189, width: 248, height: 248))
    shadow(20, y: -12, opacity: 0.4) {
        NSGradient(starting: color(0x5A665D), ending: color(0x101A16))!.draw(in: stone, angle: -70)
    }
    color(0xC2C4A6, alpha: 0.25).setStroke(); stone.lineWidth = 3; stone.stroke()
    color(0xFFFFFF, alpha: 0.08).setFill()
    NSBezierPath(ovalIn: NSRect(x: 653, y: 341, width: 100, height: 38)).fill()
    color(0xE6E1C4, alpha: 0.13).setStroke(); tile.lineWidth = 3; tile.stroke()
}

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for (points, scale) in [(16,1),(16,2),(32,1),(32,2),(128,1),(128,2),(256,1),(256,2),(512,1),(512,2)] {
    let pixels = points * scale
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current!.imageInterpolation = .high
    NSGraphicsContext.current!.cgContext.scaleBy(x: Double(pixels) / 1024, y: Double(pixels) / 1024)
    drawIcon(pixels: pixels)
    NSGraphicsContext.restoreGraphicsState()
    let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
    try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
}
