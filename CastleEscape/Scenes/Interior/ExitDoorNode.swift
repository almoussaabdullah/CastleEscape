import SpriteKit

/// The staircase door at the end of each corridor. Opens to reveal steps going down.
final class ExitDoorNode: SKNode {
    private let leaf = SKNode()
    private let stairwell = SKNode()
    private let lockGlow: SKSpriteNode
    private(set) var isOpen = false

    override init() {
        lockGlow = ShapeFactory.glow(radius: 140, color: GamePalette.success, alpha: 0)
        super.init()
        let width = CastleLayout.doorWidth
        let height = CastleLayout.doorHeight
        // Stone frame.
        let frame = ShapeFactory.arch(width: width + 36, height: height + 18, fill: GamePalette.stoneLight)
        frame.zPosition = 1
        addChild(frame)
        let keystone = ShapeFactory.polygon([CGPoint(x: -18, y: height + 10), CGPoint(x: 18, y: height + 10), CGPoint(x: 12, y: height + 44), CGPoint(x: -12, y: height + 44)], fill: GamePalette.stoneLight)
        keystone.zPosition = 1
        addChild(keystone)
        // Stairwell behind the door: dark opening with descending steps.
        let opening = ShapeFactory.arch(width: width, height: height, fill: UIColor(red: 0.04, green: 0.04, blue: 0.09, alpha: 1))
        opening.zPosition = 1.5
        stairwell.addChild(opening)
        var stepY: CGFloat = 0
        var stepX: CGFloat = -width / 2 + 10
        for i in 0..<6 {
            let step = ShapeFactory.rect(CGRect(x: stepX, y: stepY - CGFloat(i) * 18, width: width - 20 - CGFloat(i) * 8, height: 12), fill: GamePalette.stoneDark.withAlphaComponent(1 - CGFloat(i) * 0.12))
            step.zPosition = 1.6
            stairwell.addChild(step)
            stepX += 6
            stepY -= 2
        }
        let lantern = ShapeFactory.glow(radius: 90, color: GamePalette.torch, alpha: 0.5)
        lantern.position = CGPoint(x: 20, y: 120)
        lantern.zPosition = 1.7
        stairwell.addChild(lantern)
        stairwell.zPosition = 1.5
        addChild(stairwell)
        // Door leaf hinged on the left.
        leaf.position = CGPoint(x: -width / 2, y: 0)
        let wood = TiledTextureNode(rect: CGRect(x: 0, y: 0, width: width, height: height - 30), textureName: "wood_tile", tileSize: 120)
        let archTop = ShapeFactory.arch(width: width, height: height, fill: GamePalette.wood)
        archTop.position = CGPoint(x: width / 2, y: 0)
        archTop.zPosition = -0.1
        let band1 = ShapeFactory.rect(CGRect(x: 0, y: 46, width: width, height: 12), fill: GamePalette.iron)
        let band2 = ShapeFactory.rect(CGRect(x: 0, y: 140, width: width, height: 12), fill: GamePalette.iron)
        let handle = ShapeFactory.circle(radius: 8, fill: GamePalette.flagGold)
        handle.position = CGPoint(x: width - 26, y: 100)
        let lock = ShapeFactory.rect(CGRect(x: width - 40, y: 70, width: 28, height: 22), fill: GamePalette.ironLight, corner: 4)
        lock.name = "lockPlate"
        leaf.addChild(archTop)
        leaf.addChild(wood)
        leaf.addChild(band1)
        leaf.addChild(band2)
        leaf.addChild(lock)
        leaf.addChild(handle)
        leaf.zPosition = 2
        addChild(leaf)
        // Sign above the door.
        let sign = ShapeFactory.rect(CGRect(x: -40, y: height + 50, width: 80, height: 30), fill: GamePalette.woodDark, corner: 5)
        sign.zPosition = 2
        addChild(sign)
        let arrow = SKLabelNode(text: "⬇")
        arrow.fontName = "AvenirNext-Bold"
        arrow.fontSize = 22
        arrow.fontColor = GamePalette.torchCore
        arrow.verticalAlignmentMode = .center
        arrow.position = CGPoint(x: 0, y: height + 65)
        arrow.zPosition = 2.1
        addChild(arrow)
        lockGlow.position = CGPoint(x: 0, y: height / 2)
        lockGlow.zPosition = 0.5
        addChild(lockGlow)
    }

    required init?(coder aDecoder: NSCoder) { nil }

    /// Highlights the door once all encounters are solved.
    func unlock() {
        lockGlow.run(.fadeAlpha(to: 0.8, duration: 0.4))
        let pulse = SKAction.sequence([.scale(to: 1.2, duration: 0.6), .scale(to: 0.9, duration: 0.6)])
        pulse.timingMode = .easeInEaseOut
        lockGlow.run(.repeatForever(pulse), withKey: "pulse")
        if let plate = leaf.childNode(withName: "lockPlate") as? SKShapeNode {
            plate.fillColor = GamePalette.success
        }
    }

    func open(duration: TimeInterval, completion: @escaping () -> Void) {
        guard !isOpen else { completion(); return }
        isOpen = true
        lockGlow.removeAllActions()
        lockGlow.run(.fadeAlpha(to: 0, duration: 0.3))
        AudioManager.shared.play(.doorCreak)
        let swing = SKAction.scaleX(to: 0.12, duration: duration)
        swing.timingMode = .easeInEaseOut
        leaf.run(.sequence([swing, .run(completion)]))
    }

    func close(duration: TimeInterval) {
        guard isOpen else { return }
        isOpen = false
        let swing = SKAction.scaleX(to: 1, duration: duration)
        swing.timingMode = .easeInEaseOut
        leaf.run(swing)
    }
}
