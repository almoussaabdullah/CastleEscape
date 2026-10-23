import SpriteKit

/// The young adventurer: brown hair, blue tunic, red scarf, brown boots, small backpack.
/// Drawn from vector shapes so every animation is procedural and resolution independent.
final class HeroNode: CharacterNode {
    private let leftEye = SKNode()
    private let rightEye = SKNode()
    private let mouth = SKShapeNode()
    private let scarfTail = SKShapeNode()
    private let eyesGroup = SKNode()

    override var height: CGFloat { 158 }
    override var headRestY: CGFloat { 128 }

    override init() {
        super.init()
        buildLegs()
        buildTorso()
        buildArms()
        buildHead()
        startIdle()
        startScarfFlutter()
    }

    required init?(coder aDecoder: NSCoder) { nil }

    // MARK: - Construction

    private func buildLegs() {
        for (leg, x) in [(leftLeg, CGFloat(-11)), (rightLeg, CGFloat(11))] {
            leg.position = CGPoint(x: x, y: 50)
            let thigh = ShapeFactory.rect(CGRect(x: -9, y: -46, width: 18, height: 48), fill: GamePalette.tunicDark, corner: 8)
            let boot = ShapeFactory.rect(CGRect(x: -11, y: -52, width: 26, height: 16), fill: GamePalette.boots, corner: 6)
            boot.position = CGPoint(x: 1, y: 2)
            leg.addChild(thigh)
            leg.addChild(boot)
        }
    }

    private func buildTorso() {
        let backpack = ShapeFactory.rect(CGRect(x: -24, y: 56, width: 30, height: 40), fill: GamePalette.backpack, corner: 10)
        backpack.position = CGPoint(x: -14, y: 0)
        backpack.zPosition = -1
        let strap = ShapeFactory.rect(CGRect(x: -6, y: 60, width: 8, height: 40), fill: GamePalette.woodDark, corner: 3)
        strap.zPosition = 1
        let tunic = ShapeFactory.rect(CGRect(x: -22, y: 46, width: 44, height: 62), fill: GamePalette.tunic, corner: 14)
        let belt = ShapeFactory.rect(CGRect(x: -22, y: 58, width: 44, height: 8), fill: GamePalette.woodDark)
        let buckle = ShapeFactory.rect(CGRect(x: -5, y: 57, width: 10, height: 10), fill: GamePalette.flagGold, corner: 2)
        let collar = ShapeFactory.rect(CGRect(x: -16, y: 100, width: 32, height: 12), fill: GamePalette.scarf, corner: 6)
        torso.addChild(backpack)
        torso.addChild(tunic)
        torso.addChild(strap)
        torso.addChild(belt)
        torso.addChild(buckle)
        torso.addChild(collar)

        // Scarf tail flows behind the hero.
        scarfTail.path = scarfPath(wave: 0)
        scarfTail.fillColor = GamePalette.scarf
        scarfTail.strokeColor = .clear
        scarfTail.position = CGPoint(x: -14, y: 104)
        scarfTail.zPosition = -2
        torso.addChild(scarfTail)
    }

