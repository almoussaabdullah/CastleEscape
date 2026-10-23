import SpriteKit

/// Side-view cutaway of one castle floor: walls, window, torches, themed props, obstacles,
/// the exit door, the hero and the guard. Its local origin is the keep centre at floor level,
/// so placing it at `CastleLayout.interiorOrigin(floor:)` aligns it with the exterior window.
final class FloorInteriorNode: SKNode {
    let floor: FloorDefinition
    let hero = HeroNode()
    let guardNode = GuardNode()
    let exitDoor = ExitDoorNode()
    private(set) var obstacles: [ObstacleNode] = []
    private let checkpoints: [CGFloat]
    private let backdrop = SKNode()
    private let windowLight: SKShapeNode

    init(floor: FloorDefinition) {
        self.floor = floor
        checkpoints = CastleLayout.checkpoints(count: floor.encounterCount)
        windowLight = ShapeFactory.polygon([
            CGPoint(x: -CastleLayout.windowSize.width / 2, y: 0), CGPoint(x: CastleLayout.windowSize.width / 2, y: 0),
            CGPoint(x: 160, y: -CastleLayout.windowLocalY - 60), CGPoint(x: -220, y: -CastleLayout.windowLocalY - 60),
        ], fill: GamePalette.moon.withAlphaComponent(0.08))
        super.init()
        buildBackdrop()
        buildWindow()
        buildTorches()
        buildObstacles()
        FloorThemeDecorator.decorate(self, theme: floor.theme, obstaclePositions: obstacles.map { $0.position.x })
        exitDoor.position = CGPoint(x: CastleLayout.exitDoorX, y: 0)
        exitDoor.zPosition = 6
        addChild(exitDoor)
        hero.position = CGPoint(x: CastleLayout.heroStartX, y: 0)
        hero.zPosition = 12
        guardNode.zPosition = 11
        addChild(hero)
        addChild(guardNode)
        guardNode.patrol()
    }

    required init?(coder aDecoder: NSCoder) { nil }

    // MARK: - Construction

    private func buildBackdrop() {
        let half = CastleLayout.keepHalfWidth
        let roomH = CastleLayout.roomHeight
        backdrop.zPosition = 0
        addChild(backdrop)
        // Foundation below the floor (sits behind the puzzle panel).
        let foundation = TiledTextureNode(rect: CGRect(x: -half, y: -CastleLayout.foundationDepth, width: half * 2, height: CastleLayout.foundationDepth), textureName: "stone_tile_dark", tileSize: 200, tint: .black, tintStrength: 0.45)
        backdrop.addChild(foundation)
        // Back wall with themed tint.
        let backWall = TiledTextureNode(rect: CGRect(x: -half, y: 0, width: half * 2, height: roomH), textureName: "stone_tile_dark", tileSize: 220, tint: wallTint, tintStrength: 0.28)
        backdrop.addChild(backWall)
        // Darker band at the bottom of the wall + light near the ceiling to fake depth.
        let shadeBottom = SKSpriteNode(texture: TextureCache.gradient(width: 4, height: 128, colors: [UIColor.clear, UIColor.black.withAlphaComponent(0.45)], key: "shade.bottom"))
        shadeBottom.anchorPoint = CGPoint(x: 0.5, y: 0)
        shadeBottom.size = CGSize(width: half * 2, height: 120)
        shadeBottom.position = CGPoint(x: 0, y: 0)
        shadeBottom.zPosition = 0.4
        backdrop.addChild(shadeBottom)
        // Floor slab and flagstones.
        let slab = TiledTextureNode(rect: CGRect(x: -half, y: -CastleLayout.slabThickness, width: half * 2, height: CastleLayout.slabThickness), textureName: "stone_tile", tileSize: 160)
        slab.zPosition = 0.5
        backdrop.addChild(slab)
        let floorLine = ShapeFactory.rect(CGRect(x: -half, y: -6, width: half * 2, height: 12), fill: GamePalette.stoneLight)
        floorLine.zPosition = 0.6
        backdrop.addChild(floorLine)
        var x = -half
        var toggle = false
        while x < half {
            let stone = ShapeFactory.rect(CGRect(x: x, y: -26, width: 110, height: 20), fill: toggle ? GamePalette.stone : GamePalette.stoneLight.withAlphaComponent(0.8), corner: 3)
            stone.zPosition = 0.55
            backdrop.addChild(stone)
            x += 114
            toggle.toggle()
        }
        // Ceiling slab with beams.
        let ceiling = TiledTextureNode(rect: CGRect(x: -half, y: roomH, width: half * 2, height: CastleLayout.slabThickness), textureName: "stone_tile", tileSize: 160)
        ceiling.zPosition = 0.5
        backdrop.addChild(ceiling)
        let cornice = ShapeFactory.rect(CGRect(x: -half, y: roomH - 10, width: half * 2, height: 14), fill: GamePalette.stoneLight)
        cornice.zPosition = 0.6
        backdrop.addChild(cornice)
        for beamX in stride(from: -half + 120, through: half - 120, by: 260) {
            let beam = ShapeFactory.rect(CGRect(x: beamX - 16, y: roomH - 54, width: 32, height: 50), fill: GamePalette.woodDark)
            beam.zPosition = 0.45
            backdrop.addChild(beam)
        }
        // Cut edge of the facade: a thin bright line marks where the exterior wall was "sliced".
        let cutEdge = ShapeFactory.rect(CGRect(x: -half, y: roomH + CastleLayout.slabThickness - 6, width: half * 2, height: 6), fill: GamePalette.stoneLight.withAlphaComponent(0.6))
        cutEdge.zPosition = 0.7
        backdrop.addChild(cutEdge)
    }

