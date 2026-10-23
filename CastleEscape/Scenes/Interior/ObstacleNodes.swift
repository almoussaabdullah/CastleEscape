import SpriteKit

/// An obstacle standing in the corridor. A correct answer calls `clear`, which plays the
/// obstacle's own animation while moving the hero to `targetX`.
class ObstacleNode: SKNode {
    let kind: ObstacleKind

    init(kind: ObstacleKind) {
        self.kind = kind
        super.init()
    }

    required init?(coder aDecoder: NSCoder) { nil }

    func clear(hero: HeroNode, targetX: CGFloat, completion: @escaping () -> Void) {
        hero.walk(to: targetX, speed: 260, completion: completion)
    }

    static func make(kind: ObstacleKind) -> ObstacleNode {
        switch kind {
        case .gap: return GapObstacleNode()
        case .lockedGate: return LockedGateObstacleNode()
        case .spikes: return SpikesObstacleNode()
        case .pendulum: return PendulumObstacleNode()
        case .magicBarrier: return MagicBarrierObstacleNode()
        case .crates: return CratesObstacleNode()
        }
    }
}

/// A pit in the floor; the hero jumps over it.
final class GapObstacleNode: ObstacleNode {
    static let width: CGFloat = 130

    init() {
        super.init(kind: .gap)
        let pit = ShapeFactory.rect(CGRect(x: -GapObstacleNode.width / 2, y: -CastleLayout.foundationDepth, width: GapObstacleNode.width, height: CastleLayout.foundationDepth + 2), fill: UIColor(red: 0.03, green: 0.03, blue: 0.07, alpha: 1))
        pit.zPosition = 3
        addChild(pit)
        let edgeL = ShapeFactory.rect(CGRect(x: -GapObstacleNode.width / 2 - 6, y: -14, width: 10, height: 16), fill: GamePalette.stoneLight)
        let edgeR = ShapeFactory.rect(CGRect(x: GapObstacleNode.width / 2 - 4, y: -14, width: 10, height: 16), fill: GamePalette.stoneLight)
        edgeL.zPosition = 3.1
        edgeR.zPosition = 3.1
        addChild(edgeL)
        addChild(edgeR)
        // A few spikes far below to make the pit read as dangerous (but cartoonish).
        for x in stride(from: -GapObstacleNode.width / 2 + 18, through: GapObstacleNode.width / 2 - 18, by: 28) {
            let spike = ShapeFactory.polygon([CGPoint(x: x - 10, y: -330), CGPoint(x: x + 10, y: -330), CGPoint(x: x, y: -270)], fill: GamePalette.ironLight.withAlphaComponent(0.35))
            spike.zPosition = 3.05
            addChild(spike)
        }
    }

    required init?(coder aDecoder: NSCoder) { nil }

    override func clear(hero: HeroNode, targetX: CGFloat, completion: @escaping () -> Void) {
        let runUp = position.x - GapObstacleNode.width / 2 - 40
        hero.walk(to: runUp, speed: 300) { [weak self] in
            guard let self = self else { return }
            AudioManager.shared.play(.jump)
            let landing = max(targetX, self.position.x + GapObstacleNode.width / 2 + 40)
            hero.jump(to: landing, height: 120, duration: 0.7) {
                AudioManager.shared.play(.land)
                let dust = SKEmitterNode.dustPuff()
                dust.position = CGPoint(x: hero.position.x, y: 4)
                self.parent?.addChild(dust)
                hero.walk(to: max(targetX, landing), speed: 260, completion: completion)
            }
        }
    }
}

/// Iron bars with a padlock. The lock pops and the bars rise into the ceiling.
final class LockedGateObstacleNode: ObstacleNode {
    private let bars = SKNode()
    private let lock = SKNode()

