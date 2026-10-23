import SpriteKit

/// Arched window on the castle facade. Shows locked / current / completed state.
final class FloorWindowNode: SKNode {
    private let pane: SKShapeNode
    private let glow: SKSpriteNode
    private let banner: SKNode
    private let archFrame: SKShapeNode
    private(set) var status: FloorStatus = .locked
    let floor: Int

    init(floor: Int, size: CGSize = CastleLayout.windowSize) {
        self.floor = floor
        archFrame = ShapeFactory.arch(width: size.width + 26, height: size.height + 14, fill: GamePalette.stoneLight)
        pane = ShapeFactory.arch(width: size.width, height: size.height, fill: GamePalette.windowDark)
        glow = ShapeFactory.glow(radius: 360, color: GamePalette.windowCurrent, alpha: 0)
        banner = SKNode()
        super.init()
        archFrame.position = CGPoint(x: 0, y: -size.height / 2 - 7)
        pane.position = CGPoint(x: 0, y: -size.height / 2)
        glow.zPosition = -1
        addChild(glow)
        addChild(archFrame)
        addChild(pane)
        // Window cross bars.
        let barV = ShapeFactory.rect(CGRect(x: -3, y: -size.height / 2, width: 6, height: size.height), fill: GamePalette.stoneDark)
        let barH = ShapeFactory.rect(CGRect(x: -size.width / 2, y: -3, width: size.width, height: 6), fill: GamePalette.stoneDark)
        barV.zPosition = 1
        barH.zPosition = 1
        addChild(barV)
        addChild(barH)
        // Completed banner: a small hanging pennant beneath the sill.
        let sill = ShapeFactory.rect(CGRect(x: -size.width / 2 - 18, y: -size.height / 2 - 18, width: size.width + 36, height: 14), fill: GamePalette.stoneLight)
        addChild(sill)
        let pennant = ShapeFactory.polygon([CGPoint(x: -22, y: -size.height / 2 - 18), CGPoint(x: 22, y: -size.height / 2 - 18), CGPoint(x: 0, y: -size.height / 2 - 70)], fill: GamePalette.success)
        let star = SKLabelNode(text: "★")
        star.fontName = "AvenirNext-Bold"
        star.fontSize = 26
        star.fontColor = GamePalette.flagGold
        star.verticalAlignmentMode = .center
        star.position = CGPoint(x: 0, y: -size.height / 2 - 36)
        banner.addChild(pennant)
        banner.addChild(star)
        banner.zPosition = 2
        banner.alpha = 0
        addChild(banner)
        apply(status: .locked, animated: false)
    }

    required init?(coder aDecoder: NSCoder) { nil }

    func apply(status: FloorStatus, animated: Bool) {
        self.status = status
        glow.removeAllActions()
        let duration = animated ? 0.5 : 0
        switch status {
        case .locked:
            pane.fillColor = GamePalette.windowDark
            glow.run(.fadeAlpha(to: 0, duration: duration))
            banner.run(.fadeAlpha(to: 0, duration: duration))
        case .current:
            pane.fillColor = GamePalette.windowCurrent
            glow.color = GamePalette.windowCurrent
            glow.run(.fadeAlpha(to: 0.9, duration: duration))
            banner.run(.fadeAlpha(to: 0, duration: duration))
            let pulse = SKAction.sequence([.scale(to: 1.25, duration: 0.9), .scale(to: 0.9, duration: 0.9)])
            pulse.timingMode = .easeInEaseOut
            glow.run(.repeatForever(pulse), withKey: "pulse")
        case .completed:
            pane.fillColor = GamePalette.windowCompleted
            glow.color = GamePalette.windowCompleted
            glow.setScale(0.7)
            glow.run(.fadeAlpha(to: 0.55, duration: duration))
            banner.run(.fadeAlpha(to: 1, duration: duration))
        }
    }

    /// Burst used when a floor flips to completed during the zoom-out.
    func celebrate() {
        let burst = SKEmitterNode.sparkBurst(color: GamePalette.success, count: 36, speed: 420, scale: 1.4)
        burst.zPosition = 5
        addChild(burst)
        let ring = ShapeFactory.circle(radius: 20, fill: .clear, stroke: GamePalette.windowCompleted, lineWidth: 8)
        ring.zPosition = 4
        addChild(ring)
        ring.run(.sequence([.group([.scale(to: 14, duration: 0.8), .fadeOut(withDuration: 0.8)]), .removeFromParent()]))
    }
}

