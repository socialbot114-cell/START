import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    fputs("Usage: make_contact_sheet.swift <screenshots-dir> <output.png>\n", stderr)
    exit(2)
}

let inputDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: arguments[2])
let files = (try? FileManager.default.contentsOfDirectory(at: inputDirectory, includingPropertiesForKeys: nil)) ?? []
let images = files
    .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
    .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
guard !images.isEmpty else {
    fputs("No screenshot images found in \(inputDirectory.path)\n", stderr)
    exit(1)
}

let columns = min(3, images.count)
let rows = Int(ceil(Double(images.count) / Double(columns)))
let thumbnailWidth: CGFloat = 270
let thumbnailHeight: CGFloat = 586
let labelHeight: CGFloat = 32
let gap: CGFloat = 22
let padding: CGFloat = 26
let cellHeight = thumbnailHeight + labelHeight
let canvasWidth = padding * 2 + CGFloat(columns) * thumbnailWidth + CGFloat(columns - 1) * gap
let canvasHeight = padding * 2 + CGFloat(rows) * cellHeight + CGFloat(rows - 1) * gap

let canvas = NSImage(size: NSSize(width: canvasWidth, height: canvasHeight))
canvas.lockFocus()
NSColor(calibratedRed: 0.075, green: 0.045, blue: 0.025, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)).fill()

let title = "START  ·  MVP iOS"
(title as NSString).draw(
    at: NSPoint(x: padding, y: canvasHeight - padding - 23),
    withAttributes: [
        .font: NSFont.systemFont(ofSize: 17, weight: .heavy),
        .foregroundColor: NSColor(calibratedRed: 1, green: 0.75, blue: 0.26, alpha: 1)
    ]
)

let titleBand: CGFloat = 42
for (index, file) in images.enumerated() {
    guard let image = NSImage(contentsOf: file) else { continue }
    let column = index % columns
    let row = index / columns
    let x = padding + CGFloat(column) * (thumbnailWidth + gap)
    let y = canvasHeight - padding - titleBand - CGFloat(row + 1) * cellHeight - CGFloat(row) * gap

    let label = file.deletingPathExtension().lastPathComponent
        .replacingOccurrences(of: "01-", with: "")
        .replacingOccurrences(of: "02-", with: "")
        .replacingOccurrences(of: "03-", with: "")
        .replacingOccurrences(of: "04-", with: "")
        .replacingOccurrences(of: "05-", with: "")
        .replacingOccurrences(of: "01_", with: "")
        .replacingOccurrences(of: "02_", with: "")
        .replacingOccurrences(of: "03_", with: "")
        .replacingOccurrences(of: "04_", with: "")
        .replacingOccurrences(of: "05_", with: "")
        .replacingOccurrences(of: "-", with: " ")
        .uppercased()
    (label as NSString).draw(
        at: NSPoint(x: x, y: y + thumbnailHeight + 8),
        withAttributes: [
            .font: NSFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.88)
        ]
    )

    let target = NSRect(x: x, y: y, width: thumbnailWidth, height: thumbnailHeight)
    NSColor(calibratedWhite: 0.10, alpha: 1).setFill()
    NSBezierPath(roundedRect: target.insetBy(dx: -1, dy: -1), xRadius: 11, yRadius: 11).fill()
    image.draw(in: target, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    NSColor(calibratedRed: 1, green: 0.70, blue: 0.19, alpha: 0.55).setStroke()
    let border = NSBezierPath(roundedRect: target, xRadius: 10, yRadius: 10)
    border.lineWidth = 1
    border.stroke()
}

canvas.unlockFocus()
guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not render contact sheet\n", stderr)
    exit(1)
}
try png.write(to: outputURL, options: .atomic)
print("Wrote \(outputURL.path) (\(images.count) screens)")