    private func scarfPath(wave: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 6))
        path.addQuadCurve(to: CGPoint(x: -34, y: -4 + wave), control: CGPoint(x: -18, y: 8 - wave))
        path.addLine(to: CGPoint(x: -30, y: -14 + wave))
        path.addQuadCurve(to: CGPoint(x: 0, y: -6), control: CGPoint(x: -14, y: -8 + wave))
        path.closeSubpath()
        return path
    }

    private func startScarfFlutter() {
        var phase: CGFloat = 0
        let flutter = SKAction.customAction(withDuration: 1_000_000) { [weak self] _, elapsed in
            guard let self = self else { return }
            phase = CGFloat(elapsed) * 6
            self.scarfTail.path = self.scarfPath(wave: sin(phase) * 5)
        }
        scarfTail.run(flutter, withKey: "flutter")
    }

    private func buildArms() {
        for (arm, x, z) in [(leftArm, CGFloat(-20), CGFloat(3)), (rightArm, CGFloat(20), CGFloat(1))] {
            arm.position = CGPoint(x: x, y: 98)
            arm.zPosition = z
            let sleeve = ShapeFactory.rect(CGRect(x: -7, y: -40, width: 14, height: 42), fill: GamePalette.tunic, corner: 7)
            let hand = ShapeFactory.circle(radius: 8, fill: GamePalette.skin)
            hand.position = CGPoint(x: 0, y: -42)
            arm.addChild(sleeve)
            arm.addChild(hand)
        }
    }

    private func buildHead() {
        head.position = CGPoint(x: 0, y: headRestY)
        let face = ShapeFactory.circle(radius: 27, fill: GamePalette.skin)
        let ear = ShapeFactory.circle(radius: 6, fill: GamePalette.skin)
        ear.position = CGPoint(x: -26, y: -2)
        // Hair: a cap plus a few tufts.
        let hairCap = ShapeFactory.polygon([
            CGPoint(x: -29, y: 4), CGPoint(x: -30, y: 18), CGPoint(x: -18, y: 32), CGPoint(x: 4, y: 36),
            CGPoint(x: 20, y: 30), CGPoint(x: 30, y: 18), CGPoint(x: 29, y: 6), CGPoint(x: 18, y: 14),
            CGPoint(x: 2, y: 18), CGPoint(x: -14, y: 14),
        ], fill: GamePalette.hair)
        let tuft = ShapeFactory.polygon([CGPoint(x: 6, y: 34), CGPoint(x: 14, y: 46), CGPoint(x: 20, y: 32)], fill: GamePalette.hair)
        let tuft2 = ShapeFactory.polygon([CGPoint(x: -12, y: 32), CGPoint(x: -10, y: 44), CGPoint(x: -2, y: 34)], fill: GamePalette.hair)

        for (eye, x) in [(leftEye, CGFloat(-9)), (rightEye, CGFloat(11))] {
            eye.position = CGPoint(x: x, y: 2)
            let white = ShapeFactory.ellipse(size: CGSize(width: 12, height: 15), fill: GamePalette.eyeWhite)
            let pupil = ShapeFactory.circle(radius: 3.5, fill: GamePalette.pupil)
            pupil.position = CGPoint(x: 1.5, y: 0)
            let shine = ShapeFactory.circle(radius: 1.2, fill: .white)
            shine.position = CGPoint(x: 2.5, y: 1.5)
            eye.addChild(white)
            eye.addChild(pupil)
            eye.addChild(shine)
            eyesGroup.addChild(eye)
        }
        let brow1 = ShapeFactory.line(from: CGPoint(x: -15, y: 13), to: CGPoint(x: -4, y: 14), color: GamePalette.hair, width: 3)
        let brow2 = ShapeFactory.line(from: CGPoint(x: 6, y: 14), to: CGPoint(x: 17, y: 13), color: GamePalette.hair, width: 3)
        mouth.path = mouthPath(smile: 1)
        mouth.strokeColor = UIColor(red: 0.55, green: 0.25, blue: 0.25, alpha: 1)
        mouth.lineWidth = 2.5
        mouth.lineCap = .round
        mouth.position = CGPoint(x: 2, y: -11)
        let blush = ShapeFactory.ellipse(size: CGSize(width: 10, height: 6), fill: UIColor(red: 1, green: 0.6, blue: 0.6, alpha: 0.5))
        blush.position = CGPoint(x: 18, y: -6)

        head.addChild(ear)
        head.addChild(face)
        head.addChild(hairCap)
        head.addChild(tuft)
        head.addChild(tuft2)
        head.addChild(eyesGroup)
        head.addChild(brow1)
        head.addChild(brow2)
        head.addChild(mouth)
        head.addChild(blush)
        startBlinking()
    }

    private func mouthPath(smile: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -8, y: 0))
        path.addQuadCurve(to: CGPoint(x: 8, y: 0), control: CGPoint(x: 0, y: -7 * smile))
        return path
    }

    private func startBlinking() {
        let blink = SKAction.sequence([
            .wait(forDuration: 2.6, withRange: 2.0),
            .scaleY(to: 0.1, duration: 0.06),
            .scaleY(to: 1, duration: 0.08),
        ])
        eyesGroup.run(.repeatForever(blink), withKey: "blink")
    }

    // MARK: - Expressions

    func setExpression(smile: CGFloat, eyeScale: CGFloat = 1) {
        mouth.path = mouthPath(smile: smile)
        eyesGroup.setScale(eyeScale)
    }

    // MARK: - Actions

    /// Hand on chin, question mark bubble.
    func think() {
        stopWalking()
        startIdle()
        setExpression(smile: 0.2)
        let raise = SKAction.rotate(toAngle: 2.4, duration: 0.35)
        raise.timingMode = .easeOut
        rightArm.run(raise, withKey: CharacterNode.reactionKey)
        let tilt = SKAction.rotate(toAngle: 0.12, duration: 0.4)
        tilt.timingMode = .easeInEaseOut
        head.run(tilt, withKey: CharacterNode.reactionKey)
        showBubble("?", color: GamePalette.tunicDark, duration: 1.4)
    }

    func celebrate() {
        stopWalking()
        stopIdle()
        setExpression(smile: 1.3, eyeScale: 1.1)
        let up = SKAction.rotate(toAngle: 2.9, duration: 0.2)
        up.timingMode = .easeOut
        leftArm.run(up, withKey: CharacterNode.reactionKey)
        rightArm.run(.rotate(toAngle: -2.9, duration: 0.2), withKey: CharacterNode.reactionKey)
        let hop = SKAction.sequence([.moveBy(x: 0, y: 26, duration: 0.18), .moveBy(x: 0, y: -26, duration: 0.16)])
        hop.timingMode = .easeOut
        body.run(.sequence([hop, hop, .run { [weak self] in
            self?.resetLimbs()
            self?.setExpression(smile: 1)
            self?.startIdle()
        }]), withKey: CharacterNode.reactionKey)
        showBubble("★", color: GamePalette.flagGold, duration: 0.9)
    }

    func surprised() {
        stopWalking()
        stopIdle()
        setExpression(smile: -0.6, eyeScale: 1.35)
        let stretch = SKAction.sequence([.scaleY(to: 1.14, duration: 0.08), .scaleY(to: 0.92, duration: 0.1), .scaleY(to: 1, duration: 0.12)])
        body.run(stretch, withKey: CharacterNode.reactionKey)
        leftArm.run(.rotate(toAngle: 1.2, duration: 0.1), withKey: CharacterNode.reactionKey)
        rightArm.run(.rotate(toAngle: -1.2, duration: 0.1), withKey: CharacterNode.reactionKey)
        showBubble("!", color: GamePalette.danger, duration: 0.9)
        run(.sequence([.wait(forDuration: 0.9), .run { [weak self] in
            self?.resetLimbs()
            self?.setExpression(smile: 1)
            self?.startIdle()
        }]), withKey: "recover")
    }

    func frightened() {
        stopWalking()
        stopIdle()
        setExpression(smile: -0.9, eyeScale: 1.4)
        let shake = SKAction.sequence([.moveBy(x: -4, y: 0, duration: 0.05), .moveBy(x: 8, y: 0, duration: 0.05), .moveBy(x: -4, y: 0, duration: 0.05)])
        body.run(.repeat(shake, count: 6), withKey: CharacterNode.reactionKey)
        leftArm.run(.rotate(toAngle: 0.9, duration: 0.1), withKey: CharacterNode.reactionKey)
        rightArm.run(.rotate(toAngle: -0.9, duration: 0.1), withKey: CharacterNode.reactionKey)
    }

    /// Jumps along an arc to `x`.
    func jump(to x: CGFloat, height: CGFloat = 110, duration: TimeInterval = 0.62, completion: @escaping () -> Void) {
        stopWalking()
        stopIdle()
        face(x - position.x)
        setExpression(smile: 0.6, eyeScale: 1.15)
        let path = CGMutablePath()
        path.move(to: position)
        path.addQuadCurve(to: CGPoint(x: x, y: position.y), control: CGPoint(x: (position.x + x) / 2, y: position.y + height * 2))
        let crouch = SKAction.scaleY(to: 0.8, duration: 0.1)
        let launch = SKAction.scaleY(to: 1.08, duration: 0.08)
        let tuck = SKAction.run { [weak self] in
            self?.leftLeg.run(.rotate(toAngle: 0.9, duration: 0.15))
            self?.rightLeg.run(.rotate(toAngle: -0.5, duration: 0.15))
            self?.leftArm.run(.rotate(toAngle: 2.2, duration: 0.15))
            self?.rightArm.run(.rotate(toAngle: -1.4, duration: 0.15))
        }
        let follow = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        follow.timingMode = .easeOut
        let land = SKAction.sequence([.scaleY(to: 0.82, duration: 0.07), .scaleY(to: 1, duration: 0.12)])
        run(.sequence([.group([crouch, .wait(forDuration: 0.1)]), launch, tuck, follow, land, .run { [weak self] in
            self?.resetLimbs()
            self?.setExpression(smile: 1)
            self?.startIdle()
            completion()
        }]), withKey: "jump")
    }

    /// Quick duck used when passing under a pendulum.
    func duck(duration: TimeInterval) {
        body.run(.sequence([.scaleY(to: 0.62, duration: 0.12), .wait(forDuration: duration), .scaleY(to: 1, duration: 0.15)]), withKey: "duck")
    }

    /// Reaches forward to push a door or lever.
    func reach(duration: TimeInterval = 0.5) {
        let out = SKAction.rotate(toAngle: -1.4, duration: 0.18)
        out.timingMode = .easeOut
        rightArm.run(.sequence([out, .wait(forDuration: duration), .rotate(toAngle: 0, duration: 0.2)]), withKey: CharacterNode.reactionKey)
    }

    /// Walks down the staircase behind the exit door: moves down-right while shrinking.
    func descendStairs(dx: CGFloat, dy: CGFloat, duration: TimeInterval, completion: @escaping () -> Void) {
        face(1)
        startWalking(stride: 0.45, cycle: 0.5)
        let move = SKAction.moveBy(x: dx, y: dy, duration: duration)
        move.timingMode = .easeIn
        let shrink = SKAction.scale(to: 0.82, duration: duration)
        let fade = SKAction.sequence([.wait(forDuration: duration * 0.55), .fadeAlpha(to: 0, duration: duration * 0.45)])
        run(.sequence([.group([move, shrink, fade]), .run { [weak self] in
            self?.stopWalking()
            completion()
        }]), withKey: "descend")
    }

    /// Resets any temporary transform after a cinematic.
    func restorePose() {
        removeAllActions()
        body.removeAllActions()
        alpha = 1
        setScale(1)
        body.setScale(1)
        body.xScale = facing
        resetLimbs()
        setExpression(smile: 1)
        startIdle()
    }

    /// Victory run across the bridge, legs flying.
    func sprint(to x: CGFloat, duration: TimeInterval, completion: @escaping () -> Void) {
        face(x - position.x)
        startWalking(stride: 0.9, cycle: 0.3)
        setExpression(smile: 1.3, eyeScale: 1.1)
        let move = SKAction.moveTo(x: x, duration: duration)
        move.timingMode = .easeIn
        run(.sequence([move, .run { [weak self] in
            self?.stopWalking()
            self?.startIdle()
            completion()
        }]), withKey: "sprint")
    }
}