/// Small decorative window that flickers randomly to make the castle feel inhabited.
final class DecorWindowNode: SKNode {
    init(width: CGFloat = 54, height: CGFloat = 90, lit: Bool) {
        super.init()
        let archFrame = ShapeFactory.arch(width: width + 14, height: height + 8, fill: GamePalette.stoneDark)
        archFrame.position = CGPoint(x: 0, y: -height / 2 - 4)
        let pane = ShapeFactory.arch(width: width, height: height, fill: lit ? GamePalette.windowLit : GamePalette.windowDark)
        pane.position = CGPoint(x: 0, y: -height / 2)
        addChild(archFrame)
        addChild(pane)
        if lit {
            let glow = ShapeFactory.glow(radius: 120, color: GamePalette.windowLit, alpha: 0.35)
            glow.zPosition = -1
            addChild(glow)
            let flicker = SKAction.sequence([
                .fadeAlpha(to: 0.2, duration: Double.random(in: 0.8...2.2)),
                .fadeAlpha(to: 0.45, duration: Double.random(in: 0.8...2.2)),
            ])
            glow.run(.repeatForever(flicker))
        }
    }

    required init?(coder aDecoder: NSCoder) { nil }
}

/// Wall-mounted torch with a flickering flame, glow and embers.
final class TorchNode: SKNode {
    init(scale: CGFloat = 1, embers: Bool = false) {
        super.init()
        let bracket = ShapeFactory.rect(CGRect(x: -6, y: -40, width: 12, height: 44), fill: GamePalette.woodDark, corner: 4)
        let cup = ShapeFactory.rect(CGRect(x: -12, y: 0, width: 24, height: 12), fill: GamePalette.iron, corner: 4)
        let flameOuter = ShapeFactory.ellipse(size: CGSize(width: 26, height: 46), fill: GamePalette.torch)
        flameOuter.position = CGPoint(x: 0, y: 30)
        let flameInner = ShapeFactory.ellipse(size: CGSize(width: 12, height: 24), fill: GamePalette.torchCore)
        flameInner.position = CGPoint(x: 0, y: 24)
        let glow = ShapeFactory.glow(radius: 190, color: GamePalette.torch, alpha: 0.55)
        glow.position = CGPoint(x: 0, y: 26)
        glow.zPosition = -1
        addChild(glow)
        addChild(bracket)
        addChild(cup)
        addChild(flameOuter)
        addChild(flameInner)
        setScale(scale)

        let flicker = SKAction.sequence([
            .group([.scaleX(to: 0.85, y: 1.1, duration: 0.12), .moveBy(x: 2, y: 0, duration: 0.12)]),
            .group([.scaleX(to: 1.1, y: 0.9, duration: 0.14), .moveBy(x: -2, y: 0, duration: 0.14)]),
        ])
        flameOuter.run(.repeatForever(flicker))
        flameInner.run(.repeatForever(flicker.reversed()))
        let glowFlicker = SKAction.sequence([.fadeAlpha(to: 0.4, duration: 0.18), .fadeAlpha(to: 0.6, duration: 0.22), .fadeAlpha(to: 0.5, duration: 0.14)])
        glow.run(.repeatForever(glowFlicker))

        if embers {
            let emitter = SKEmitterNode.embers()
            emitter.position = CGPoint(x: 0, y: 40)
            emitter.zPosition = 2
            addChild(emitter)
        }
    }

    required init?(coder aDecoder: NSCoder) { nil }
}

/// A pennant that waves in the wind (path is re-generated every frame).
final class FlagNode: SKNode {
    private let cloth = SKShapeNode()
    private let color: UIColor
    private let length: CGFloat
    private let flagHeight: CGFloat

