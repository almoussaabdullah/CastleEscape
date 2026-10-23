import AVFoundation
import Foundation

/// Renders original sound effects and a looping ambient track directly into PCM buffers.
/// No audio files are shipped, so nothing here is copyrighted material; every sound is synthesized.
enum SoundSynthesizer {
    static let sampleRate: Double = 44_100

    static var format: AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }

    // MARK: - Building blocks

    /// Builds a mono buffer from a sample generator. `generator` receives time in seconds.
    static func render(duration: Double, _ generator: (Double) -> Double) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard frameCount > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount
        let step = 1.0 / sampleRate
        for i in 0..<Int(frameCount) {
            let t = Double(i) * step
            channel[i] = Float(max(-1, min(1, generator(t))))
        }
        return buffer
    }

    /// Exponential decay envelope.
    static func decay(_ t: Double, _ rate: Double) -> Double { exp(-t * rate) }

    /// Attack/decay envelope in seconds.
    static func envelope(_ t: Double, attack: Double, release: Double, total: Double) -> Double {
        if t < attack { return t / attack }
        if t > total - release { return max(0, (total - t) / release) }
        return 1
    }

    /// A plucked-string style tone: sine fundamental with soft harmonics and fast decay.
    static func pluck(_ t: Double, frequency f: Double, decayRate: Double = 6) -> Double {
        let e = decay(t, decayRate)
        return (sin(2 * .pi * f * t) * 0.6 + sin(4 * .pi * f * t) * 0.25 * decay(t, decayRate * 1.6) + sin(6 * .pi * f * t) * 0.1 * decay(t, decayRate * 2.2)) * e
    }

    /// Deterministic white noise.
    static func noise(_ seed: inout UInt32) -> Double {
        seed = seed &* 1_664_525 &+ 1_013_904_223
        return Double(seed >> 8) / Double(1 << 24) * 2 - 1
    }

    /// Frequency of a MIDI note.
    static func midi(_ note: Double) -> Double { 440 * pow(2, (note - 69) / 12) }

    // MARK: - Sound effects

    static func correct() -> AVAudioPCMBuffer? {
        let notes = [midi(72), midi(76), midi(79)]   // C5 E5 G5
        return render(duration: 0.65) { t in
            var s = 0.0
            for (i, f) in notes.enumerated() {
                let start = Double(i) * 0.09
                if t >= start { s += pluck(t - start, frequency: f, decayRate: 5) * 0.5 }
            }
            return s
        }
    }

    static func wrong() -> AVAudioPCMBuffer? {
        render(duration: 0.45) { t in
            let f = t < 0.2 ? 180.0 : 140.0
            let square: Double = sin(2 * .pi * f * t) > 0 ? 1 : -1
            let tri = asin(sin(2 * .pi * f * t)) / (.pi / 2)
            return (square * 0.25 + tri * 0.35) * envelope(t, attack: 0.01, release: 0.12, total: 0.45) * 0.6
        }
    }

    static func timeout() -> AVAudioPCMBuffer? {
        render(duration: 0.5) { t in
            let f = 330 - t * 300
            return sin(2 * .pi * f * t) * envelope(t, attack: 0.01, release: 0.2, total: 0.5) * 0.5
        }
    }

    static func footstep() -> AVAudioPCMBuffer? {
        var seed: UInt32 = 12_345
        return render(duration: 0.12) { t in
            let n = noise(&seed)
            let thud = sin(2 * .pi * 110 * t) * decay(t, 40)
            return (n * 0.25 * decay(t, 60) + thud * 0.5) * 0.7
        }
    }

    static func jump() -> AVAudioPCMBuffer? {
        render(duration: 0.3) { t in
            let f = 300 + t * 900
            return sin(2 * .pi * f * t) * envelope(t, attack: 0.01, release: 0.1, total: 0.3) * 0.4
        }
    }

    static func land() -> AVAudioPCMBuffer? {
        var seed: UInt32 = 777
        return render(duration: 0.25) { t in
            (sin(2 * .pi * 80 * t) * decay(t, 18) * 0.8 + noise(&seed) * 0.15 * decay(t, 50)) * 0.8
        }
    }

    static func doorCreak() -> AVAudioPCMBuffer? {
        var seed: UInt32 = 99
        return render(duration: 1.1) { t in
            let vib = sin(2 * .pi * 11 * t) * 12
            let f = 420 - t * 180 + vib
            let tone = sin(2 * .pi * f * t) * 0.35 + sin(2 * .pi * f * 2.01 * t) * 0.12
            let grit = noise(&seed) * 0.08
            return (tone + grit) * envelope(t, attack: 0.08, release: 0.35, total: 1.1) * 0.7
        }
    }

    static func unlock() -> AVAudioPCMBuffer? {
        render(duration: 0.5) { t in
            let click = t < 0.03 ? sin(2 * .pi * 1_800 * t) * (1 - t / 0.03) : 0
            let chime = t > 0.05 ? pluck(t - 0.05, frequency: midi(84), decayRate: 7) * 0.5 : 0
            return click * 0.6 + chime
        }
    }

    static func whoosh() -> AVAudioPCMBuffer? {
        var seed: UInt32 = 4_242
        var low = 0.0
        return render(duration: 0.9) { t in
            let n = noise(&seed)
            // Simple one-pole low-pass whose cutoff rises and falls with the envelope.
            let env = sin(.pi * t / 0.9)
            let alpha = 0.02 + env * 0.3
            low += alpha * (n - low)
            return low * env * 1.6
        }
    }

    static func guardClank() -> AVAudioPCMBuffer? {
        var seed: UInt32 = 31
        return render(duration: 0.35) { t in
            let metal = sin(2 * .pi * 1_240 * t) * 0.3 + sin(2 * .pi * 1_875 * t) * 0.2 + sin(2 * .pi * 2_630 * t) * 0.1
            return (metal * decay(t, 14) + noise(&seed) * 0.2 * decay(t, 45)) * 0.7
        }
    }

    static func comboSparkle() -> AVAudioPCMBuffer? {
        let notes = [midi(79), midi(83), midi(86), midi(91)]
        return render(duration: 0.7) { t in
            var s = 0.0
            for (i, f) in notes.enumerated() {
                let start = Double(i) * 0.07
                if t >= start { s += pluck(t - start, frequency: f, decayRate: 6) * 0.35 }
            }
            return s
        }
    }

    static func shield() -> AVAudioPCMBuffer? {
        render(duration: 0.8) { t in
            let f = 220 + sin(2 * .pi * 3 * t) * 20
            return (sin(2 * .pi * f * t) * 0.3 + sin(2 * .pi * f * 1.5 * t) * 0.2) * envelope(t, attack: 0.15, release: 0.4, total: 0.8) * 0.8
        }
    }

    static func tick() -> AVAudioPCMBuffer? {
        render(duration: 0.06) { t in
            sin(2 * .pi * 1_400 * t) * decay(t, 90) * 0.4
        }
    }

    static func uiTap() -> AVAudioPCMBuffer? {
        render(duration: 0.08) { t in
            sin(2 * .pi * 900 * t) * decay(t, 70) * 0.35
        }
    }

    static func victoryFanfare() -> AVAudioPCMBuffer? {
        // A short triumphant phrase in D major.
        let sequence: [(note: Double, start: Double, length: Double)] = [
            (62, 0.0, 0.25), (66, 0.25, 0.25), (69, 0.5, 0.25), (74, 0.75, 0.6),
            (73, 1.4, 0.2), (74, 1.6, 0.9),
        ]
        return render(duration: 2.8) { t in
            var s = 0.0
            for item in sequence where t >= item.start {
                let local = t - item.start
                let f = midi(item.note)
                let brass = sin(2 * .pi * f * t) * 0.35 + sin(2 * .pi * f * 2 * t) * 0.18 + sin(2 * .pi * f * 3 * t) * 0.08
                s += brass * envelope(local, attack: 0.03, release: 0.12, total: item.length) * (local <= item.length ? 1 : 0)
            }
            let shimmer = t > 1.6 ? pluck(t - 1.6, frequency: midi(86), decayRate: 3) * 0.25 : 0
            return (s + shimmer) * 0.8
        }
    }

    static func gameOver() -> AVAudioPCMBuffer? {
        let notes = [midi(64), midi(60), midi(55)]
        return render(duration: 1.6) { t in
            var s = 0.0
            for (i, f) in notes.enumerated() {
                let start = Double(i) * 0.35
                if t >= start {
                    let local = t - start
                    s += (sin(2 * .pi * f * local) * 0.4 + sin(2 * .pi * f * 0.5 * local) * 0.25) * envelope(local, attack: 0.02, release: 0.3, total: 0.6) * (local < 0.6 ? 1 : 0)
                }
            }
            return s * 0.8
        }
    }

    // MARK: - Music

    /// A 16-second ambient loop: slow lute-like arpeggios in D dorian over a drone and soft wind.
    static func ambientLoop(bars: Int = 4, tempo: Double = 68) -> AVAudioPCMBuffer? {
        let beat = 60 / tempo
        let barLength = beat * 4
        let duration = barLength * Double(bars)
        // Chord tones per bar (MIDI): Dm, Am, C, G — modal, slightly mysterious.
        let chords: [[Double]] = [[50, 57, 62, 65], [45, 52, 57, 60], [48, 55, 60, 64], [43, 50, 55, 59]]
        let pattern: [Int] = [0, 1, 2, 3, 2, 1, 0, 2]    // arpeggio order per eighth note
        var seed: UInt32 = 2_024
        var wind = 0.0
        return render(duration: duration) { t in
            let bar = Int(t / barLength) % bars
            let chord = chords[bar % chords.count]
            let posInBar = t - Double(Int(t / barLength)) * barLength
            let eighth = beat / 2
            let stepIndex = Int(posInBar / eighth)
            let stepStart = Double(stepIndex) * eighth
            let local = posInBar - stepStart
            let note = chord[pattern[stepIndex % pattern.count] % chord.count] + 12
            var s = pluck(local, frequency: midi(note), decayRate: 3.2) * 0.22
            // previous note tail for smoother phrasing
            if stepIndex > 0 {
                let prevNote = chord[pattern[(stepIndex - 1) % pattern.count] % chord.count] + 12
                s += pluck(local + eighth, frequency: midi(prevNote), decayRate: 3.2) * 0.22
            }
            // drone: root an octave below with slow tremolo
            let root = midi(chord[0] - 12)
            let drone = (sin(2 * .pi * root * t) * 0.12 + sin(2 * .pi * root * 1.5 * t) * 0.05) * (0.8 + 0.2 * sin(2 * .pi * 0.25 * t))
            // wind: heavily low-passed noise with slow swell
            wind += 0.004 * (noise(&seed) - wind)
            let swell = 0.5 + 0.5 * sin(2 * .pi * t / duration * 2)
            let windOut = wind * 2.5 * swell
            // fade the loop edges to avoid clicks
            let edge = min(1, min(t, duration - t) / 0.05)
            return (s + drone + windOut) * edge
        }
    }
}