    private var wallTint: UIColor {
        switch floor.theme {
        case .prisonTower: return UIColor(red: 0.18, green: 0.20, blue: 0.34, alpha: 1)
        case .guardBarracks: return UIColor(red: 0.30, green: 0.18, blue: 0.16, alpha: 1)
        case .ancientLibrary: return UIColor(red: 0.26, green: 0.20, blue: 0.12, alpha: 1)
        case .clockTower: return UIColor(red: 0.28, green: 0.24, blue: 0.14, alpha: 1)
        case .alchemistLab: return UIColor(red: 0.12, green: 0.26, blue: 0.24, alpha: 1)
        case .mirrorHall: return UIColor(red: 0.22, green: 0.26, blue: 0.40, alpha: 1)
        case .secretCorridors: return UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
        case .armory: return UIColor(red: 0.24, green: 0.24, blue: 0.28, alpha: 1)
        case .throneRoom: return UIColor(red: 0.36, green: 0.16, blue: 0.20, alpha: 1)
        case .mainGate: return UIColor(red: 0.20, green: 0.22, blue: 0.30, alpha: 1)
        }
    }

    private func buildWindow() {
        let window = SKNode()
        window.position = CGPoint(x: CastleLayout.windowLocalX, y: CastleLayout.windowLocalY)
        window.zPosition = 0.8
        let size = CastleLayout.windowSize
        let frame = ShapeFactory.arch(width: size.width + 30, height: size.height + 16, fill: GamePalette.stoneLight)
        frame.position = CGPoint(x: 0, y: -size.height / 2 - 8)
        let sky = SKSpriteNode(texture: TextureCache.gradient(width: 4, height: 64, colors: [GamePalette.nightTop, GamePalette.nightBottom], key: "sky.window"))
        sky.size = CGSize(width: size.width, height: size.height)
        let crop = SKCropNode()
        let mask = ShapeFactory.arch(width: size.width, height: size.height, fill: .white)
        mask.position = CGPoint(x: 0, y: -size.height / 2)
        crop.maskNode = mask
        crop.addChild(sky)
        let moon = ShapeFactory.circle(radius: 14, fill: GamePalette.moon)
        moon.position = CGPoint(x: 20, y: 36)
        crop.addChild(moon)
        window.addChild(frame)
        window.addChild(crop)
        if floor.theme == .prisonTower {
            for x in stride(from: -size.width / 2 + 16, through: size.width / 2 - 16, by: 24) {
                let bar = ShapeFactory.rect(CGRect(x: x - 3, y: -size.height / 2, width: 6, height: size.height - 4), fill: GamePalette.iron, corner: 2)
                bar.zPosition = 0.1
                window.addChild(bar)
            }
        }
        addChild(window)
        windowLight.position = CGPoint(x: CastleLayout.windowLocalX, y: CastleLayout.windowLocalY + CastleLayout.windowSize.height / 2 - 20)
        windowLight.zPosition = 0.9
        addChild(windowLight)
    }

