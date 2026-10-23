import SpriteKit

/// Builds the themed set dressing of each floor from reusable props.
/// Floors 10 and 9 are the most detailed; the others share props with theme-specific tints.
enum FloorThemeDecorator {
    static func decorate(_ root: SKNode, theme: FloorTheme, obstaclePositions: [CGFloat]) {
        let layer = SKNode()
        layer.zPosition = 1   // behind characters (characters are z >= 10)
        root.addChild(layer)

        switch theme {
        case .prisonTower: prison(layer)
        case .guardBarracks: barracks(layer)
        case .ancientLibrary: library(layer)
        case .clockTower: clockTower(layer)
        case .alchemistLab: alchemistLab(layer)
        case .mirrorHall: mirrorHall(layer)
        case .secretCorridors: secretCorridors(layer)
        case .armory: armory(layer)
        case .throneRoom: throneRoom(layer)
        case .mainGate: mainGate(layer)
        }
    }

    // MARK: - Themes

    private static func prison(_ layer: SKNode) {
        // Cell bars around the hero's starting corner.
        let cellBars = SKNode()
        for x in stride(from: CGFloat(-310), through: -250, by: 30) {
            cellBars.addChild(ShapeFactory.rect(CGRect(x: x - 4, y: 0, width: 8, height: 300), fill: GamePalette.iron, corner: 3))
        }
        cellBars.addChild(ShapeFactory.rect(CGRect(x: -318, y: 292, width: 76, height: 10), fill: GamePalette.ironLight))
        cellBars.alpha = 0.9
        layer.addChild(cellBars)
        layer.addChild(place(straw(), x: -700, y: 0))
        layer.addChild(place(bench(), x: -620, y: 0))
        layer.addChild(place(chain(length: 160), x: -380, y: CastleLayout.roomHeight - 10))
        layer.addChild(place(chain(length: 120), x: 120, y: CastleLayout.roomHeight - 10))
        layer.addChild(place(bucket(), x: -200, y: 0))
        layer.addChild(place(cobweb(), x: -CastleLayout.keepHalfWidth + 40, y: CastleLayout.roomHeight - 30))
        layer.addChild(place(cobweb(), x: 400, y: CastleLayout.roomHeight - 30))
        layer.addChild(place(wallRing(), x: 250, y: 300))
        layer.addChild(place(wallRing(), x: 460, y: 320))
        layer.addChild(place(tallyMarks(), x: -560, y: 260))
    }

    private static func barracks(_ layer: SKNode) {
        layer.addChild(place(bunkBed(), x: -700, y: 0))
        layer.addChild(place(bunkBed(), x: -480, y: 0))
        layer.addChild(place(shieldOnWall(color: GamePalette.shieldRed), x: -150, y: 300))
        layer.addChild(place(shieldOnWall(color: GamePalette.tunic), x: 80, y: 300))
        layer.addChild(place(helmetShelf(), x: 260, y: 240))
        layer.addChild(place(table(width: 160), x: 0, y: 0))
        layer.addChild(place(barrel(), x: 420, y: 0))
        layer.addChild(place(barrel(), x: 470, y: 0))
        layer.addChild(place(banner(color: GamePalette.guardCloth), x: -320, y: CastleLayout.roomHeight))
        layer.addChild(place(banner(color: GamePalette.guardCloth), x: 560, y: CastleLayout.roomHeight))
        layer.addChild(place(candle(), x: -20, y: 92))
    }

    private static func library(_ layer: SKNode) {
        for x in stride(from: CGFloat(-760), through: 520, by: 230) {
            layer.addChild(place(bookshelf(width: 180, height: 360), x: x, y: 0))
        }
        layer.addChild(place(table(width: 180), x: -120, y: 0))
        layer.addChild(place(candle(), x: -160, y: 92))
        layer.addChild(place(scroll(), x: -90, y: 96))
        layer.addChild(place(cobweb(), x: 620, y: CastleLayout.roomHeight - 30))
    }

