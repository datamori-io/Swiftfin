// Generates the Datamori tvOS app icon layers and Top Shelf images.
// usage: swift make-icons.swift <logo.png> <brandassets dir>
import AppKit
import CoreGraphics
import Foundation

let args = CommandLine.arguments
let logoURL = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])

guard let src = CGImageSourceCreateWithURL(logoURL as CFURL, nil),
      let logo = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("logo") }

let ink = CGColor(srgbRed: 14 / 255, green: 14 / 255, blue: 15 / 255, alpha: 1)
let red = CGColor(srgbRed: 216 / 255, green: 88 / 255, blue: 96 / 255, alpha: 1)

func context(_ w: Int, _ h: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    // flip so y grows downward like the app's Canvas
    ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func save(_ ctx: CGContext, _ rel: String) {
    let img = ctx.makeImage()!
    let url = outDir.appendingPathComponent(rel)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("wrote", rel, img.width, "x", img.height)
}

// Same pattern as DatamoriBackground.swift (contours + network), scaled.
func drawBackground(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat, network: Bool = true) {
    ctx.setFillColor(ink); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    let unit = min(w, h)
    let line = max(1, unit / 400)
    ctx.setLineWidth(line)
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.06))
    let clusters: [(CGPoint, Int, Double)] = [
        (CGPoint(x: w * 0.82, y: h * 0.22), 14, 0.0),
        (CGPoint(x: w * 0.12, y: h * 0.95), 11, 1.7),
    ]
    for (c, rings, phase) in clusters {
        for ring in 1 ... rings {
            let base = unit * 0.07 * Double(ring)
            for step in 0 ... 180 {
                let t = Double(step) / 180 * 2 * .pi
                let wob = 1 + 0.10 * sin(3 * t + phase + Double(ring) * 0.35) + 0.05 * sin(5 * t - phase * 1.3 - Double(ring) * 0.2)
                let p = CGPoint(x: c.x + base * wob * cos(t) * 1.35, y: c.y + base * wob * sin(t))
                if step == 0 { ctx.move(to: p) } else { ctx.addLine(to: p) }
            }
            ctx.closePath(); ctx.strokePath()
        }
    }
    guard network else { return }
    let nodes: [CGPoint] = [(0.06, 0.30), (0.18, 0.18), (0.30, 0.34), (0.47, 0.12), (0.62, 0.28), (0.74, 0.10),
                            (0.90, 0.40), (0.56, 0.62), (0.38, 0.78), (0.80, 0.80), (0.22, 0.60), (0.96, 0.66)]
        .map { CGPoint(x: $0.0 * w, y: $0.1 * h) }
    let edges = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (4, 6), (4, 7), (7, 8), (7, 9), (9, 11), (6, 11), (2, 10), (10, 8)]
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.06))
    for (a, b) in edges { ctx.move(to: nodes[a]); ctx.addLine(to: nodes[b]) }
    ctx.strokePath()
    for (i, n) in nodes.enumerated() {
        let isRed = [2, 7, 11].contains(i)
        let r = (isRed ? 1.6 : 1.0) * line * 2.5
        ctx.setFillColor(isRed ? red.copy(alpha: 0.6)! : CGColor(gray: 1, alpha: 0.1))
        ctx.fillEllipse(in: CGRect(x: n.x - r, y: n.y - r, width: r * 2, height: r * 2))
    }
}

/// Draws the logo centred, fitted to `fraction` of the given box.
func drawLogo(_ ctx: CGContext, in box: CGRect, fraction: CGFloat) {
    let aspect = CGFloat(logo.width) / CGFloat(logo.height)
    var lw = box.width * fraction, lh = lw / aspect
    if lh > box.height * fraction { lh = box.height * fraction; lw = lh * aspect }
    let rect = CGRect(x: box.midX - lw / 2, y: box.midY - lh / 2, width: lw, height: lh)
    // undo flip for the image so it isn't drawn upside down
    ctx.saveGState()
    ctx.translateBy(x: 0, y: rect.minY + rect.maxY); ctx.scaleBy(x: 1, y: -1)
    ctx.draw(logo, in: rect)
    ctx.restoreGState()
}

let base = "App Icon.imagestack"
let store = "App Icon - App Store.imagestack"

// Back layers (full canvas, ink + pattern, no logo)
for (w, h, rel) in [(400, 240, "\(base)/Back.imagestacklayer/Content.imageset/back.png"),
                    (800, 480, "\(base)/Back.imagestacklayer/Content.imageset/back@2x.png"),
                    (1280, 768, "\(store)/Back.imagestacklayer/Content.imageset/1280x768-back.png")] {
    let ctx = context(w, h); drawBackground(ctx, CGFloat(w), CGFloat(h)); save(ctx, rel)
}

// Front layers (transparent square, logo centred)
for (s, rel) in [(216, "\(base)/Front.imagestacklayer/Content.imageset/front.png"),
                 (432, "\(base)/Front.imagestacklayer/Content.imageset/front@2x.png"),
                 (512, "\(store)/Front.imagestacklayer/Content.imageset/512.png")] {
    let ctx = context(s, s); drawLogo(ctx, in: CGRect(x: 0, y: 0, width: s, height: s), fraction: 0.82); save(ctx, rel)
}

// Top Shelf (ink + pattern + small mark at left-centre)
for (w, h, rel) in [(1920, 720, "Top Shelf Image.imageset/top shelf.png"),
                    (3840, 1440, "Top Shelf Image.imageset/Untitled-1.png"),
                    (1920, 720, "Top Shelf Image.imageset/top shelf-1.png"),
                    (3840, 1440, "Top Shelf Image.imageset/Untitled-2.png"),
                    (2320, 720, "Top Shelf Image Wide.imageset/top shelf.png"),
                    (4640, 1440, "Top Shelf Image Wide.imageset/Untitled-1.png"),
                    (2320, 720, "Top Shelf Image Wide.imageset/top shelf-1.png"),
                    (4640, 1440, "Top Shelf Image Wide.imageset/Untitled-2.png")] {
    let ctx = context(w, h)
    drawBackground(ctx, CGFloat(w), CGFloat(h))
    let box = CGFloat(h) * 0.42
    drawLogo(ctx, in: CGRect(x: CGFloat(w) / 2 - box / 2, y: CGFloat(h) / 2 - box / 2, width: box, height: box), fraction: 1)
    save(ctx, rel)
}