    private func buildTorches() {
        for x in [CGFloat(-200), CGFloat(260), CGFloat(560)] {
            let torch = TorchNode(scale: 1.1, embers: x == 260)
            torch.position = CGPoint(x: x, y: 290)
            torch.zPosition = 2
            addChild(torch)
        }
    }

    private func buildObstacles() {
        for index in 0..<floor.encounterCount {
            let obstacle = ObstacleNode.make(kind: floor.obstacle(forEncounter: index))
            obstacle.position = CGPoint(x: CastleLayout.obstacleX(index: index, count: floor.encounterCount), y: 0)
            obstacle.zPosition = 8
            addChild(obstacle)
            obstacles.append(obstacle)
        }
    }

    // MARK: - Positions

    func checkpointX(_ index: Int) -> CGFloat {
        checkpoints[min(max(0, index), checkpoints.count - 1)]
    }

    /// Places the hero at a checkpoint and the guard at the gap dictated by the danger level.
    func positionCharacters(checkpoint: Int, dangerLevel: Int, maxDanger: Int) {
        hero.removeAllActions()
        hero.restorePose()
        hero.position = CGPoint(x: checkpointX(checkpoint), y: 0)
        hero.face(1)
        guardNode.removeAllActions()
        guardNode.restorePose()
        guardNode.position = CGPoint(x: guardX(forHeroX: hero.position.x, dangerLevel: dangerLevel, maxDanger: maxDanger), y: 0)
        guardNode.face(1)
    }

    func guardX(forHeroX heroX: CGFloat, dangerLevel: Int, maxDanger: Int) -> CGFloat {
        heroX - CastleLayout.guardGap(dangerLevel: dangerLevel, maxDanger: maxDanger)
    }

    /// Moves the guard to keep the current gap after the hero advanced.
    func guardFollow(dangerLevel: Int, maxDanger: Int, completion: (() -> Void)? = nil) {
        let target = guardX(forHeroX: hero.position.x, dangerLevel: dangerLevel, maxDanger: maxDanger)
        let distance = abs(target - guardNode.position.x)
        guard distance > 4 else { completion?(); return }
        guardNode.approach(to: target, duration: TimeInterval(distance / 240)) { completion?() }
    }

    /// Guard closes in after a mistake.
    func guardAdvance(dangerLevel: Int, maxDanger: Int, completion: @escaping () -> Void) {
        let target = guardX(forHeroX: hero.position.x, dangerLevel: dangerLevel, maxDanger: maxDanger)
        AudioManager.shared.play(.guardClank)
        guardNode.angry()
        hero.frightened()
        let distance = max(1, abs(target - guardNode.position.x))
        guardNode.approach(to: target, duration: TimeInterval(distance / 200)) { [weak self] in
            self?.hero.restorePose()
            completion()
        }
    }

    func guardCatch(completion: @escaping () -> Void) {
        let target = hero.position.x - 62
        guardNode.lunge(to: target, duration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.hero.surprised()
            let shake = SKAction.sequence([.moveBy(x: -5, y: 0, duration: 0.05), .moveBy(x: 10, y: 0, duration: 0.05), .moveBy(x: -5, y: 0, duration: 0.05)])
            self.hero.run(.sequence([.repeat(shake, count: 5), .run(completion)]))
        }
    }

    /// Hero clears obstacle `index` and ends at checkpoint `index + 1`.
    func clearObstacle(index: Int, completion: @escaping () -> Void) {
        guard index < obstacles.count else { hero.walk(to: checkpointX(index + 1), speed: 260, completion: completion); return }
        obstacles[index].clear(hero: hero, targetX: checkpointX(index + 1), completion: completion)
    }

    /// Opens the door and walks the hero down the stairs.
    func exitThroughDoor(completion: @escaping () -> Void) {
        exitDoor.unlock()
        hero.walk(to: CastleLayout.exitDoorX - 70, speed: 240) { [weak self] in
            guard let self = self else { return }
            self.hero.reach(duration: 0.6)
            self.exitDoor.open(duration: 0.9) {
                self.hero.zPosition = 7.7   // inside the doorway: above the stairwell, below the door leaf
                self.hero.descendStairs(dx: 70, dy: -150, duration: 1.3) {
                    self.exitDoor.close(duration: 0.6)
                    completion()
                }
            }
        }
    }
}
