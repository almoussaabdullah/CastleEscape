import SpriteKit

/// A cartoon castle guard: round helmet with a visor slit, plate armour, red tabard and a
/// shield. Intimidating in silhouette, harmless in behaviour — he only catches the hero.
final class GuardNode: CharacterNode {
    private let angryTint = SKShapeNode()
    private let visor = SKShapeNode()
    private let lanternGlow: SKSpriteNode

    override var height: CGFloat { 168 }
    override var headRestY: CGFloat { 132 }

    override init() {
        lanternGlow = ShapeFactory.glow(radius: 90, color: GamePalette.torch, alpha: 0.35)
        super.init()
        buildLegs()
        buildTorso()
        buildArms()
        buildHead()
        startIdle()
        face(1)
    }

    required init?(coder aDecoder: NSCoder) { nil }

    private func buildLegs() {
        for (leg, x) in [(leftLeg, CGFloat(-13)), (rightLeg, CGFloat(13))] {
            leg.position = CGPoint(x: x, y: 52)
            let greave = ShapeFactory.rect(CGRect(x: -10, y: -48, width: 20, height: 50), fill: GamePalette.armorDark, corner: 8)
            let boot = ShapeFactory.rect(CGRect(x: -12, y: -54, width: 28, height: 16), fill: GamePalette.iron, corner: 6)
            boot.position = CGPoint(x: 1, y: 2)
            leg.addChild(greave)
            leg.addChild(boot)
        }
    }

    private func buildTorso() {
        let plate = ShapeFactory.rect(CGRect(x: -28, y: 48, width: 56, height: 64), fill: GamePalette.armor, corner: 16)
        let tabard = ShapeFactory.rect(CGRect(x: -14, y: 50, width: 28, height: 56), fill: GamePalette.guardCloth, corner: 6)
        let emblem = ShapeFactory.polygon([CGPoint(x: 0, y: 92), CGPoint(x: 8, y: 80), CGPoint(x: 0, y: 66), CGPoint(x: -8, y: 80)], fill: GamePalette.flagGold)
        let belt = ShapeFactory.rect(CGRect(x: -28, y: 60, width: 56, height: 8), fill: GamePalette.woodDark)
        let pauldronL = ShapeFactory.circle(radius: 12, fill: GamePalette.armorDark)
        pauldronL.position = CGPoint(x: -26, y: 104)
        let pauldronR = ShapeFactory.circle(radius: 12, fill: GamePalette.armorDark)
        pauldronR.position = CGPoint(x: 26, y: 104)
        torso.addChild(plate)
        torso.addChild(tabard)
        torso.addChild(emblem)
        torso.addChild(belt)
        torso.addChild(pauldronL)
        torso.addChild(pauldronR)

        angryTint.path = CGPath(roundedRect: CGRect(x: -30, y: 46, width: 60, height: 70), cornerWidth: 16, cornerHeight: 16, transform: nil)
        angryTint.fillColor = GamePalette.danger
        angryTint.strokeColor = .clear
        angryTint.alpha = 0
        angryTint.zPosition = 5
        torso.addChild(angryTint)
    }

    private func buildArms() {
        // Left arm (behind) carries the lantern, right arm (front) carries the shield.
        leftArm.position = CGPoint(x: -24, y: 102)
        leftArm.zPosition = 1
        let sleeveL = ShapeFactory.rect(CGRect(x: -8, y: -44, width: 16, height: 46), fill: GamePalette.armorDark, corner: 8)
        let lantern = SKNode()
        lantern.position = CGPoint(x: 0, y: -52)
        let lanternBody = ShapeFactory.rect(CGRect(x: -7, y: -12, width: 14, height: 20), fill: GamePalette.iron, corner: 3)
        let lanternLight = ShapeFactory.rect(CGRect(x: -5, y: -10, width: 10, height: 14), fill: GamePalette.torchCore, corner: 2)
        lanternGlow.position = CGPoint(x: 0, y: -2)
        lanternGlow.zPosition = -1
        lantern.addChild(lanternGlow)
        lantern.addChild(lanternBody)
        lantern.addChild(lanternLight)
        leftArm.addChild(sleeveL)
        leftArm.addChild(lantern)

        rightArm.position = CGPoint(x: 24, y: 102)
        rightArm.zPosition = 3
        let sleeveR = ShapeFactory.rect(CGRect(x: -8, y: -44, width: 16, height: 46), fill: GamePalette.armorDark, corner: 8)
        let shield = ShapeFactory.polygon([
            CGPoint(x: -20, y: -16), CGPoint(x: 20, y: -16), CGPoint(x: 20, y: -36),
            CGPoint(x: 0, y: -60), CGPoint(x: -20, y: -36),
        ], fill: GamePalette.shieldRed, stroke: GamePalette.flagGold, lineWidth: 3)
        shield.position = CGPoint(x: 4, y: -4)
        let boss = ShapeFactory.circle(radius: 5, fill: GamePalette.flagGold)
        boss.position = CGPoint(x: 4, y: -36)
        rightArm.addChild(sleeveR)
        rightArm.addChild(shield)
        rightArm.addChild(boss)

        let flicker = SKAction.sequence([.fadeAlpha(to: 0.25, duration: 0.3), .fadeAlpha(to: 0.4, duration: 0.25)])
        lanternGlow.run(.repeatForever(flicker))
    }