    private static func clockTower(_ layer: SKNode) {
        layer.addChild(place(gear(radius: 110, teeth: 12, color: GamePalette.flagGold, speed: 6), x: -560, y: 300))
        layer.addChild(place(gear(radius: 70, teeth: 9, color: GamePalette.ironLight, speed: -3.8), x: -400, y: 220))
        layer.addChild(place(gear(radius: 140, teeth: 14, color: GamePalette.iron, speed: 9), x: 260, y: 260))
        layer.addChild(place(gear(radius: 60, teeth: 8, color: GamePalette.flagGold, speed: -3.2), x: 440, y: 150))
        layer.addChild(place(clockFace(radius: 95), x: -100, y: 300))
        layer.addChild(place(pendulumDecor(), x: 600, y: CastleLayout.roomHeight))
    }

    private static func alchemistLab(_ layer: SKNode) {
        layer.addChild(place(table(width: 220), x: -620, y: 0))
        layer.addChild(place(flask(color: GamePalette.windowCompleted), x: -680, y: 92))
        layer.addChild(place(flask(color: GamePalette.magicPink), x: -620, y: 92))
        layer.addChild(place(flask(color: GamePalette.magic), x: -560, y: 92))
        layer.addChild(place(jarShelf(), x: -300, y: 280))
        layer.addChild(place(jarShelf(), x: 200, y: 300))
        layer.addChild(place(cauldron(), x: 60, y: 0))
        layer.addChild(place(table(width: 180), x: 520, y: 0))
        layer.addChild(place(flask(color: GamePalette.torch), x: 500, y: 92))
        layer.addChild(place(candle(), x: 560, y: 92))
        let motes = SKEmitterNode.magicMotes(color: GamePalette.magicPink, width: 1_400, height: 300)
        motes.position = CGPoint(x: 0, y: 220)
        motes.particleBirthRate = 4
        layer.addChild(motes)
    }

    private static func mirrorHall(_ layer: SKNode) {
        for x in stride(from: CGFloat(-700), through: 500, by: 240) {
            layer.addChild(place(mirror(), x: x, y: 60))
        }
        layer.addChild(place(chandelier(), x: -200, y: CastleLayout.roomHeight))
        layer.addChild(place(chandelier(), x: 300, y: CastleLayout.roomHeight))
    }

    private static func secretCorridors(_ layer: SKNode) {
        layer.addChild(place(crack(), x: -600, y: 200))
        layer.addChild(place(crack(), x: 150, y: 260))
        layer.addChild(place(lever(), x: -300, y: 180))
        layer.addChild(place(cobweb(), x: -820, y: CastleLayout.roomHeight - 30))
        layer.addChild(place(cobweb(), x: 350, y: CastleLayout.roomHeight - 30))
        for (i, x) in [CGFloat(-120), CGFloat(60), CGFloat(240)].enumerated() {
            layer.addChild(place(paintedDoor(color: [GamePalette.shieldRed, GamePalette.tunic, GamePalette.success][i]), x: x, y: 0))
        }
        layer.addChild(place(candle(), x: -480, y: 140))
        layer.addChild(place(candle(), x: 520, y: 140))
    }

    private static func armory(_ layer: SKNode) {
        layer.addChild(place(armorStand(), x: -680, y: 0))
        layer.addChild(place(armorStand(), x: -520, y: 0))
        layer.addChild(place(shieldOnWall(color: GamePalette.shieldRed), x: -260, y: 300))
        layer.addChild(place(shieldOnWall(color: GamePalette.flagGold), x: -80, y: 300))
        layer.addChild(place(shieldOnWall(color: GamePalette.tunic), x: 100, y: 300))
        layer.addChild(place(helmetShelf(), x: 320, y: 240))
        layer.addChild(place(barrel(), x: 520, y: 0))
        layer.addChild(place(bench(), x: 400, y: 0))
    }

