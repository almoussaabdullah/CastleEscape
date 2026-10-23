import SpriteKit

/// Owns the scene camera and knows how to frame the castle overview, a floor window and
/// the gameplay corridor for any iPhone screen (safe areas and UI overlays included).
final class CameraDirector {
    struct State: Equatable {
        var position: CGPoint
        var scale: CGFloat
    }

    /// UI overlay thickness in points: HUD at the top, puzzle panel at the bottom.
    struct Insets: Equatable {
        var top: CGFloat
        var bottom: CGFloat
        static let zero = Insets(top: 0, bottom: 0)
    }

    let camera = SKCameraNode()
    var viewSize: CGSize = CGSize(width: 390, height: 844)
    /// Overlay insets while a puzzle is on screen.
    var gameplayInsets = Insets(top: 110, bottom: 380)
    /// Overlay insets while the main menu is on screen.
    var menuInsets = Insets(top: 80, bottom: 420)
    /// Overlay insets for the plain overview (between floors).
    var overviewInsets = Insets(top: 90, bottom: 120)

    private(set) var isFlying = false
    private var followTargetX: CGFloat?
    private var driftStart: TimeInterval?
    private var driftBase: State?

    init() {
        // Keep the camera at z 0: its only child is the sky, which must render behind the world.
        camera.zPosition = 0
    }

    // MARK: - Framing

    func overviewState(insets: Insets) -> State {
        let bounds = CastleLayout.overviewBounds
        let availableWidth = max(100, viewSize.width - 24)
        let availableHeight = max(100, viewSize.height - insets.top - insets.bottom)
        let scale = max(bounds.width / availableWidth, bounds.height / availableHeight) * 1.04
        let yOffset = (insets.bottom - insets.top) / 2 * scale
        return State(position: CGPoint(x: bounds.midX, y: bounds.midY - yOffset), scale: scale)
    }

    func menuState() -> State { overviewState(insets: menuInsets) }

    func gameplayScale() -> CGFloat {
        let availableHeight = max(120, viewSize.height - gameplayInsets.top - gameplayInsets.bottom)
        let needed = CastleLayout.roomHeight + 50
        return max(CastleLayout.gameplayCameraScale, needed / availableHeight)
    }

    func gameplayCameraY(floor: Int) -> CGFloat {
        let scale = gameplayScale()
        let roomCenter = CastleLayout.floorBaseY(floor) + CastleLayout.roomHeight / 2 + 14
        return roomCenter - (gameplayInsets.bottom - gameplayInsets.top) / 2 * scale
    }

    /// Camera x that keeps the hero framed without showing beyond the room walls.
    func gameplayCameraX(heroX: CGFloat) -> CGFloat {
        let scale = gameplayScale()
        let halfVisible = viewSize.width / 2 * scale
        let minX = -CastleLayout.keepHalfWidth + halfVisible
        let maxX = CastleLayout.keepHalfWidth - halfVisible
        guard minX < maxX else { return 0 }
        return min(maxX, max(minX, heroX + CastleLayout.cameraLookAhead))
    }

    func gameplayState(floor: Int, heroX: CGFloat) -> State {
        State(position: CGPoint(x: gameplayCameraX(heroX: heroX), y: gameplayCameraY(floor: floor)), scale: gameplayScale())
    }

    func windowState(floor: Int) -> State {
        State(position: CastleLayout.windowWorldPosition(floor: floor), scale: CastleLayout.windowCameraScale)
    }

    // MARK: - Motion

    func snap(to state: State) {
        camera.removeAllActions()
        isFlying = false
        camera.position = state.position
        camera.setScale(state.scale)
    }

    /// Smooth move + zoom.
    func fly(to state: State, duration: TimeInterval, timing: SKActionTimingMode = .easeInEaseOut, completion: (() -> Void)? = nil) {
        camera.removeAllActions()
        stopDrift()
        isFlying = true
        let move = SKAction.move(to: state.position, duration: duration)
        move.timingMode = timing
        let zoom = SKAction.scale(to: state.scale, duration: duration)
        zoom.timingMode = timing
        camera.run(.sequence([.group([move, zoom]), .run { [weak self] in
            self?.isFlying = false
            completion?()
        }]), withKey: "fly")
    }

    // MARK: - Follow (gameplay)

    func startFollowing(heroX: CGFloat) {
        followTargetX = gameplayCameraX(heroX: heroX)
    }

    func stopFollowing() {
        followTargetX = nil
    }

    /// Called every frame by the scene while playing.
    func updateFollow(heroX: CGFloat, floor: Int, deltaTime: TimeInterval) {
        guard !isFlying, followTargetX != nil else { return }
        let targetX = gameplayCameraX(heroX: heroX)
        followTargetX = targetX
        let t = CGFloat(min(1, deltaTime * 4.5))
        camera.position.x += (targetX - camera.position.x) * t
        let targetY = gameplayCameraY(floor: floor)
        camera.position.y += (targetY - camera.position.y) * t
        let scale = gameplayScale()
        if abs(camera.xScale - scale) > 0.001 {
            camera.setScale(camera.xScale + (scale - camera.xScale) * t)
        }
    }

    // MARK: - Menu drift

    func startDrift(from base: State) {
        driftBase = base
        driftStart = nil
    }

    func stopDrift() {
        driftBase = nil
        driftStart = nil
    }

    var isDrifting: Bool { driftBase != nil }

    func updateDrift(currentTime: TimeInterval) {
        guard !isFlying, let base = driftBase else { return }
        if driftStart == nil { driftStart = currentTime }
        let t = currentTime - (driftStart ?? currentTime)
        let dx = CGFloat(sin(t * 0.16)) * 160
        let dy = CGFloat(cos(t * 0.11)) * 90
        let breathe = 1 + CGFloat(sin(t * 0.09)) * 0.035
        camera.position = CGPoint(x: base.position.x + dx, y: base.position.y + dy)
        camera.setScale(base.scale * breathe)
    }
}
