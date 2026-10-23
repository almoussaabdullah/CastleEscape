import SpriteKit

/// One continuous SpriteKit world: the exterior castle and the floor interiors share the same
/// coordinate space, so the camera can fly from the mountainside straight into a window.
final class CastleScene: SKScene {
    enum Mode {
        case menu, overview, entering, gameplay, exiting, victory
    }

    let director = CameraDirector()
    let world = SKNode()
    let castle = CastleNode()
    let sky = SkyNode()
    private let mountains = MountainsNode()
    private let clouds = CloudLayerNode()
    private let fog = FogLayerNode()
    private(set) var interior: FloorInteriorNode?
    private(set) var mode: Mode = .overview
    private var lastUpdate: TimeInterval = 0
    private(set) var currentStatuses: [Int: FloorStatus] = [:]
    private var victoryHero: HeroNode?

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = GamePalette.nightTop
    }

    required init?(coder aDecoder: NSCoder) { nil }

    override func didMove(to view: SKView) {
        guard world.parent == nil else { return }
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        addChild(world)
        world.addChild(mountains)
        world.addChild(clouds)
        world.addChild(castle)
        world.addChild(fog)
        castle.zPosition = 0
        camera = director.camera
        addChild(director.camera)
        director.camera.addChild(sky)
        director.viewSize = size
        sky.layout(viewSize: size)
        castle.apply(statuses: currentStatuses, animated: false)
        showOverview(menu: mode == .menu, animated: false)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0 else { return }
        director.viewSize = size
        sky.layout(viewSize: size)
        switch mode {
        case .menu, .overview:
            if !director.isFlying { showOverview(menu: mode == .menu, animated: false) }
        default:
            break
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = lastUpdate == 0 ? 1.0 / 60.0 : min(0.1, currentTime - lastUpdate)
        lastUpdate = currentTime
        switch mode {
        case .menu:
            director.updateDrift(currentTime: currentTime)
        case .gameplay:
            if let interior = interior {
                director.updateFollow(heroX: interior.hero.position.x, floor: interior.floor.number, deltaTime: delta)
            }
        default:
            break
        }
    }

    // MARK: - Interior management

    @discardableResult
    func installInterior(for floor: FloorDefinition) -> FloorInteriorNode {
        removeInterior()
        let node = FloorInteriorNode(floor: floor)
        node.position = CastleLayout.interiorOrigin(floor: floor.number)
        node.zPosition = 100
        node.alpha = 0
        world.addChild(node)
        interior = node
        return node
    }

    func removeInterior() {
        interior?.removeAllActions()
        interior?.removeFromParent()
        interior = nil
    }

    // MARK: - Overview

    func showOverview(menu: Bool, animated: Bool) {
        mode = menu ? .menu : .overview
        let target = menu ? director.menuState() : director.overviewState(insets: director.overviewInsets)
        if animated {
            director.fly(to: target, duration: 1.2, timing: .easeInEaseOut) { [weak self] in
                guard let self = self, menu else { return }
                self.director.startDrift(from: target)
            }
        } else {
            director.snap(to: target)
            if menu { director.startDrift(from: target) } else { director.stopDrift() }
        }
    }

    func storeStatuses(_ statuses: [Int: FloorStatus]) {
        currentStatuses = statuses
    }

    // MARK: - Victory helpers

    func makeVictoryHero() -> HeroNode {
        victoryHero?.removeFromParent()
        let hero = HeroNode()
        hero.zPosition = 2.86   // between the gate opening and the portcullis
        hero.position = CGPoint(x: 0, y: -40)
        hero.setScale(1.0)
        castle.addChild(hero)
        victoryHero = hero
        return hero
    }

    func removeVictoryHero() {
        victoryHero?.removeFromParent()
        victoryHero = nil
    }

    func setMode(_ newMode: Mode) { mode = newMode }
}
