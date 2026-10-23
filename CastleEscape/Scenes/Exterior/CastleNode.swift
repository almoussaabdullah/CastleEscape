import SpriteKit

/// The exterior of the castle: rock plateau, ten-floor keep, side towers, turrets, gate and
/// the stone bridge. Floor windows report progress (locked / current / completed).
final class CastleNode: SKNode {
    private(set) var floorWindows: [Int: FloorWindowNode] = [:]
    private var portcullis: SKNode?
    private var gateDoors: [SKNode] = []

    override init() {
        super.init()
        buildRock()
        buildBridge()
        buildSideTowers()
        buildKeep()
        buildGate()
        buildTurrets()
        buildTorches()
    }

    required init?(coder aDecoder: NSCoder) { nil }

    // MARK: - Rock & bridge

    private func buildRock() {
        let bottom = CastleLayout.rockBottomY
        let rock = ShapeFactory.polygon([
            CGPoint(x: -1_420, y: -120), CGPoint(x: -1_380, y: -40), CGPoint(x: 1_420, y: -40),
            CGPoint(x: 1_560, y: -260), CGPoint(x: 1_760, y: -640), CGPoint(x: 1_900, y: bottom),
            CGPoint(x: -1_460, y: bottom), CGPoint(x: -1_480, y: -560), CGPoint(x: -1_420, y: -300),
        ], fill: GamePalette.rock)
        rock.zPosition = -4
        addChild(rock)
        let rockShade = ShapeFactory.polygon([
            CGPoint(x: -1_460, y: -760), CGPoint(x: -1_300, y: -520), CGPoint(x: -700, y: -620),
            CGPoint(x: 100, y: -500), CGPoint(x: 900, y: -640), CGPoint(x: 1_700, y: -560), CGPoint(x: 1_900, y: bottom),
            CGPoint(x: -1_460, y: bottom),
        ], fill: GamePalette.rockDark)
        rockShade.zPosition = -3
        addChild(rockShade)
        // Trees along the cliff edge.
        for x in stride(from: CGFloat(-1_400), through: 1_800, by: 160) {
            guard x < -1_380 || x > 1_430 else { continue }
            let h = CGFloat.random(in: 140...260)
            let base = x < 0 ? CGFloat(-120) : CGFloat(-240) - (x - 1_430) * 0.5
            let tree = ShapeFactory.polygon([CGPoint(x: x - 60, y: base), CGPoint(x: x + 60, y: base), CGPoint(x: x, y: base + h)], fill: GamePalette.forest)
            tree.zPosition = -2
            addChild(tree)
        }
    }

