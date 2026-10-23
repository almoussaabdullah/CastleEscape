import SpriteKit

/// Shared behaviour for procedurally drawn characters: limb containers, walking cycle,
/// facing direction and speech-bubble style reactions.
class CharacterNode: SKNode {
    static let walkKey = "walk"
    static let idleKey = "idle"
    static let reactionKey = "reaction"

    /// Everything that should flip when the character turns around.
    let body = SKNode()
    let leftLeg = SKNode()
    let rightLeg = SKNode()
    let leftArm = SKNode()
    let rightArm = SKNode()
    let head = SKNode()
    let torso = SKNode()

    /// Horizontal facing (1 = right, -1 = left).
    private(set) var facing: CGFloat = 1

    /// Height from the feet to the top of the head, used by cameras and bubbles.
    var height: CGFloat { 150 }

    override init() {
        super.init()
        addChild(body)
        body.addChild(leftLeg)
        body.addChild(rightLeg)
        body.addChild(torso)
        body.addChild(leftArm)
        body.addChild(rightArm)
        body.addChild(head)
        leftLeg.zPosition = 1
        rightLeg.zPosition = 0
        torso.zPosition = 2
        leftArm.zPosition = 3
        rightArm.zPosition = 1
        head.zPosition = 4
    }

    required init?(coder aDecoder: NSCoder) { nil }

    func face(_ direction: CGFloat) {
        let sign: CGFloat = direction < 0 ? -1 : 1
        guard sign != facing else { return }
        facing = sign
        body.xScale = sign
    }

    // MARK: - Shared animations

    /// Gentle breathing bob used while standing.
    func startIdle() {
        body.removeAction(forKey: CharacterNode.walkKey)
        resetLimbs()
        let up = SKAction.moveBy(x: 0, y: 3, duration: 0.9)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        body.run(.repeatForever(.sequence([up, down])), withKey: CharacterNode.idleKey)
    }

    func stopIdle() {
        body.removeAction(forKey: CharacterNode.idleKey)
        body.position = .zero
    }

    /// Walking/running cycle: legs and arms swing in opposition while the body bobs.
    func startWalking(stride: CGFloat = 0.55, cycle: TimeInterval = 0.42) {
        stopIdle()
        guard body.action(forKey: CharacterNode.walkKey) == nil else { return }
        let half = cycle / 2
        let legForward = SKAction.rotate(toAngle: -stride, duration: half)
        legForward.timingMode = .easeInEaseOut
        let legBack = SKAction.rotate(toAngle: stride, duration: half)
        legBack.timingMode = .easeInEaseOut
        leftLeg.run(.repeatForever(.sequence([legForward, legBack])), withKey: CharacterNode.walkKey)
        rightLeg.run(.repeatForever(.sequence([legBack, legForward])), withKey: CharacterNode.walkKey)
        leftArm.run(.repeatForever(.sequence([legBack, legForward])), withKey: CharacterNode.walkKey)
        rightArm.run(.repeatForever(.sequence([legForward, legBack])), withKey: CharacterNode.walkKey)
        let bobUp = SKAction.moveBy(x: 0, y: 5, duration: half / 2)
        bobUp.timingMode = .easeOut
        let bobDown = bobUp.reversed()
        bobDown.timingMode = .easeIn
        body.run(.repeatForever(.sequence([bobUp, bobDown, bobUp, bobDown])), withKey: CharacterNode.walkKey)
    }

    func stopWalking() {
        for limb in [leftLeg, rightLeg, leftArm, rightArm] { limb.removeAction(forKey: CharacterNode.walkKey) }
        body.removeAction(forKey: CharacterNode.walkKey)
        resetLimbs()
        body.position = .zero
    }

    func resetLimbs() {
        for limb in [leftLeg, rightLeg, leftArm, rightArm] {
            limb.removeAllActions()
            limb.zRotation = 0
        }
        head.removeAllActions()
        head.zRotation = 0
        head.position = CGPoint(x: head.position.x, y: headRestY)
    }

    /// Subclasses set where the head rests.
    var headRestY: CGFloat { 0 }

    /// Walks to `x` at `speed` points per second and runs `completion` on arrival.
    func walk(to x: CGFloat, speed: CGFloat, completion: (() -> Void)? = nil) {
        let distance = abs(x - position.x)
        guard distance > 0.5 else { completion?(); return }
        face(x - position.x)
        startWalking()
        let move = SKAction.moveTo(x: x, duration: TimeInterval(distance / max(1, speed)))
        run(.sequence([move, .run { [weak self] in
            self?.stopWalking()
            self?.startIdle()
            completion?()
        }]), withKey: "walkTo")
    }

    // MARK: - Speech bubble

    /// Shows a short glyph above the head ("?", "!", "♥"...).
    func showBubble(_ text: String, color: UIColor = .white, duration: TimeInterval = 1.2) {
        childNode(withName: "bubble")?.removeFromParent()
        let bubble = SKNode()
        bubble.name = "bubble"
        bubble.position = CGPoint(x: 26, y: height + 24)
        bubble.zPosition = 20
        let back = ShapeFactory.rect(size: CGSize(width: 44, height: 40), fill: UIColor.white.withAlphaComponent(0.95), corner: 12)
        let tail = ShapeFactory.polygon([CGPoint(x: -10, y: -20), CGPoint(x: 2, y: -20), CGPoint(x: -14, y: -32)], fill: UIColor.white.withAlphaComponent(0.95))
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 26
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        bubble.addChild(back)
        bubble.addChild(tail)
        bubble.addChild(label)
        bubble.setScale(0.2)
        addChild(bubble)
        let pop = SKAction.scale(to: 1, duration: 0.18)
        pop.timingMode = .easeOut
        bubble.run(.sequence([pop, .wait(forDuration: duration), .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }
}
