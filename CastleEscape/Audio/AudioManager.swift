import AVFoundation
import Foundation

/// Sound effects the game can trigger.
enum SoundEffect: String, CaseIterable {
    case correct, wrong, timeout, footstep, jump, land, doorCreak, unlock, whoosh
    case guardClank, comboSparkle, shield, tick, uiTap, victoryFanfare, gameOver
}

/// Plays synthesized audio through AVAudioEngine. Music and effects have independent toggles.
final class AudioManager {
    static let shared = AudioManager()

    var musicEnabled: Bool = true {
        didSet { musicPlayer.volume = musicEnabled ? musicVolume : 0 }
    }
    var soundEffectsEnabled: Bool = true

    private let engine = AVAudioEngine()
    private let musicPlayer = AVAudioPlayerNode()
    private var effectPlayers: [AVAudioPlayerNode] = []
    private var nextEffectPlayer = 0
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var musicBuffer: AVAudioPCMBuffer?
    private let musicVolume: Float = 0.55
    private var isConfigured = false
    private var lastFootstep: TimeInterval = 0
    private let renderQueue = DispatchQueue(label: "castleescape.audio.render", qos: .utility)

    private init() {}

    /// Builds the graph and renders all buffers in the background; safe to call more than once.
    func prepare() {
        guard !isConfigured else { return }
        isConfigured = true
        configureSession()

        let format = SoundSynthesizer.format
        engine.attach(musicPlayer)
        engine.connect(musicPlayer, to: engine.mainMixerNode, format: format)
        for _ in 0..<6 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            effectPlayers.append(player)
        }
        engine.mainMixerNode.outputVolume = 0.9
        startEngineIfNeeded()

        renderQueue.async { [weak self] in
            var rendered: [SoundEffect: AVAudioPCMBuffer] = [:]
            for effect in SoundEffect.allCases {
                if let buffer = AudioManager.render(effect) { rendered[effect] = buffer }
            }
            let music = SoundSynthesizer.ambientLoop()
            DispatchQueue.main.async {
                self?.buffers = rendered
                self?.musicBuffer = music
                if self?.musicRequested == true { self?.startMusic() }
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification, object: nil)
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            #if DEBUG
            print("AudioManager: engine failed to start: \(error)")
            #endif
        }
    }

    private static func render(_ effect: SoundEffect) -> AVAudioPCMBuffer? {
        switch effect {
        case .correct: return SoundSynthesizer.correct()
        case .wrong: return SoundSynthesizer.wrong()
        case .timeout: return SoundSynthesizer.timeout()
        case .footstep: return SoundSynthesizer.footstep()
        case .jump: return SoundSynthesizer.jump()
        case .land: return SoundSynthesizer.land()
        case .doorCreak: return SoundSynthesizer.doorCreak()
        case .unlock: return SoundSynthesizer.unlock()
        case .whoosh: return SoundSynthesizer.whoosh()
        case .guardClank: return SoundSynthesizer.guardClank()
        case .comboSparkle: return SoundSynthesizer.comboSparkle()
        case .shield: return SoundSynthesizer.shield()
        case .tick: return SoundSynthesizer.tick()
        case .uiTap: return SoundSynthesizer.uiTap()
        case .victoryFanfare: return SoundSynthesizer.victoryFanfare()
        case .gameOver: return SoundSynthesizer.gameOver()
        }
    }

    // MARK: - Effects

    func play(_ effect: SoundEffect, volume: Float = 1) {
        guard soundEffectsEnabled, isConfigured, let buffer = buffers[effect] else { return }
        if effect == .footstep {
            let now = Date().timeIntervalSince1970
            guard now - lastFootstep > 0.12 else { return }
            lastFootstep = now
        }
        startEngineIfNeeded()
        guard engine.isRunning, !effectPlayers.isEmpty else { return }
        let player = effectPlayers[nextEffectPlayer]
        nextEffectPlayer = (nextEffectPlayer + 1) % effectPlayers.count
        player.stop()
        player.volume = volume
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    // MARK: - Music

    private var musicRequested = false

    func startMusic() {
        musicRequested = true
        guard isConfigured, let buffer = musicBuffer else { return }
        startEngineIfNeeded()
        guard engine.isRunning else { return }
        if musicPlayer.isPlaying { return }
        musicPlayer.volume = musicEnabled ? musicVolume : 0
        musicPlayer.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
        musicPlayer.play()
    }

    func stopMusic() {
        musicRequested = false
        musicPlayer.stop()
    }

    /// Lowers music briefly (e.g. under a fanfare) then restores it.
    func duckMusic(for seconds: Double) {
        guard musicEnabled else { return }
        musicPlayer.volume = musicVolume * 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let self = self else { return }
            self.musicPlayer.volume = self.musicEnabled ? self.musicVolume : 0
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            musicPlayer.pause()
        case .ended:
            configureSession()
            startEngineIfNeeded()
            if musicRequested { musicPlayer.play() }
        @unknown default:
            break
        }
    }
}