    private static func throneRoom(_ layer: SKNode) {
        layer.addChild(place(carpet(), x: 0, y: 0))
        for x in stride(from: CGFloat(-720), through: 480, by: 300) {
            layer.addChild(place(column(), x: x, y: 0))
        }
        layer.addChild(place(throne(), x: -560, y: 0))
        layer.addChild(place(banner(color: GamePalette.shieldRed), x: -400, y: CastleLayout.roomHeight))
        layer.addChild(place(banner(color: GamePalette.shieldRed), x: 160, y: CastleLayout.roomHeight))
        layer.addChild(place(chandelier(), x: 0, y: CastleLayout.roomHeight))
    }

    private static func mainGate(_ layer: SKNode) {
        layer.addChild(place(chain(length: 300), x: -600, y: CastleLayout.roomHeight - 10))
        layer.addChild(place(chain(length: 300), x: -480, y: CastleLayout.roomHeight - 10))
        layer.addChild(place(gear(radius: 120, teeth: 12, color: GamePalette.iron, speed: 14), x: -540, y: 150))
        layer.addChild(place(shieldOnWall(color: GamePalette.shieldRed), x: -200, y: 300))
        layer.addChild(place(banner(color: GamePalette.flagGold), x: 0, y: CastleLayout.roomHeight))
        layer.addChild(place(barrel(), x: 300, y: 0))
        layer.addChild(place(barrel(), x: 350, y: 0))
        layer.addChild(place(armorStand(), x: 520, y: 0))
    }

    // MARK: - Props

    private static func place(_ node: SKNode, x: CGFloat, y: CGFloat) -> SKNode {
        node.position = CGPoint(x: x, y: y)
        return node
    }

    private static func straw() -> SKNode {
        let n = SKNode()
        let pile = ShapeFactory.ellipse(size: CGSize(width: 170, height: 44), fill: UIColor(red: 0.80, green: 0.66, blue: 0.32, alpha: 1))
        pile.position = CGPoint(x: 0, y: 14)
        n.addChild(pile)
        for i in 0..<9 {
            let blade = ShapeFactory.line(from: CGPoint(x: -70 + CGFloat(i) * 17, y: 8), to: CGPoint(x: -60 + CGFloat(i) * 17, y: 36), color: UIColor(red: 0.92, green: 0.80, blue: 0.42, alpha: 1), width: 3)
            n.addChild(blade)
        }
        return n
    }