    init(color: UIColor = GamePalette.flag, length: CGFloat = 110, height: CGFloat = 64, poleHeight: CGFloat = 170) {
        self.color = color
        self.length = length
        self.flagHeight = height
        super.init()
        let pole = ShapeFactory.rect(CGRect(x: -4, y: 0, width: 8, height: poleHeight), fill: GamePalette.ironLight)
        let finial = ShapeFactory.circle(radius: 8, fill: GamePalette.flagGold)
        finial.position = CGPoint(x: 0, y: poleHeight + 4)
        cloth.fillColor = color
        cloth.strokeColor = .clear
        cloth.position = CGPoint(x: 4, y: poleHeight - height - 6)
        addChild(pole)
        addChild(finial)
        addChild(cloth)
        cloth.path = flagPath(phase: 0)
        let wave = SKAction.customAction(withDuration: 1_000_000) { [weak self] _, elapsed in
            guard let self = self else { return }
            self.cloth.path = self.flagPath(phase: CGFloat(elapsed) * 5)
        }
        cloth.run(wave, withKey: "wave")
    }

    required init?(coder aDecoder: NSCoder) { nil }

    private func flagPath(phase: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let segments = 6
        path.move(to: CGPoint(x: 0, y: flagHeight))
        for i in 1...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let wave = sin(phase + t * 4) * 7 * t
            path.addLine(to: CGPoint(x: t * length, y: flagHeight - t * flagHeight * 0.45 + wave))
        }
        for i in stride(from: segments, through: 0, by: -1) {
            let t = CGFloat(i) / CGFloat(segments)
            let wave = sin(phase + t * 4) * 7 * t
            path.addLine(to: CGPoint(x: t * length, y: t * flagHeight * 0.45 + wave))
        }
        path.closeSubpath()
        return path
    }
}

extension SKEmitterNode {
    /// One-shot radial burst of sparkles.
    static func sparkBurst(color: UIColor, count: Int = 24, speed: CGFloat = 260, scale: CGFloat = 0.5) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = TextureCache.texture("spark")
        emitter.particleBirthRate = CGFloat(count) * 10
        emitter.numParticlesToEmit = count
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.4
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speed * 0.6
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 1
        emitter.particleAlphaSpeed = -1.2
        emitter.particleScale = scale
        emitter.particleScaleRange = scale * 0.5
        emitter.particleScaleSpeed = -scale * 0.6
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        emitter.yAcceleration = -300
        emitter.run(.sequence([.wait(forDuration: 2.0), .removeFromParent()]))
        return emitter
    }

    /// Rising embers for torches.
    static func embers() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = TextureCache.texture("spark")
        emitter.particleBirthRate = 6
        emitter.particleLifetime = 1.6
        emitter.particleLifetimeRange = 0.6
        emitter.particleSpeed = 50
        emitter.particleSpeedRange = 30
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = 0.6
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -0.6
        emitter.particleScale = 0.18
        emitter.particleScaleRange = 0.1
        emitter.particleColor = GamePalette.torch
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        emitter.xAcceleration = 10
        return emitter
    }

    /// Dust puff when the hero lands.
    static func dustPuff() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = TextureCache.texture("glow_soft")
        emitter.particleBirthRate = 200
        emitter.numParticlesToEmit = 12
        emitter.particleLifetime = 0.5
        emitter.particleSpeed = 90
        emitter.particleSpeedRange = 40
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        emitter.particleAlpha = 0.35
        emitter.particleAlphaSpeed = -0.7
        emitter.particleScale = 0.12
        emitter.particleScaleSpeed = 0.25
        emitter.particleColor = GamePalette.stoneLight
        emitter.particleColorBlendFactor = 1
        emitter.run(.sequence([.wait(forDuration: 1.2), .removeFromParent()]))
        return emitter
    }

    /// Slow magical motes for barriers and the alchemist lab.
    static func magicMotes(color: UIColor, width: CGFloat, height: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = TextureCache.texture("spark")
        emitter.particleBirthRate = 10
        emitter.particleLifetime = 2.4
        emitter.particleLifetimeRange = 1
        emitter.particlePositionRange = CGVector(dx: width, dy: height)
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 15
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0
        emitter.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0.0, 0.9, 0.0], times: [0.0, 0.5, 1.0])
        emitter.particleScale = 0.14
        emitter.particleScaleRange = 0.08
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        return emitter
    }
}