    init() {
        super.init(kind: .lockedGate)
        let frame = ShapeFactory.rect(CGRect(x: -34, y: 0, width: 68, height: CastleLayout.roomHeight), fill: GamePalette.stoneDark.withAlphaComponent(0.5))
        frame.zPosition = 4
        addChild(frame)
        for x in stride(from: CGFloat(-22), through: 22, by: 14.5) {
            let bar = ShapeFactory.rect(CGRect(x: x - 4, y: 0, width: 8, height: CastleLayout.roomHeight - 20), fill: GamePalette.iron, corner: 3)
            bars.addChild(bar)
        }
        for y in [CGFloat(90), CGFloat(230), CGFloat(370)] {
            let rail = ShapeFactory.rect(CGRect(x: -28, y: y, width: 56, height: 10), fill: GamePalette.ironLight, corner: 3)
            bars.addChild(rail)
        }
        bars.zPosition = 4.1
        addChild(bars)
        let body = ShapeFactory.rect(CGRect(x: -16, y: -18, width: 32, height: 26), fill: GamePalette.flagGold, corner: 6)
        let shackle = ShapeFactory.arch(width: 22, height: 26, fill: .clear, stroke: GamePalette.ironLight, lineWidth: 6)
        shackle.position = CGPoint(x: 0, y: 2)
        let keyhole = ShapeFactory.circle(radius: 3.5, fill: GamePalette.pupil)
        keyhole.position = CGPoint(x: 0, y: -6)
        lock.addChild(shackle)
        lock.addChild(body)
        lock.addChild(keyhole)
        lock.position = CGPoint(x: 0, y: 160)
        lock.zPosition = 4.2
        addChild(lock)
    }

    required init?(coder aDecoder: NSCoder) { nil }

    override func clear(hero: HeroNode, targetX: CGFloat, completion: @escaping () -> Void) {
        let approach = position.x - 90
        hero.walk(to: approach, speed: 280) { [weak self] in
            guard let self = self else { return }
            hero.reach(duration: 0.45)
            AudioManager.shared.play(.unlock)
            let wiggle = SKAction.sequence([.rotate(byAngle: 0.3, duration: 0.06), .rotate(byAngle: -0.6, duration: 0.08), .rotate(byAngle: 0.3, duration: 0.06)])
            let drop = SKAction.group([.moveBy(x: 0, y: -170, duration: 0.5), .rotate(byAngle: 1.2, duration: 0.5), .fadeOut(withDuration: 0.5)])
            drop.timingMode = .easeIn
            self.lock.run(.sequence([wiggle, wiggle, drop]))
            let burst = SKEmitterNode.sparkBurst(color: GamePalette.flagGold, count: 18, speed: 160, scale: 0.4)
            burst.position = self.lock.position
            burst.zPosition = 6
            self.addChild(burst)
            let rise = SKAction.moveBy(x: 0, y: CastleLayout.roomHeight, duration: 0.9)
            rise.timingMode = .easeInEaseOut
            self.bars.run(.sequence([.wait(forDuration: 0.45), rise]))
            self.run(.sequence([.wait(forDuration: 1.1), .run {
                hero.walk(to: targetX, speed: 260, completion: completion)
            }]))
        }
    }
}

/// Floor spikes that retract into the stone.
final class SpikesObstacleNode: ObstacleNode {
    private let spikes = SKNode()

    init() {
        super.init(kind: .spikes)
        let slot = ShapeFactory.rect(CGRect(x: -70, y: -8, width: 140, height: 10), fill: GamePalette.stoneShadow)
        slot.zPosition = 3
        addChild(slot)
        for x in stride(from: CGFloat(-56), through: 56, by: 28) {
            let spike = ShapeFactory.polygon([CGPoint(x: x - 11, y: 0), CGPoint(x: x + 11, y: 0), CGPoint(x: x, y: 62)], fill: GamePalette.ironLight, stroke: GamePalette.iron, lineWidth: 2)
            spikes.addChild(spike)
        }
        spikes.zPosition = 3.5
        addChild(spikes)
        // Menacing little bounce so the trap reads as active.
        let twitch = SKAction.sequence([.wait(forDuration: 1.4), .moveBy(x: 0, y: 6, duration: 0.08), .moveBy(x: 0, y: -6, duration: 0.12)])
        spikes.run(.repeatForever(twitch), withKey: "twitch")
    }