    private func buildBridge() {
        let deckTop: CGFloat = 10
        let leftEnd = CastleLayout.bridgeEndX
        let rightEnd: CGFloat = -(CastleLayout.sideTowerX + CastleLayout.sideTowerHalfWidth) + 40
        let bottom = CastleLayout.rockBottomY
        // Far cliff the bridge lands on.
        let cliff = ShapeFactory.polygon([
            CGPoint(x: leftEnd - 1_600, y: bottom), CGPoint(x: leftEnd - 1_200, y: -140), CGPoint(x: leftEnd - 400, y: -30),
            CGPoint(x: leftEnd + 60, y: -30), CGPoint(x: leftEnd + 120, y: -400), CGPoint(x: leftEnd - 100, y: bottom),
        ], fill: GamePalette.rock)
        cliff.zPosition = -4
        addChild(cliff)
        for x in stride(from: leftEnd - 1_100, through: leftEnd - 100, by: 140) {
            let h = CGFloat.random(in: 160...280)
            let tree = ShapeFactory.polygon([CGPoint(x: x - 60, y: -60), CGPoint(x: x + 60, y: -60), CGPoint(x: x, y: -60 + h)], fill: GamePalette.forest)
            tree.zPosition = -2
            addChild(tree)
        }
        // Arches.
        let pierColor = GamePalette.stoneDark
        let span = (rightEnd - leftEnd) / 3
        for i in 0..<3 {
            let x0 = leftEnd + CGFloat(i) * span
            let pier = ShapeFactory.rect(CGRect(x: x0 - 40, y: -720, width: 80, height: 700), fill: pierColor)
            pier.zPosition = -1
            addChild(pier)
            let arch = SKShapeNode(path: {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x0, y: -720))
                path.addLine(to: CGPoint(x: x0, y: -200))
                path.addArc(center: CGPoint(x: x0 + span / 2, y: -200), radius: span / 2, startAngle: .pi, endAngle: 0, clockwise: true)
                path.addLine(to: CGPoint(x: x0 + span, y: -720))
                path.closeSubpath()
                return path
            }())
            arch.fillColor = GamePalette.stoneDark
            arch.strokeColor = .clear
            arch.zPosition = -1
            addChild(arch)
            let hollow = SKShapeNode(path: {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x0 + 50, y: -720))
                path.addLine(to: CGPoint(x: x0 + 50, y: -220))
                path.addArc(center: CGPoint(x: x0 + span / 2, y: -220), radius: span / 2 - 50, startAngle: .pi, endAngle: 0, clockwise: true)
                path.addLine(to: CGPoint(x: x0 + span - 50, y: -720))
                path.closeSubpath()
                return path
            }())
            hollow.fillColor = GamePalette.nightTop
            hollow.strokeColor = .clear
            hollow.zPosition = -0.5
            addChild(hollow)
        }
        let lastPier = ShapeFactory.rect(CGRect(x: rightEnd - 40, y: -720, width: 80, height: 700), fill: pierColor)
        lastPier.zPosition = -1
        addChild(lastPier)
        // Deck and parapet.
        let deck = TiledTextureNode(rect: CGRect(x: leftEnd, y: deckTop - 70, width: rightEnd - leftEnd, height: 70), textureName: "stone_tile", tileSize: 160)
        deck.zPosition = 0
        addChild(deck)
        let parapet = ShapeFactory.crenellations(from: leftEnd, to: rightEnd, y: deckTop, fill: GamePalette.stone, merlonWidth: 50, height: 34)
        parapet.zPosition = 0.5
        addChild(parapet)
        let lip = ShapeFactory.rect(CGRect(x: leftEnd, y: deckTop - 4, width: rightEnd - leftEnd, height: 8), fill: GamePalette.stoneLight)
        lip.zPosition = 0.6
        addChild(lip)
    }

    // MARK: - Towers and keep

    private func buildSideTowers() {
        for sign in [CGFloat(-1), CGFloat(1)] {
            let x = CastleLayout.sideTowerX * sign
            let half = CastleLayout.sideTowerHalfWidth
            let top = CastleLayout.floorBaseY(CastleLayout.sideTowerTopFloor)
            let wall = TiledTextureNode(rect: CGRect(x: x - half, y: -120, width: half * 2, height: top + 120), textureName: "stone_tile", tileSize: 260,
                                        tint: GamePalette.stoneShadow, tintStrength: 0.25)
            wall.zPosition = 1
            addChild(wall)
            // Shadow stripe to give the tower roundness.
            let shade = ShapeFactory.rect(CGRect(x: x + half * 0.35 * sign - (sign > 0 ? 0 : half * 0.3), y: -120, width: half * 0.3, height: top + 120), fill: GamePalette.stoneShadow.withAlphaComponent(0.4))
            shade.zPosition = 1.2
            addChild(shade)
            let ledge = ShapeFactory.rect(CGRect(x: x - half - 24, y: top, width: half * 2 + 48, height: 40), fill: GamePalette.stoneLight)
            ledge.zPosition = 1.3
            addChild(ledge)
            let roof = ShapeFactory.polygon([
                CGPoint(x: x - half - 36, y: top + 40), CGPoint(x: x + half + 36, y: top + 40), CGPoint(x: x, y: top + 40 + CastleLayout.roofHeight),
            ], fill: GamePalette.roof)
            roof.zPosition = 1.4
            addChild(roof)
            let roofShade = ShapeFactory.polygon([
                CGPoint(x: x, y: top + 40), CGPoint(x: x + (half + 36) * sign, y: top + 40), CGPoint(x: x, y: top + 40 + CastleLayout.roofHeight),
            ], fill: GamePalette.roofDark)
            roofShade.zPosition = 1.5
            addChild(roofShade)
            let flag = FlagNode(color: GamePalette.flag)
            flag.position = CGPoint(x: x, y: top + 40 + CastleLayout.roofHeight - 10)
            flag.zPosition = 1.6
            addChild(flag)
            // Decorative windows up the tower.
            var y: CGFloat = 420
            var index = 0
            while y < top - 200 {
                let window = DecorWindowNode(lit: index % 3 != 1)
                window.position = CGPoint(x: x + (index % 2 == 0 ? -40 : 40) * sign, y: y)
                window.zPosition = 1.7
                addChild(window)
                y += 560
                index += 1
            }
            // Short curtain wall linking tower and keep.
            let innerEdge = x - half * sign
            let keepEdge = CastleLayout.keepHalfWidth * sign
            let minX = min(innerEdge, keepEdge)
            let curtain = TiledTextureNode(rect: CGRect(x: minX, y: -120, width: abs(innerEdge - keepEdge) + 2, height: 1_040), textureName: "stone_tile_dark", tileSize: 220)
            curtain.zPosition = 0.8
            addChild(curtain)
            let battlement = ShapeFactory.crenellations(from: minX, to: minX + abs(innerEdge - keepEdge), y: 920, fill: GamePalette.stoneDark, merlonWidth: 36, height: 50)
            battlement.zPosition = 0.9
            addChild(battlement)
        }
    }

    private func buildKeep() {
        let half = CastleLayout.keepHalfWidth
        let top = CastleLayout.keepTopY
        let wall = TiledTextureNode(rect: CGRect(x: -half, y: -120, width: half * 2, height: top + 120), textureName: "stone_tile", tileSize: 260)
        wall.zPosition = 2
        addChild(wall)
        // Subtle vertical shading on the right edge.
        let shade = ShapeFactory.rect(CGRect(x: half - 160, y: -120, width: 160, height: top + 120), fill: GamePalette.stoneShadow.withAlphaComponent(0.35))
        shade.zPosition = 2.1
        addChild(shade)
        // Buttresses.
        for x in [-half + 20, half - 60] {
            let buttress = ShapeFactory.rect(CGRect(x: x, y: -120, width: 40, height: top + 120), fill: GamePalette.stoneDark.withAlphaComponent(0.6))
            buttress.zPosition = 2.2
            addChild(buttress)
        }
        for floor in 1...CastleLayout.floorCount {
            let base = CastleLayout.floorBaseY(floor)
            // Ledge marking each floor.
            let ledge = ShapeFactory.rect(CGRect(x: -half, y: base - 10, width: half * 2, height: 16), fill: GamePalette.stoneDark.withAlphaComponent(0.7))
            ledge.zPosition = 2.3
            addChild(ledge)
            let ledgeLight = ShapeFactory.rect(CGRect(x: -half, y: base + 6, width: half * 2, height: 6), fill: GamePalette.stoneLight.withAlphaComponent(0.5))
            ledgeLight.zPosition = 2.3
            addChild(ledgeLight)
            // Main window.
            let window = FloorWindowNode(floor: floor)
            window.position = CastleLayout.windowWorldPosition(floor: floor)
            window.zPosition = 2.5
            addChild(window)
            floorWindows[floor] = window
            // Decorative windows.
            if floor > 1 {
                for (i, x) in [CGFloat(40), CGFloat(420)].enumerated() {
                    let lit = (floor + i) % 3 == 0
                    let decor = DecorWindowNode(lit: lit)
                    decor.position = CGPoint(x: x, y: base + 270)
                    decor.zPosition = 2.4
                    addChild(decor)
                }
            }
        }
        // Battlements along the top of the keep.
        let battlements = ShapeFactory.crenellations(from: -half - 30, to: half + 30, y: top, fill: GamePalette.stone, merlonWidth: 64, height: 76)
        battlements.zPosition = 2.6
        addChild(battlements)
        let coping = ShapeFactory.rect(CGRect(x: -half - 30, y: top - 24, width: half * 2 + 60, height: 30), fill: GamePalette.stoneLight)
        coping.zPosition = 2.6
        addChild(coping)
    }

    private func buildTurrets() {
        let keepTop = CastleLayout.keepTopY
        // Central turret: the prison tower above floor 10.
        let half = CastleLayout.turretHalfWidth
        let turretTop = CastleLayout.turretTopY
        let turret = TiledTextureNode(rect: CGRect(x: -half, y: keepTop, width: half * 2, height: CastleLayout.turretHeight), textureName: "stone_tile_dark", tileSize: 220)
        turret.zPosition = 3
        addChild(turret)
        let turretWindow = DecorWindowNode(width: 60, height: 100, lit: true)
        turretWindow.position = CGPoint(x: 0, y: keepTop + 300)
        turretWindow.zPosition = 3.2
        addChild(turretWindow)
        let ledge = ShapeFactory.rect(CGRect(x: -half - 30, y: turretTop, width: half * 2 + 60, height: 44), fill: GamePalette.stoneLight)
        ledge.zPosition = 3.3
        addChild(ledge)
        let roof = ShapeFactory.polygon([
            CGPoint(x: -half - 50, y: turretTop + 44), CGPoint(x: half + 50, y: turretTop + 44), CGPoint(x: 0, y: turretTop + 44 + CastleLayout.roofHeight),
        ], fill: GamePalette.roof)
        roof.zPosition = 3.4
        addChild(roof)
        let roofShade = ShapeFactory.polygon([
            CGPoint(x: 0, y: turretTop + 44), CGPoint(x: half + 50, y: turretTop + 44), CGPoint(x: 0, y: turretTop + 44 + CastleLayout.roofHeight),
        ], fill: GamePalette.roofDark)
        roofShade.zPosition = 3.5
        addChild(roofShade)
        let flag = FlagNode(color: GamePalette.flagGold, length: 150, height: 80, poleHeight: 200)
        flag.position = CGPoint(x: 0, y: turretTop + 44 + CastleLayout.roofHeight - 12)
        flag.zPosition = 3.6
        addChild(flag)

        // Corner turrets.
        for sign in [CGFloat(-1), CGFloat(1)] {
            let x = (CastleLayout.keepHalfWidth - 90) * sign
            let w: CGFloat = 120
            let body = TiledTextureNode(rect: CGRect(x: x - w / 2, y: keepTop - 300, width: w, height: 540), textureName: "stone_tile_dark", tileSize: 200)
            body.zPosition = 2.9
            addChild(body)
            let cap = ShapeFactory.polygon([CGPoint(x: x - w / 2 - 20, y: keepTop + 240), CGPoint(x: x + w / 2 + 20, y: keepTop + 240), CGPoint(x: x, y: keepTop + 480)], fill: GamePalette.roof)
            cap.zPosition = 3
            addChild(cap)
            let flag = FlagNode(color: GamePalette.flag, length: 80, height: 48, poleHeight: 120)
            flag.position = CGPoint(x: x, y: keepTop + 470)
            flag.zPosition = 3.1
            addChild(flag)
        }
    }

    // MARK: - Gate

    private func buildGate() {
        let width: CGFloat = 240
        let height: CGFloat = 330
        let frame = ShapeFactory.arch(width: width + 60, height: height + 30, fill: GamePalette.stoneLight)
        frame.position = CGPoint(x: 0, y: -40)
        frame.zPosition = 2.7
        addChild(frame)
        let opening = ShapeFactory.arch(width: width, height: height, fill: UIColor(red: 0.05, green: 0.05, blue: 0.10, alpha: 1))
        opening.position = CGPoint(x: 0, y: -40)
        opening.zPosition = 2.8
        addChild(opening)
        // Wooden doors (open during the victory cinematic).
        for sign in [CGFloat(-1), CGFloat(1)] {
            let door = SKNode()
            door.position = CGPoint(x: sign * width / 2, y: -40)
            let leaf = TiledTextureNode(rect: CGRect(x: sign < 0 ? 0 : -width / 2, y: 0, width: width / 2, height: height - 40), textureName: "wood_tile", tileSize: 120)
            door.addChild(leaf)
            let bands = ShapeFactory.rect(CGRect(x: sign < 0 ? 0 : -width / 2, y: 80, width: width / 2, height: 14), fill: GamePalette.iron)
            door.addChild(bands)
            let bands2 = ShapeFactory.rect(CGRect(x: sign < 0 ? 0 : -width / 2, y: 200, width: width / 2, height: 14), fill: GamePalette.iron)
            door.addChild(bands2)
            door.zPosition = 2.85
            addChild(door)
            gateDoors.append(door)
        }
        // Portcullis.
        let grid = SKNode()
        for x in stride(from: -width / 2 + 20, through: width / 2 - 20, by: 40) {
            grid.addChild(ShapeFactory.rect(CGRect(x: x - 6, y: 0, width: 12, height: height - 20), fill: GamePalette.iron))
        }
        for y in stride(from: CGFloat(40), through: height - 60, by: 70) {
            grid.addChild(ShapeFactory.rect(CGRect(x: -width / 2, y: y, width: width, height: 12), fill: GamePalette.ironLight))
        }
        grid.position = CGPoint(x: 0, y: -40)
        grid.zPosition = 2.9
        addChild(grid)
        portcullis = grid
        // Crest above the gate.
        let crest = ShapeFactory.polygon([CGPoint(x: -40, y: 360), CGPoint(x: 40, y: 360), CGPoint(x: 40, y: 310), CGPoint(x: 0, y: 270), CGPoint(x: -40, y: 310)], fill: GamePalette.shieldRed, stroke: GamePalette.flagGold, lineWidth: 6)
        crest.zPosition = 2.9
        addChild(crest)
        let crestStar = SKLabelNode(text: "★")
        crestStar.fontName = "AvenirNext-Bold"
        crestStar.fontSize = 44
        crestStar.fontColor = GamePalette.flagGold
        crestStar.verticalAlignmentMode = .center
        crestStar.position = CGPoint(x: 0, y: 320)
        crestStar.zPosition = 3
        addChild(crestStar)
        // Steps down from the gate to the ground level.
        let steps = ShapeFactory.rect(CGRect(x: -200, y: -70, width: 400, height: 34), fill: GamePalette.stone)
        steps.zPosition = 2.75
        addChild(steps)
    }

    private func buildTorches() {
        let half = CastleLayout.keepHalfWidth
        for floor in stride(from: 1, through: CastleLayout.floorCount, by: 2) {
            let y = CastleLayout.floorBaseY(floor) + 300
            for x in [-half + 90, half - 110] {
                let torch = TorchNode(scale: 2.2)
                torch.position = CGPoint(x: x, y: y)
                torch.zPosition = 4
                addChild(torch)
            }
        }
        for x in [CGFloat(-200), CGFloat(200)] {
            let torch = TorchNode(scale: 2.6, embers: true)
            torch.position = CGPoint(x: x, y: 200)
            torch.zPosition = 4
            addChild(torch)
        }
        let bridgeTorch = TorchNode(scale: 2.4)
        bridgeTorch.position = CGPoint(x: CastleLayout.bridgeEndX + 40, y: 90)
        bridgeTorch.zPosition = 4
        addChild(bridgeTorch)
    }

    // MARK: - Progress

    func apply(statuses: [Int: FloorStatus], animated: Bool) {
        for (floor, window) in floorWindows {
            window.apply(status: statuses[floor] ?? .locked, animated: animated)
        }
    }

    func window(for floor: Int) -> FloorWindowNode? { floorWindows[floor] }

    /// Raises the portcullis and swings the doors open for the escape.
    func openGate(duration: TimeInterval) {
        let rise = SKAction.moveBy(x: 0, y: 300, duration: duration)
        rise.timingMode = .easeInEaseOut
        portcullis?.run(rise)
        for (i, door) in gateDoors.enumerated() {
            let sign: CGFloat = i == 0 ? -1 : 1
            let swing = SKAction.scaleX(to: 0.08, duration: duration * 0.8)
            swing.timingMode = .easeInEaseOut
            door.run(.sequence([.wait(forDuration: duration * 0.3), swing, .run { door.xScale = 0.08 * sign }]))
        }
    }

    func closeGate() {
        portcullis?.position = CGPoint(x: 0, y: -40)
        for door in gateDoors { door.xScale = 1 }
    }
}
