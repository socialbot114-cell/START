import AVFoundation
import UIKit

@MainActor
enum GameFeedback {
    enum Cue: Hashable {
        case diceRoll
        case cardFlip
        case winner

        var duration: Double {
            switch self {
            case .diceRoll: return 0.72
            case .cardFlip: return 0.14
            case .winner: return 0.72
            }
        }

        var volume: Float {
            switch self {
            case .diceRoll: return 0.20
            case .cardFlip: return 0.16
            case .winner: return 0.24
            }
        }
    }

    static let preferenceKey = "start.effects.enabled"

    private static var activePlayers: [AVAudioPlayer] = []
    private static var cachedSounds: [Cue: Data] = [:]

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard effectsAreEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        guard effectsAreEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func play(_ cue: Cue) {
        guard effectsAreEnabled else { return }

        let data: Data
        if let cached = cachedSounds[cue] {
            data = cached
        } else {
            data = makeWave(for: cue)
            cachedSounds[cue] = data
        }

        guard let player = try? AVAudioPlayer(data: data) else { return }
        player.volume = cue.volume
        player.prepareToPlay()
        player.play()
        activePlayers.removeAll { !$0.isPlaying }
        activePlayers.append(player)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((cue.duration + 0.12) * 1_000_000_000))
            activePlayers.removeAll { $0 === player }
        }
    }

    private static var effectsAreEnabled: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        guard !arguments.contains("-ui-testing"), !arguments.contains("-screenshot-mode") else { return false }
        return UserDefaults.standard.object(forKey: preferenceKey) as? Bool ?? true
    }

    private static func makeWave(for cue: Cue) -> Data {
        let sampleRate: UInt32 = 24_000
        let sampleCount = Int(Double(sampleRate) * cue.duration)
        var samples = Data(capacity: sampleCount * MemoryLayout<Int16>.size)

        for index in 0..<sampleCount {
            let time = Double(index) / Double(sampleRate)
            let signal = sample(for: cue, at: time)
            let clipped = max(-1, min(1, signal))
            appendLittleEndian(Int16(clipped * Double(Int16.max)), to: &samples)
        }

        var wave = Data(capacity: 44 + samples.count)
        wave.append(contentsOf: "RIFF".utf8)
        appendLittleEndian(UInt32(36 + samples.count), to: &wave)
        wave.append(contentsOf: "WAVEfmt ".utf8)
        appendLittleEndian(UInt32(16), to: &wave)
        appendLittleEndian(UInt16(1), to: &wave) // Linear PCM
        appendLittleEndian(UInt16(1), to: &wave) // Mono
        appendLittleEndian(sampleRate, to: &wave)
        appendLittleEndian(sampleRate * 2, to: &wave)
        appendLittleEndian(UInt16(2), to: &wave)
        appendLittleEndian(UInt16(16), to: &wave)
        wave.append(contentsOf: "data".utf8)
        appendLittleEndian(UInt32(samples.count), to: &wave)
        wave.append(samples)
        return wave
    }

    private static func sample(for cue: Cue, at time: Double) -> Double {
        switch cue {
        case .diceRoll:
            let pulse = time.truncatingRemainder(dividingBy: 0.105)
            let envelope = exp(-pulse * 27) * min(1, time * 180)
            let frequency = 350 + 115 * exp(-pulse * 10)
            return (sin(2 * .pi * frequency * time) + 0.16 * sin(2 * .pi * frequency * 2.1 * time)) * envelope * 0.54

        case .cardFlip:
            let progress = time / Cue.cardFlip.duration
            let frequency = 1_180 - 520 * progress
            let attack = min(1, time * 150)
            return sin(2 * .pi * frequency * time) * exp(-time * 22) * attack * 0.58

        case .winner:
            let notes: [(start: Double, frequency: Double)] = [
                (0.00, 659.25),
                (0.13, 783.99),
                (0.27, 987.77),
                (0.43, 1_318.50)
            ]
            return notes.reduce(0) { value, note in
                let noteTime = time - note.start
                guard noteTime >= 0 else { return value }
                let envelope = min(1, noteTime * 95) * exp(-noteTime * 5.4)
                return value + sin(2 * .pi * note.frequency * noteTime) * envelope * 0.34
            }
        }
    }

    private static func appendLittleEndian<Value: FixedWidthInteger>(_ value: Value, to data: inout Data) {
        var encoded = value.littleEndian
        withUnsafeBytes(of: &encoded) { data.append(contentsOf: $0) }
    }
}