    private func buildHead() {
        head.position = CGPoint(x: 0, y: headRestY)
        let face = ShapeFactory.circle(radius: 24, fill: GamePalette.skin)
        let helmet = ShapeFactory.polygon([
            CGPoint(x: -30, y: -4), CGPoint(x: -30, y: 14), CGPoint(x: -20, y: 30), CGPoint(x: 0, y: 36),
            CGPoint(x: 20, y: 30), CGPoint(x: 30, y: 14), CGPoint(x: 30, y: -4), CGPoint(x: 22, y: -4),
            CGPoint(x: 22, y: 10), CGPoint(x: -22, y: 10), CGPoint(x: -22, y: -4),
        ], fill: GamePalette.armor)
        let crest = ShapeFactory.polygon([CGPoint(x: -4, y: 34), CGPoint(x: 0, y: 52), CGPoint(x: 6, y: 34)], fill: GamePalette.guardCloth)
        visor.path = CGPath(roundedRect: CGRect(x: -16, y: 2, width: 32, height: 6), cornerWidth: 3, cornerHeight: 3, transform: nil)
        visor.fillColor = GamePalette.pupil
        visor.strokeColor = .clear
        // Eyes peek through the visor.
        let eyeL = ShapeFactory.circle(radius: 2.2, fill: .white)
        eyeL.position = CGPoint(x: -7, y: 5)
        let eyeR = ShapeFactory.circle(radius: 2.2, fill: .white)
        eyeR.position = CGPoint(x: 7, y: 5)
        let brow = ShapeFactory.line(from: CGPoint(x: -14, y: 11), to: CGPoint(x: -3, y: 9), color: GamePalette.armorDark, width: 3)
        let brow2 = ShapeFactory.line(from: CGPoint(x: 3, y: 9), to: CGPoint(x: 14, y: 11), color: GamePalette.armorDark, width: 3)
        let moustache = ShapeFactory.ellipse(size: CGSize(width: 20, height: 6), fill: GamePalette.hair)
        moustache.position = CGPoint(x: 0, y: -8)
        head.addChild(face)
        head.addChild(helmet)
        head.addChild(crest)
        head.addChild(visor)
        head.addChild(eyeL)
        head.addChild(eyeR)
        head.addChild(brow)
        head.addChild(brow2)
        head.addChild(moustache)
    }

    // MARK: - Behaviour

    /// Slow sway with the lantern while waiting.
    func patrol() {
        startIdle()
        let swing = SKAction.sequence([.rotate(toAngle: 0.18, duration: 0.9), .rotate(toAngle: -0.18, duration: 0.9)])
        swing.timingMode = .easeInEaseOut
        leftArm.run(.repeatForever(swing), withKey: "lantern")
    }

    /// Advances toward `x` with a determined stomp.
    func approach(to x: CGFloat, duration: TimeInterval, completion: @escaping () -> Void) {
        leftArm.removeAction(forKey: "lantern")
        face(x - position.x)
        startWalking(stride: 0.5, cycle: 0.38)
        let lean = SKAction.rotate(toAngle: -0.12 * facing, duration: 0.15)
        body.run(lean)
        let move = SKAction.moveTo(x: x, duration: duration)
        move.timingMode = .easeInEaseOut
        run(.sequence([move, .run { [weak self] in
            self?.stopWalking()
            self?.body.run(.rotate(toAngle: 0, duration: 0.15))
            self?.patrol()
            completion()
        }]), withKey: "approach")
    }

    /// Head tilt and question mark when the hero slips away.
    func confused() {
        let tilt = SKAction.sequence([.rotate(toAngle: -0.25, duration: 0.25), .wait(forDuration: 0.5), .rotate(toAngle: 0, duration: 0.25)])
        tilt.timingMode = .easeInEaseOut
        head.run(tilt, withKey: CharacterNode.reactionKey)
        showBubble("?", color: GamePalette.armorDark, duration: 1.0)
    }

    /// Red flash, shake and exclamation mark when the hero makes a mistake.
    func angry() {
        angryTint.run(.sequence([.fadeAlpha(to: 0.45, duration: 0.08), .fadeAlpha(to: 0, duration: 0.4)]))
        let shake = SKAction.sequence([.moveBy(x: 0, y: 8, duration: 0.06), .moveBy(x: 0, y: -8, duration: 0.06)])
        head.run(.repeat(shake, count: 3), withKey: CharacterNode.reactionKey)
        showBubble("!", color: GamePalette.danger, duration: 0.9)
    }

    /// Lunges at the hero and grabs him.
    func lunge(to x: CGFloat, duration: TimeInterval, completion: @escaping () -> Void) {
        leftArm.removeAction(forKey: "lantern")
        stopIdle()
        face(x - position.x)
        startWalking(stride: 0.7, cycle: 0.26)
        let move = SKAction.moveTo(x: x, duration: duration)
        move.timingMode = .easeIn
        let grab = SKAction.run { [weak self] in
            self?.stopWalking()
            self?.rightArm.run(.rotate(toAngle: -1.6, duration: 0.12))
            self?.leftArm.run(.rotate(toAngle: 1.6, duration: 0.12))
        }
        run(.sequence([move, grab, .wait(forDuration: 0.25), .run(completion)]), withKey: "lunge")
    }

    func restorePose() {
        removeAllActions()
        body.removeAllActions()
        body.zRotation = 0
        body.setScale(1)
        body.xScale = facing
        resetLimbs()
        patrol()
    }
}
