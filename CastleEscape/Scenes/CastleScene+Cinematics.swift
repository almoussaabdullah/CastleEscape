import SpriteKit

extension CastleScene: SceneDirecting {
    func applyProgress(statuses: [Int: FloorStatus], animated: Bool) {
        storeStatuses(statuses)
        castle.apply(statuses: statuses, animated: animated)
    }

    func updateGameplayInsets(top: CGFloat, bottom: CGFloat) {
        director.gameplayInsets = CameraDirector.Insets(top: top, bottom: bottom)
    }

    func updateMenuInsets(top: CGFloat, bottom: CGFloat) {
        director.menuInsets = CameraDirector.Insets(top: top, bottom: bottom)
        if mode == .menu, !director.isFlying {
            director.startDrift(from: director.menuState())
        }
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    // MARK: - Entering a floor

    func enterFloor(_ floor: FloorDefinition, completion: @escaping () -> Void) {
        setMode(.entering)
        director.stopDrift()
        director.stopFollowing()
        removeVictoryHero()
        castle.closeGate()
        sky.resetToNight()
        let interior = installInterior(for: floor)
        interior.positionCharacters(checkpoint: 0, dangerLevel: 0, maxDanger: floor.safetyMargin)
        castle.window(for: floor.number)?.apply(status: .current, animated: true)

        AudioManager.shared.play(.whoosh)
        let windowState = director.windowState(floor: floor.number)
        let playState = director.gameplayState(floor: floor.number, heroX: interior.hero.position.x)
        director.fly(to: windowState, duration: 1.7, timing: .easeInEaseOut) { [weak self, weak interior] in
            guard let self = self, let interior = interior else { return }
            // The facade dissolves into the cutaway while the camera keeps moving.
            interior.run(.fadeIn(withDuration: 0.5))
            AudioManager.shared.play(.whoosh, volume: 0.6)
            self.director.fly(to: playState, duration: 1.1, timing: .easeOut) { [weak self] in
                guard let self = self else { return }
                self.setMode(.gameplay)
                self.director.startFollowing(heroX: interior.hero.position.x)
                if floor.number == FloorCatalog.topFloor {
                    interior.hero.surprised()
                }
                completion()
            }
        }
    }

    // MARK: - Gameplay commands

    func heroThinks() {
        interior?.hero.think()
    }

    func heroAdvances(obstacleIndex: Int, dangerLevel: Int, maxDanger: Int, completion: @escaping () -> Void) {
        guard let interior = interior else { completion(); return }
        interior.hero.celebrate()
        let sparkle = SKEmitterNode.sparkBurst(color: GamePalette.success, count: 22, speed: 180, scale: 0.45)
        sparkle.position = CGPoint(x: interior.hero.position.x, y: 90)
        sparkle.zPosition = 30
        interior.addChild(sparkle)
        interior.run(.sequence([.wait(forDuration: 0.55), .run { [weak interior] in
            guard let interior = interior else { completion(); return }
            interior.clearObstacle(index: obstacleIndex) {
                interior.guardFollow(dangerLevel: dangerLevel, maxDanger: maxDanger)
                completion()
            }
        }]))
    }

    func guardAdvances(dangerLevel: Int, maxDanger: Int, completion: @escaping () -> Void) {
        guard let interior = interior else { completion(); return }
        interior.guardAdvance(dangerLevel: dangerLevel, maxDanger: maxDanger, completion: completion)
    }

    func guardConfused() {
        guard let interior = interior else { return }
        interior.guardNode.confused()
        let ring = ShapeFactory.circle(radius: 40, fill: .clear, stroke: GamePalette.magic, lineWidth: 6)
        ring.position = CGPoint(x: interior.hero.position.x, y: 80)
        ring.zPosition = 30
        interior.addChild(ring)
        ring.run(.sequence([.group([.scale(to: 3, duration: 0.6), .fadeOut(withDuration: 0.6)]), .removeFromParent()]))
        AudioManager.shared.play(.shield)
    }

    func guardCatches(completion: @escaping () -> Void) {
        guard let interior = interior else { completion(); return }
        AudioManager.shared.play(.guardClank)
        interior.guardCatch(completion: completion)
    }

    func resetPositions(checkpoint: Int, dangerLevel: Int, maxDanger: Int) {
        guard let interior = interior else { return }
        interior.positionCharacters(checkpoint: checkpoint, dangerLevel: dangerLevel, maxDanger: maxDanger)
        director.startFollowing(heroX: interior.hero.position.x)
    }

    func showCombo(multiplier: Double) {
        guard let interior = interior else { return }
        AudioManager.shared.play(.comboSparkle)
        let burst = SKEmitterNode.sparkBurst(color: GamePalette.flagGold, count: 40, speed: 300, scale: 0.6)
        burst.position = CGPoint(x: interior.hero.position.x, y: 120)
        burst.zPosition = 30
        interior.addChild(burst)
        let label = SKLabelNode(text: "×\(Int(multiplier))")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 54
        label.fontColor = GamePalette.flagGold
        label.position = CGPoint(x: interior.hero.position.x, y: 200)
        label.zPosition = 31
        label.setScale(0.2)
        interior.addChild(label)
        let pop = SKAction.scale(to: 1.2, duration: 0.25)
        pop.timingMode = .easeOut
        label.run(.sequence([pop, .group([.moveBy(x: 0, y: 90, duration: 0.8), .fadeOut(withDuration: 0.8)]), .removeFromParent()]))
    }

    func showShieldGained() {
        guard let interior = interior else { return }
        AudioManager.shared.play(.shield)
        let shield = ShapeFactory.circle(radius: 110, fill: GamePalette.magic.withAlphaComponent(0.18), stroke: GamePalette.magic, lineWidth: 5)
        shield.position = CGPoint(x: 0, y: 80)
        shield.zPosition = 30
        shield.alpha = 0
        interior.hero.addChild(shield)
        shield.run(.sequence([.fadeIn(withDuration: 0.3), .wait(forDuration: 1.2), .fadeOut(withDuration: 0.5), .removeFromParent()]))
    }

    // MARK: - Leaving a floor

    func exitFloor(completion: @escaping () -> Void) {
        guard let interior = interior else { completion(); return }
        setMode(.exiting)
        AudioManager.shared.play(.unlock)
        interior.exitThroughDoor(completion: completion)
    }

    func zoomOutAfterFloor(completedFloor: Int, statuses: [Int: FloorStatus], nextFloor: Int?, completion: @escaping () -> Void) {
        setMode(.exiting)
        director.stopFollowing()
        storeStatuses(statuses)
        let windowState = director.windowState(floor: completedFloor)
        AudioManager.shared.play(.whoosh, volume: 0.7)
        interior?.run(.sequence([.wait(forDuration: 0.35), .fadeOut(withDuration: 0.5)]))
        director.fly(to: windowState, duration: 1.0, timing: .easeIn) { [weak self] in
            guard let self = self else { return }
            self.removeInterior()
            let overview = self.director.overviewState(insets: self.director.overviewInsets)
            AudioManager.shared.play(.whoosh, volume: 0.5)
            self.director.fly(to: overview, duration: 1.7, timing: .easeOut) { [weak self] in
                guard let self = self else { return }
                self.setMode(.overview)
                self.castle.window(for: completedFloor)?.apply(status: .completed(stars: 0), animated: true)
                self.castle.window(for: completedFloor)?.celebrate()
                AudioManager.shared.play(.comboSparkle, volume: 0.8)
                self.run(.sequence([.wait(forDuration: 0.6), .run {
                    self.castle.apply(statuses: statuses, animated: true)
                    if let next = nextFloor {
                        self.castle.window(for: next)?.apply(status: .current, animated: true)
                    }
                    completion()
                }]))
            }
        }
    }

    func abandonFloor() {
        director.stopFollowing()
        removeInterior()
        removeVictoryHero()
        castle.closeGate()
        sky.resetToNight()
        castle.apply(statuses: currentStatuses, animated: false)
        showOverview(menu: true, animated: true)
    }

    // MARK: - Victory

    func playVictory(completion: @escaping () -> Void) {
        setMode(.victory)
        director.stopFollowing()
        AudioManager.shared.play(.whoosh, volume: 0.7)
        let gateFocus = CameraDirector.State(position: CGPoint(x: -420, y: 420), scale: 3.2)
        interior?.run(.sequence([.wait(forDuration: 0.3), .fadeOut(withDuration: 0.5)]))
        director.fly(to: gateFocus, duration: 1.6, timing: .easeInEaseOut) { [weak self] in
            guard let self = self else { return }
            self.removeInterior()
            self.castle.openGate(duration: 1.4)
            AudioManager.shared.play(.doorCreak)
            let hero = self.makeVictoryHero()
            hero.alpha = 0
            hero.run(.sequence([.wait(forDuration: 0.8), .fadeIn(withDuration: 0.3)]))
            self.run(.sequence([.wait(forDuration: 1.5), .run { [weak self] in
                guard let self = self else { return }
                AudioManager.shared.play(.victoryFanfare)
                AudioManager.shared.duckMusic(for: 4)
                self.sky.sunrise(duration: 7)
                let bridgeStart = -(CastleLayout.sideTowerX + CastleLayout.sideTowerHalfWidth) - 60
                hero.sprint(to: bridgeStart, duration: 2.2) {
                    hero.jump(to: bridgeStart - 140, height: 60, duration: 0.5) {
                        hero.position.y = 10
                        hero.sprint(to: CastleLayout.bridgeEndX + 260, duration: 2.6) {
                            hero.celebrate()
                            completion()
                        }
                    }
                }
                // Camera pulls back while the hero runs, revealing the whole castle at dawn.
                let pullBack = CameraDirector.State(position: CGPoint(x: -1_100, y: 1_500), scale: 7.5)
                self.director.fly(to: pullBack, duration: 5.4, timing: .easeInEaseOut)
            }]))
        }
    }
}