    required init?(coder aDecoder: NSCoder) { nil }

    override func clear(hero: HeroNode, targetX: CGFloat, completion: @escaping () -> Void) {
        let approach = position.x - 120
        hero.walk(to: approach, speed: 280) { [weak self] in
            guard let self = self else { return }
            hero.reach(duration: 0.3)
            self.spikes.removeAction(forKey: "twitch")
            AudioManager.shared.play(.guardClank, volume: 0.5)
            let retract = SKAction.moveBy(x: 0, y: -64, duration: 0.35)
            retract.timingMode = .easeIn
            self.spikes.run(retract)
            self.run(.sequence([.wait(forDuration: 0.5), .run {
                hero.walk(to: targetX, speed: 260, completion: completion)
            }]))
        }
    }
}

/// A log swinging from the ceiling on a chain. It is stopped high so the hero can duck under.
final class PendulumObstacleNode: ObstacleNode {
    private let arm = SKNode()

    init() {
        super.init(kind: .pendulum)
        arm.position = CGPoint(x: 0, y: CastleLayout.roomHeight)
        let chain = ShapeFactory.rect(CGRect(x: -4, y: -250, width: 8, height: 250), fill: GamePalette.ironLight)
        let log = ShapeFactory.rect(CGRect(x: -26, y: -330, width: 52, height: 90), fill: GamePalette.wood, corner: 16)
        let ring = ShapeFactory.rect(CGRect(x: -28, y: -300, width: 56, height: 10), fill: GamePalette.iron, corner: 4)
        arm.addChild(chain)
        arm.addChild(log)
        arm.addChild(ring)
        arm.zPosition = 5
        addChild(arm)
        let mount = ShapeFactory.circle(radius: 12, fill: GamePalette.iron)
        mount.position = arm.position
        mount.zPosition = 5.1
        addChild(mount)
        let swing = SKAction.sequence([.rotate(toAngle: 0.9, duration: 1.1), .rotate(toAngle: -0.9, duration: 1.1)])
        swing.timingMode = .easeInEaseOut
        arm.zRotation = -0.9
        arm.run(.repeatForever(swing), withKey: "swing")
    }

    required init?(coder aDecoder: NSCoder) { nil }

    override func clear(hero: HeroNode, targetX: CGFloat, completion: @escaping () -> Void) {
        let approach = position.x - 150
        hero.walk(to: approach, speed: 280) { [weak self] in
            guard let self = self else { return }
            self.arm.removeAction(forKey: "swing")
            let park = SKAction.rotate(toAngle: 1.25, duration: 0.5)
            park.timingMode = .easeOut
            self.arm.run(park)
            AudioManager.shared.play(.guardClank, volume: 0.4)
            self.run(.sequence([.wait(forDuration: 0.5), .run {
                hero.duck(duration: 0.9)
                hero.walk(to: targetX, speed: 220) {
                    completion()
                    // Resume swinging behind the hero for flavour.
                    let swing = SKAction.sequence([.rotate(toAngle: 0.9, duration: 1.1), .rotate(toAngle: -0.9, duration: 1.1)])
                    swing.timingMode = .easeInEaseOut
                    self.arm.run(.repeatForever(swing), withKey: "swing")
                }
            }]))
        }
    }
}

/// A wall of glowing runes that dissolves.
final class MagicBarrierObstacleNode: ObstacleNode {
    private let field: SKShapeNode
    private let motes: SKEmitterNode

