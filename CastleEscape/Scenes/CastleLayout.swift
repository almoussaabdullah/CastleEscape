import CoreGraphics
import Foundation

/// World-space geometry shared by the exterior castle, the interior floors and the camera.
///
/// One world unit equals one point when the camera scale is 1. The castle's ten floors are
/// stacked vertically so that zooming the camera into a window lands exactly on that floor's
/// interior — the castle is a single, physically continuous environment.
enum CastleLayout {
    static let floorCount = 10

    /// Vertical distance between the floor surfaces of two consecutive floors.
    static let floorHeight: CGFloat = 520
    /// Height of the walkable room (floor surface to ceiling).
    static let roomHeight: CGFloat = 440
    /// Stone slab between a ceiling and the floor above.
    static let slabThickness: CGFloat = 80
    /// Dark foundation drawn under each floor; it sits behind the puzzle panel.
    static let foundationDepth: CGFloat = 520

    static let keepHalfWidth: CGFloat = 850
    static let keepWidth: CGFloat = keepHalfWidth * 2

    /// Position of a floor's main window, relative to the floor's local origin
    /// (origin = horizontal keep centre, floor surface).
    static let windowLocalX: CGFloat = -520
    static let windowLocalY: CGFloat = 250
    static let windowSize = CGSize(width: 96, height: 150)

    static let heroStartX: CGFloat = -420
    static let doorApproachX: CGFloat = 560
    static let exitDoorX: CGFloat = 690
    static let doorWidth: CGFloat = 130
    static let doorHeight: CGFloat = 210

    /// Camera zoom used while playing inside a room.
    static let gameplayCameraScale: CGFloat = 1.25
    /// Camera zoom at the window right before the interior fades in.
    static let windowCameraScale: CGFloat = 2.6
    /// How far ahead of the hero the camera looks (negative keeps the guard in frame).
    static let cameraLookAhead: CGFloat = -30

    // Towers and roofs
    static let sideTowerX: CGFloat = 1180
    static let sideTowerHalfWidth: CGFloat = 190
    static let sideTowerTopFloor = 8
    static let turretHalfWidth: CGFloat = 250
    static let turretHeight: CGFloat = 520
    static let roofHeight: CGFloat = 420

    /// Rock plateau the castle sits on.
    static let rockBottomY: CGFloat = -1_050
    static let bridgeEndX: CGFloat = -2_450

    // MARK: Derived helpers

    /// Y of the floor surface for a given floor (1...10). Floor 1 is at zero.
    static func floorBaseY(_ floor: Int) -> CGFloat { CGFloat(floor - 1) * floorHeight }

    static func floorCenterY(_ floor: Int) -> CGFloat { floorBaseY(floor) + roomHeight / 2 }

    static func windowWorldPosition(floor: Int) -> CGPoint {
        CGPoint(x: windowLocalX, y: floorBaseY(floor) + windowLocalY)
    }

    /// Local origin of a floor's interior node in world space.
    static func interiorOrigin(floor: Int) -> CGPoint { CGPoint(x: 0, y: floorBaseY(floor)) }

    static var keepTopY: CGFloat { floorBaseY(floorCount + 1) }
    static var turretTopY: CGFloat { keepTopY + turretHeight }
    static var castleTopY: CGFloat { turretTopY + roofHeight + 120 }

    /// Rectangle enclosing everything the overview camera should frame.
    static var overviewBounds: CGRect {
        CGRect(x: -(sideTowerX + sideTowerHalfWidth + 420), y: rockBottomY,
               width: (sideTowerX + sideTowerHalfWidth + 420) * 2, height: castleTopY - rockBottomY)
    }

    /// Horizontal checkpoints for a floor with `count` encounters.
    /// Index 0 is the start, index `count` is the door approach.
    static func checkpoints(count: Int) -> [CGFloat] {
        guard count > 0 else { return [heroStartX, doorApproachX] }
        let segment = (doorApproachX - heroStartX) / CGFloat(count)
        return (0...count).map { heroStartX + CGFloat($0) * segment }
    }

    /// Where obstacle `index` (0-based) stands: just before checkpoint `index + 1`.
    static func obstacleX(index: Int, count: Int) -> CGFloat {
        let points = checkpoints(count: count)
        let segment = points[1] - points[0]
        return points[index + 1] - segment * 0.42
    }

    /// Gap between hero and guard for a danger level (0 = safe ... max = caught).
    static func guardGap(dangerLevel: Int, maxDanger: Int) -> CGFloat {
        let safeGap: CGFloat = 290
        let fraction = 1 - CGFloat(min(dangerLevel, maxDanger)) / CGFloat(max(1, maxDanger))
        return 70 + (safeGap - 70) * fraction
    }
}