    private static func bench() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -60, y: 44, width: 120, height: 14), fill: GamePalette.wood, corner: 3))
        n.addChild(ShapeFactory.rect(CGRect(x: -50, y: 0, width: 12, height: 44), fill: GamePalette.woodDark))
        n.addChild(ShapeFactory.rect(CGRect(x: 38, y: 0, width: 12, height: 44), fill: GamePalette.woodDark))
        return n
    }

    private static func chain(length: CGFloat) -> SKNode {
        let n = SKNode()
        var y: CGFloat = 0
        var toggle = false
        while y > -length {
            let link = ShapeFactory.rect(CGRect(x: toggle ? -5 : -8, y: y - 22, width: toggle ? 10 : 16, height: 22), fill: .clear, stroke: GamePalette.ironLight, lineWidth: 4, corner: 6)
            n.addChild(link)
            y -= 18
            toggle.toggle()
        }
        let cuff = ShapeFactory.circle(radius: 16, fill: .clear, stroke: GamePalette.ironLight, lineWidth: 6)
        cuff.position = CGPoint(x: 0, y: -length - 10)
        n.addChild(cuff)
        let sway = SKAction.sequence([.rotate(toAngle: 0.05, duration: 1.6), .rotate(toAngle: -0.05, duration: 1.6)])
        sway.timingMode = .easeInEaseOut
        n.run(.repeatForever(sway))
        return n
    }

    private static func bucket() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.polygon([CGPoint(x: -22, y: 0), CGPoint(x: 22, y: 0), CGPoint(x: 26, y: 44), CGPoint(x: -26, y: 44)], fill: GamePalette.wood))
        n.addChild(ShapeFactory.rect(CGRect(x: -27, y: 40, width: 54, height: 6), fill: GamePalette.iron))
        n.addChild(ShapeFactory.rect(CGRect(x: -24, y: 14, width: 48, height: 6), fill: GamePalette.iron))
        return n
    }

    private static func cobweb() -> SKNode {
        let n = SKNode()
        let color = UIColor.white.withAlphaComponent(0.35)
        for angle in stride(from: CGFloat(0), through: .pi / 2, by: .pi / 8) {
            n.addChild(ShapeFactory.line(from: .zero, to: CGPoint(x: cos(angle) * 90, y: -sin(angle) * 90), color: color, width: 1.5))
        }
        for r in [CGFloat(30), CGFloat(55), CGFloat(80)] {
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: r, startAngle: 0, endAngle: -.pi / 2, clockwise: true)
            let ring = SKShapeNode(path: path)
            ring.strokeColor = color
            ring.lineWidth = 1.5
            n.addChild(ring)
        }
        return n
    }

    private static func wallRing() -> SKNode {
        let ring = ShapeFactory.circle(radius: 14, fill: .clear, stroke: GamePalette.ironLight, lineWidth: 5)
        let bolt = ShapeFactory.circle(radius: 6, fill: GamePalette.iron)
        bolt.position = CGPoint(x: 0, y: 14)
        let n = SKNode()
        n.addChild(ring)
        n.addChild(bolt)
        return n
    }

    private static func tallyMarks() -> SKNode {
        let n = SKNode()
        for i in 0..<4 {
            n.addChild(ShapeFactory.line(from: CGPoint(x: CGFloat(i) * 10, y: 0), to: CGPoint(x: CGFloat(i) * 10, y: 28), color: GamePalette.stoneLight.withAlphaComponent(0.7), width: 3))
        }
        n.addChild(ShapeFactory.line(from: CGPoint(x: -6, y: 4), to: CGPoint(x: 36, y: 24), color: GamePalette.stoneLight.withAlphaComponent(0.7), width: 3))
        return n
    }

    private static func bunkBed() -> SKNode {
        let n = SKNode()
        for y in [CGFloat(40), CGFloat(140)] {
            n.addChild(ShapeFactory.rect(CGRect(x: -80, y: y, width: 160, height: 14), fill: GamePalette.wood))
            n.addChild(ShapeFactory.rect(CGRect(x: -74, y: y + 14, width: 148, height: 18), fill: UIColor(red: 0.85, green: 0.82, blue: 0.74, alpha: 1), corner: 5))
            n.addChild(ShapeFactory.rect(CGRect(x: -70, y: y + 16, width: 36, height: 18), fill: GamePalette.guardCloth, corner: 5))
        }
        n.addChild(ShapeFactory.rect(CGRect(x: -86, y: 0, width: 10, height: 200), fill: GamePalette.woodDark))
        n.addChild(ShapeFactory.rect(CGRect(x: 76, y: 0, width: 10, height: 200), fill: GamePalette.woodDark))
        return n
    }

    private static func shieldOnWall(color: UIColor) -> SKNode {
        let shield = ShapeFactory.polygon([CGPoint(x: -30, y: 30), CGPoint(x: 30, y: 30), CGPoint(x: 30, y: 0), CGPoint(x: 0, y: -40), CGPoint(x: -30, y: 0)], fill: color, stroke: GamePalette.flagGold, lineWidth: 4)
        let stripe = ShapeFactory.rect(CGRect(x: -4, y: -32, width: 8, height: 58), fill: GamePalette.flagGold)
        let n = SKNode()
        n.addChild(shield)
        n.addChild(stripe)
        return n
    }

    private static func helmetShelf() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -90, y: -6, width: 180, height: 10), fill: GamePalette.wood))
        for x in [CGFloat(-60), CGFloat(0), CGFloat(60)] {
            let helm = ShapeFactory.polygon([CGPoint(x: x - 20, y: 4), CGPoint(x: x + 20, y: 4), CGPoint(x: x + 20, y: 22), CGPoint(x: x, y: 40), CGPoint(x: x - 20, y: 22)], fill: GamePalette.armor)
            n.addChild(helm)
            n.addChild(ShapeFactory.rect(CGRect(x: x - 14, y: 10, width: 28, height: 5), fill: GamePalette.pupil))
        }
        return n
    }

    private static func table(width: CGFloat) -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -width / 2, y: 80, width: width, height: 14), fill: GamePalette.wood, corner: 3))
        n.addChild(ShapeFactory.rect(CGRect(x: -width / 2 + 12, y: 0, width: 14, height: 80), fill: GamePalette.woodDark))
        n.addChild(ShapeFactory.rect(CGRect(x: width / 2 - 26, y: 0, width: 14, height: 80), fill: GamePalette.woodDark))
        return n
    }

    private static func barrel() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -28, y: 0, width: 56, height: 80), fill: GamePalette.wood, corner: 14))
        n.addChild(ShapeFactory.rect(CGRect(x: -29, y: 16, width: 58, height: 7), fill: GamePalette.iron))
        n.addChild(ShapeFactory.rect(CGRect(x: -29, y: 56, width: 58, height: 7), fill: GamePalette.iron))
        return n
    }

    private static func banner(color: UIColor) -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -34, y: -14, width: 68, height: 10), fill: GamePalette.woodDark))
        n.addChild(ShapeFactory.polygon([CGPoint(x: -28, y: -14), CGPoint(x: 28, y: -14), CGPoint(x: 28, y: -150), CGPoint(x: 0, y: -176), CGPoint(x: -28, y: -150)], fill: color))
        let star = SKLabelNode(text: "★")
        star.fontName = "AvenirNext-Bold"
        star.fontSize = 28
        star.fontColor = GamePalette.flagGold
        star.verticalAlignmentMode = .center
        star.position = CGPoint(x: 0, y: -80)
        n.addChild(star)
        let sway = SKAction.sequence([.rotate(toAngle: 0.03, duration: 2), .rotate(toAngle: -0.03, duration: 2)])
        sway.timingMode = .easeInEaseOut
        n.run(.repeatForever(sway))
        return n
    }

    private static func candle() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -5, y: 0, width: 10, height: 26), fill: UIColor(red: 0.96, green: 0.93, blue: 0.82, alpha: 1), corner: 2))
        let flame = ShapeFactory.ellipse(size: CGSize(width: 10, height: 18), fill: GamePalette.torch)
        flame.position = CGPoint(x: 0, y: 34)
        n.addChild(flame)
        let glow = ShapeFactory.glow(radius: 70, color: GamePalette.torch, alpha: 0.4)
        glow.position = CGPoint(x: 0, y: 34)
        glow.zPosition = -0.5
        n.addChild(glow)
        flame.run(.repeatForever(.sequence([.scaleY(to: 1.2, duration: 0.15), .scaleY(to: 0.9, duration: 0.2)])))
        return n
    }

    private static func bookshelf(width: CGFloat, height: CGFloat) -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -width / 2, y: 0, width: width, height: height), fill: GamePalette.woodDark))
        var rng = SeededRandom(seed: UInt64(width + height))
        let palette = [GamePalette.shieldRed, GamePalette.tunic, GamePalette.success, GamePalette.flagGold, GamePalette.magic, GamePalette.magicPink]
        let shelves = Int(height / 90)
        for s in 0..<shelves {
            let y = CGFloat(s) * 90 + 10
            n.addChild(ShapeFactory.rect(CGRect(x: -width / 2 + 4, y: y - 6, width: width - 8, height: 6), fill: GamePalette.wood))
            var x = -width / 2 + 10
            while x < width / 2 - 16 {
                let w = CGFloat(rng.int(in: 12...24))
                let h = CGFloat(rng.int(in: 50...74))
                n.addChild(ShapeFactory.rect(CGRect(x: x, y: y, width: w, height: h), fill: rng.pick(palette), corner: 2))
                x += w + 3
            }
        }
        return n
    }

    private static func scroll() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -30, y: 0, width: 60, height: 16), fill: UIColor(red: 0.93, green: 0.88, blue: 0.72, alpha: 1), corner: 4))
        n.addChild(ShapeFactory.circle(radius: 9, fill: GamePalette.wood))
        let end = ShapeFactory.circle(radius: 9, fill: GamePalette.wood)
        end.position = CGPoint(x: 0, y: 0)
        n.addChild(end)
        return n
    }

    private static func gear(radius: CGFloat, teeth: Int, color: UIColor, speed: Double) -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.circle(radius: radius, fill: color))
        n.addChild(ShapeFactory.circle(radius: radius * 0.55, fill: GamePalette.stoneShadow))
        n.addChild(ShapeFactory.circle(radius: radius * 0.18, fill: color))
        for i in 0..<teeth {
            let angle = CGFloat(i) / CGFloat(teeth) * .pi * 2
            let tooth = ShapeFactory.rect(CGRect(x: -radius * 0.11, y: radius - 2, width: radius * 0.22, height: radius * 0.2), fill: color)
            tooth.zRotation = angle
            n.addChild(tooth)
        }
        let direction: CGFloat = speed < 0 ? -1 : 1
        n.run(.repeatForever(.rotate(byAngle: direction * .pi * 2, duration: abs(speed))))
        return n
    }

    private static func clockFace(radius: CGFloat) -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.circle(radius: radius + 12, fill: GamePalette.woodDark))
        n.addChild(ShapeFactory.circle(radius: radius, fill: UIColor(red: 0.94, green: 0.90, blue: 0.78, alpha: 1)))
        for i in 0..<12 {
            let angle = CGFloat(i) / 12 * .pi * 2
            let tick = ShapeFactory.rect(CGRect(x: -3, y: radius - 18, width: 6, height: 12), fill: GamePalette.pupil)
            tick.zRotation = -angle
            n.addChild(tick)
        }
        let hour = ShapeFactory.rect(CGRect(x: -4, y: 0, width: 8, height: radius * 0.5), fill: GamePalette.pupil, corner: 3)
        hour.zRotation = -0.8
        let minute = ShapeFactory.rect(CGRect(x: -3, y: 0, width: 6, height: radius * 0.75), fill: GamePalette.pupil, corner: 3)
        n.addChild(hour)
        n.addChild(minute)
        minute.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 60)))
        hour.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 720)))
        return n
    }

    private static func pendulumDecor() -> SKNode {
        let n = SKNode()
        let rod = ShapeFactory.rect(CGRect(x: -3, y: -260, width: 6, height: 260), fill: GamePalette.flagGold)
        let bob = ShapeFactory.circle(radius: 26, fill: GamePalette.flagGold)
        bob.position = CGPoint(x: 0, y: -270)
        n.addChild(rod)
        n.addChild(bob)
        let swing = SKAction.sequence([.rotate(toAngle: 0.35, duration: 1), .rotate(toAngle: -0.35, duration: 1)])
        swing.timingMode = .easeInEaseOut
        n.run(.repeatForever(swing))
        return n
    }

    private static func flask(color: UIColor) -> SKNode {
        let n = SKNode()
        let glass = ShapeFactory.polygon([CGPoint(x: -8, y: 60), CGPoint(x: 8, y: 60), CGPoint(x: 8, y: 36), CGPoint(x: 26, y: 0), CGPoint(x: -26, y: 0), CGPoint(x: -8, y: 36)], fill: UIColor.white.withAlphaComponent(0.18), stroke: UIColor.white.withAlphaComponent(0.5), lineWidth: 2)
        let liquid = ShapeFactory.polygon([CGPoint(x: -16, y: 20), CGPoint(x: 16, y: 20), CGPoint(x: 26, y: 0), CGPoint(x: -26, y: 0)], fill: color.withAlphaComponent(0.85))
        n.addChild(liquid)
        n.addChild(glass)
        let glow = ShapeFactory.glow(radius: 50, color: color, alpha: 0.4)
        glow.position = CGPoint(x: 0, y: 14)
        glow.zPosition = -0.5
        n.addChild(glow)
        glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.2, duration: 0.8), .fadeAlpha(to: 0.5, duration: 0.8)])))
        return n
    }

    private static func jarShelf() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -100, y: -6, width: 200, height: 10), fill: GamePalette.wood))
        let colors = [GamePalette.success, GamePalette.magic, GamePalette.torch, GamePalette.magicPink]
        for (i, color) in colors.enumerated() {
            let x = CGFloat(-70 + i * 46)
            n.addChild(ShapeFactory.rect(CGRect(x: x - 14, y: 4, width: 28, height: 36), fill: color.withAlphaComponent(0.7), corner: 6))
            n.addChild(ShapeFactory.rect(CGRect(x: x - 10, y: 40, width: 20, height: 8), fill: GamePalette.woodDark, corner: 2))
        }
        return n
    }

    private static func cauldron() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.ellipse(size: CGSize(width: 120, height: 90), fill: GamePalette.pupil).withPosition(CGPoint(x: 0, y: 50)))
        n.addChild(ShapeFactory.ellipse(size: CGSize(width: 100, height: 26), fill: GamePalette.success).withPosition(CGPoint(x: 0, y: 84)))
        n.addChild(ShapeFactory.rect(CGRect(x: -40, y: 0, width: 12, height: 20), fill: GamePalette.pupil))
        n.addChild(ShapeFactory.rect(CGRect(x: 28, y: 0, width: 12, height: 20), fill: GamePalette.pupil))
        let glow = ShapeFactory.glow(radius: 110, color: GamePalette.success, alpha: 0.5)
        glow.position = CGPoint(x: 0, y: 90)
        n.addChild(glow)
        let bubbles = SKEmitterNode.magicMotes(color: GamePalette.success, width: 70, height: 10)
        bubbles.position = CGPoint(x: 0, y: 90)
        bubbles.particleSpeed = 60
        bubbles.emissionAngleRange = 0.4
        bubbles.particleBirthRate = 8
        n.addChild(bubbles)
        return n
    }

    private static func mirror() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.arch(width: 120, height: 280, fill: GamePalette.flagGold))
        let glass = ShapeFactory.arch(width: 100, height: 262, fill: UIColor(red: 0.62, green: 0.74, blue: 0.92, alpha: 0.55))
        glass.position = CGPoint(x: 0, y: 8)
        n.addChild(glass)
        let shine = ShapeFactory.polygon([CGPoint(x: -30, y: 40), CGPoint(x: -10, y: 40), CGPoint(x: 10, y: 230), CGPoint(x: -10, y: 230)], fill: UIColor.white.withAlphaComponent(0.35))
        n.addChild(shine)
        return n
    }

    private static func chandelier() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -3, y: -90, width: 6, height: 90), fill: GamePalette.ironLight))
        n.addChild(ShapeFactory.circle(radius: 70, fill: .clear, stroke: GamePalette.flagGold, lineWidth: 8).withPosition(CGPoint(x: 0, y: -110)))
        for i in 0..<5 {
            let angle = CGFloat(i) / 5 * .pi * 2
            let candleNode = candle()
            candleNode.position = CGPoint(x: cos(angle) * 60, y: -110 + sin(angle) * 16)
            n.addChild(candleNode)
        }
        n.run(.repeatForever(.sequence([.rotate(toAngle: 0.04, duration: 2.5), .rotate(toAngle: -0.04, duration: 2.5)])))
        return n
    }

    private static func crack() -> SKNode {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 20, y: -40))
        path.addLine(to: CGPoint(x: 6, y: -90))
        path.addLine(to: CGPoint(x: 34, y: -150))
        let crack = SKShapeNode(path: path)
        crack.strokeColor = GamePalette.stoneShadow
        crack.lineWidth = 4
        return crack
    }

    private static func lever() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -30, y: -10, width: 60, height: 20), fill: GamePalette.iron, corner: 6))
        let handle = ShapeFactory.rect(CGRect(x: -4, y: 0, width: 8, height: 60), fill: GamePalette.ironLight, corner: 3)
        handle.zRotation = 0.5
        n.addChild(handle)
        let knob = ShapeFactory.circle(radius: 9, fill: GamePalette.shieldRed)
        knob.position = CGPoint(x: -28, y: 52)
        n.addChild(knob)
        return n
    }

    private static func paintedDoor(color: UIColor) -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.arch(width: 90, height: 170, fill: GamePalette.stoneDark))
        let leaf = ShapeFactory.arch(width: 74, height: 158, fill: color.withAlphaComponent(0.8))
        n.addChild(leaf)
        let knob = ShapeFactory.circle(radius: 5, fill: GamePalette.flagGold)
        knob.position = CGPoint(x: 22, y: 80)
        n.addChild(knob)
        return n
    }

    private static func armorStand() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -4, y: 0, width: 8, height: 190), fill: GamePalette.woodDark))
        n.addChild(ShapeFactory.rect(CGRect(x: -34, y: 0, width: 68, height: 10), fill: GamePalette.woodDark))
        n.addChild(ShapeFactory.rect(CGRect(x: -30, y: 70, width: 60, height: 80), fill: GamePalette.armor, corner: 14))
        n.addChild(ShapeFactory.polygon([CGPoint(x: -24, y: 156), CGPoint(x: 24, y: 156), CGPoint(x: 24, y: 176), CGPoint(x: 0, y: 196), CGPoint(x: -24, y: 176)], fill: GamePalette.armor))
        n.addChild(ShapeFactory.rect(CGRect(x: -16, y: 164, width: 32, height: 5), fill: GamePalette.pupil))
        return n
    }

    private static func carpet() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -CastleLayout.keepHalfWidth, y: 0, width: CastleLayout.keepWidth, height: 18), fill: GamePalette.shieldRed))
        n.addChild(ShapeFactory.rect(CGRect(x: -CastleLayout.keepHalfWidth, y: 16, width: CastleLayout.keepWidth, height: 4), fill: GamePalette.flagGold))
        n.zPosition = 0.5
        return n
    }

    private static func column() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -34, y: 0, width: 68, height: CastleLayout.roomHeight), fill: GamePalette.stoneLight, corner: 6))
        n.addChild(ShapeFactory.rect(CGRect(x: -44, y: 0, width: 88, height: 24), fill: GamePalette.stone))
        n.addChild(ShapeFactory.rect(CGRect(x: -44, y: CastleLayout.roomHeight - 24, width: 88, height: 24), fill: GamePalette.stone))
        n.addChild(ShapeFactory.rect(CGRect(x: 12, y: 24, width: 14, height: CastleLayout.roomHeight - 48), fill: GamePalette.stoneDark.withAlphaComponent(0.35)))
        return n
    }

    private static func throne() -> SKNode {
        let n = SKNode()
        n.addChild(ShapeFactory.rect(CGRect(x: -70, y: 0, width: 140, height: 36), fill: GamePalette.stoneLight))
        n.addChild(ShapeFactory.rect(CGRect(x: -48, y: 36, width: 96, height: 200), fill: GamePalette.flagGold, corner: 20))
        n.addChild(ShapeFactory.rect(CGRect(x: -40, y: 44, width: 80, height: 150), fill: GamePalette.shieldRed, corner: 14))
        n.addChild(ShapeFactory.rect(CGRect(x: -58, y: 36, width: 116, height: 50), fill: GamePalette.shieldRed, corner: 10))
        n.addChild(ShapeFactory.polygon([CGPoint(x: -24, y: 236), CGPoint(x: 24, y: 236), CGPoint(x: 18, y: 270), CGPoint(x: 0, y: 250), CGPoint(x: -18, y: 270)], fill: GamePalette.flagGold))
        return n
    }
}

private extension SKNode {
    func withPosition(_ p: CGPoint) -> SKNode {
        position = p
        return self
    }
}