    init() {
        field = ShapeFactory.rect(CGRect(x: -22, y: 0, width: 44, height: CastleLayout.roomHeight - 30), fill: GamePalette.magic.withAlphaComponent(0.35), stroke: GamePalette.magic, lineWidth: 3, corner: 14)
        motes = SKEmitterNode.magicMotes(color: GamePalette.magic, width: 50, height: CastleLayout.roomHeight - 60)
        super.init(kind: .magicBarrier)
        field.zPosition = 5
        addChild(field)
        motes.position = CGPoint(x: 0, y: (CastleLayout.roomHeight - 30) / 2)
        motes.zPosition = 5.1
        addChild(motes)
        let glow = ShapeFactory.glow(radius: 180, color: GamePalette.magic, alpha: 0.45)
        glow.position = CGPoint(x: 0, y: (CastleLayout.roomHeight - 30) / 2)
        glow.zPosition = 4.9
        addChild(glow)
        // Rune glyphs.
        let glyphs = ["ᚠ", "ᚢ", "ᚦ", "ᚨ"]
        for (i, glyph) in glyphs.enumerated() {
            let label = SKLabelNode(text: glyph)
            label.fontName = "AvenirNext-Bold"
            label.fontSize = 30
            label.fontColor = GamePalette.torchCore
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: 70 + CGFloat(i) * 90)
            label.zPosition = 5.2
            addChild(label)
            label.run(.repeatForever(.sequence([.fadeAlpha(to: 0.4, duration: 0.6 + Double(i) * 0.1), .fadeAlpha(to: 1, duration: 0.6)])))
        }
        let pulse = SKAction.sequence([.fadeAlpha(to: 0.7, duration: 0.7), .fadeAlpha(to: 1, duration: 0.7)])
        field.run(.repeatForever(pulse))
    }

    required init?(coder aDecoder: NSCoder) { nil }

    override func clear(hero: HeroNode, targetX: CGFloat, completion: @escaping () -> Void) {
        let approach = position.x - 110
        hero.walk(to: approach, speed: 280) { [weak self] in
            guard let self = self else { return }
            hero.reach(duration: 0.5)
            AudioManager.shared.play(.comboSparkle, volume: 0.6)
            let burst = SKEmitterNode.sparkBurst(color: GamePalette.magic, count: 40, speed: 240, scale: 0.5)
            burst.position = CGPoint(x: 0, y: 200)
            burst.zPosition = 6
            self.addChild(burst)
            self.motes.particleBirthRate = 0
            let dissolve = SKAction.group([.scaleY(to: 0.02, duration: 0.45), .fadeOut(withDuration: 0.45)])
            dissolve.timingMode = .easeIn
            for child in self.children where child !== burst { child.run(dissolve) }
            self.run(.sequence([.wait(forDuration: 0.55), .run {
                hero.walk(to: targetX, speed: 260, completion: completion)
            }]))
        }
    }
}

/// Stacked wooden crates the hero hops over.
final class CratesObstacleNode: ObstacleNode {
    init() {
        super.init(kind: .crates)
        let crateSize: CGFloat = 84
        let positions = [CGPoint(x: -crateSize / 2 - 2, y: 0), CGPoint(x: crateSize / 2 + 2, y: 0), CGPoint(x: 0, y: crateSize + 4)]
        for p in positions {
            let crate = SKNode()
            crate.position = p
            let box = TiledTextureNode(rect: CGRect(x: -crateSize / 2, y: 0, width: crateSize, height: crateSize), textureName: "wood_tile", tileSize: crateSize)
            let outline = ShapeFactory.rect(CGRect(x: -crateSize / 2, y: 0, width: crateSize, height: crateSize), fill: .clear, stroke: GamePalette.woodDark, lineWidth: 5)
            let cross = ShapeFactory.line(from: CGPoint(x: -crateSize / 2 + 6, y: 6), to: CGPoint(x: crateSize / 2 - 6, y: crateSize - 6), color: GamePalette.woodDark.withAlphaComponent(0.6), width: 4)
            crate.addChild(box)
            crate.addChild(outline)
            crate.addChild(cross)
            crate.zPosition = 4
            addChild(crate)
        }
    }

    required init?(coder aDecoder: NSCoder) { nil }

    override func clear(hero: HeroNode, targetX: CGFloat, completion: @escaping () -> Void) {
        let approach = position.x - 120
        hero.walk(to: approach, speed: 300) { [weak self] in
            guard let self = self else { return }
            AudioManager.shared.play(.jump)
            hero.jump(to: self.position.x + 125, height: 150, duration: 0.75) {
                AudioManager.shared.play(.land, volume: 0.7)
                hero.walk(to: targetX, speed: 260, completion: completion)
            }
        }
    }
}
