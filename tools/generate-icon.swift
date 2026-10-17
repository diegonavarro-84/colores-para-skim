import AppKit

// Original vector artwork. Run from the repository root with `swift tools/generate-icon.swift`.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("resources")
let iconset = resources.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255)/255,
            green: CGFloat((hex >> 8) & 255)/255, blue: CGFloat(hex & 255)/255, alpha: 1)
}
func rounded(_ rect: NSRect, _ radius: CGFloat, _ fill: UInt32) {
    color(fill).setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
func drawIcon() {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    shadow.set()
    let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 184, yRadius: 184)
    NSGradient(starting: color(0xFFF2BB), ending: color(0xE2BB72))!.draw(in: tile, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // A page, its folded corner, and quiet typeset lines echo Skim's reading purpose.
    rounded(NSRect(x: 233, y: 201, width: 558, height: 644), 42, 0xBC945A)
    rounded(NSRect(x: 225, y: 215, width: 558, height: 644), 42, 0xFFF9E8)
    let fold = NSBezierPath()
    fold.move(to: NSPoint(x: 655, y: 859))
    fold.line(to: NSPoint(x: 783, y: 731))
    fold.line(to: NSPoint(x: 683, y: 731))
    fold.curve(to: NSPoint(x: 655, y: 759), controlPoint1: NSPoint(x: 665, y: 731), controlPoint2: NSPoint(x: 655, y: 741))
    fold.close()
    color(0xE9D9B4).setFill(); fold.fill()
    rounded(NSRect(x: 283, y: 741, width: 216, height: 49), 11, 0xD2B77D)
    for (y, width) in [(680.0, 300.0), (630.0, 382.0), (580.0, 340.0)] {
        rounded(NSRect(x: 283, y: y, width: width, height: 15), 7.5, 0xDAD1BB)
    }

    // Dark reading glasses, drawn as a single recognizable silhouette.
    let glasses = NSBezierPath()
    glasses.lineWidth = 21; glasses.lineCapStyle = .round; glasses.lineJoinStyle = .round
    glasses.appendRoundedRect(NSRect(x: 285, y: 429, width: 145, height: 104), xRadius: 39, yRadius: 39)
    glasses.appendRoundedRect(NSRect(x: 477, y: 429, width: 145, height: 104), xRadius: 39, yRadius: 39)
    glasses.move(to: NSPoint(x: 430, y: 491))
    glasses.curve(to: NSPoint(x: 477, y: 491), controlPoint1: NSPoint(x: 444, y: 509), controlPoint2: NSPoint(x: 463, y: 509))
    glasses.move(to: NSPoint(x: 285, y: 499)); glasses.line(to: NSPoint(x: 262, y: 521))
    glasses.move(to: NSPoint(x: 622, y: 499)); glasses.line(to: NSPoint(x: 645, y: 521))
    color(0x343C3B).setStroke(); glasses.stroke()

    // Color swatches distinguish this selector from the official PDF reader.
    NSGraphicsContext.saveGraphicsState()
    let paletteShadow = NSShadow()
    paletteShadow.shadowColor = NSColor.black.withAlphaComponent(0.17)
    paletteShadow.shadowBlurRadius = 16; paletteShadow.shadowOffset = NSSize(width: 0, height: -8)
    paletteShadow.set()
    rounded(NSRect(x: 275, y: 170, width: 590, height: 196), 70, 0xFFFFFF)
    NSGraphicsContext.restoreGraphicsState()
    for (index, hex) in [UInt32(0xF4EEDC), 0xE2EBE6, 0xDDE5EA, 0xEAE6EE, 0x404746].enumerated() {
        let circle = NSBezierPath(ovalIn: NSRect(x: 307 + index * 108, y: 225, width: 88, height: 88))
        color(hex).setFill(); circle.fill()
        color(0xC2C8C2).withAlphaComponent(0.6).setStroke()
        circle.lineWidth = 2; circle.stroke()
    }
}

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        let transform = NSAffineTransform(); transform.scale(by: CGFloat(pixels)/1024); transform.concat()
        drawIcon()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        let data = rep.representation(using: .png, properties: [:])!
        try data.write(to: iconset.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
        if pixels == 1024 { try data.write(to: resources.appendingPathComponent("AppIcon.png")) }
    }
}
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path]
try process.run(); process.waitUntilExit()
guard process.terminationStatus == 0 else { fatalError("No se pudo crear AppIcon.icns") }
try FileManager.default.removeItem(at: iconset)
