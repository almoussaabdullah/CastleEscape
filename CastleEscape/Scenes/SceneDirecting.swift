import CoreGraphics
import Foundation

/// Rendering-side commands issued by the game session. Keeping gameplay state out of
/// SpriteKit (and rendering out of the session) means either side can be replaced or tested alone.
protocol SceneDirecting: AnyObject {
    /// Reflects saved progress on the castle windows.
    func applyProgress(statuses: [Int: FloorStatus], animated: Bool)
    /// Frames the whole castle. `menu` keeps the lower part of the screen free and drifts slowly.
    func showOverview(menu: Bool, animated: Bool)
    /// Cinematic zoom from the overview into the floor's window; the interior is ready on completion.
    func enterFloor(_ floor: FloorDefinition, completion: @escaping () -> Void)
    /// Hero reacts to a new puzzle (thinking pose).
    func heroThinks()
    /// Hero celebrates and clears obstacle `index`, ending at the next checkpoint. The guard follows.
    func heroAdvances(obstacleIndex: Int, dangerLevel: Int, maxDanger: Int, completion: @escaping () -> Void)
    /// Guard closes in after a mistake.
    func guardAdvances(dangerLevel: Int, maxDanger: Int, completion: @escaping () -> Void)
    /// Shield absorbed a mistake: guard looks confused instead of advancing.
    func guardConfused()
    /// Guard catches the hero.
    func guardCatches(completion: @escaping () -> Void)
    /// Re-places hero and guard (retry from the start or continue after a rewarded ad).
    func resetPositions(checkpoint: Int, dangerLevel: Int, maxDanger: Int)
    /// Combo celebration effects around the hero.
    func showCombo(multiplier: Double)
    func showShieldGained()
    /// Hero walks to the staircase and descends. Completion fires once the hero is gone.
    func exitFloor(completion: @escaping () -> Void)
    /// Zooms out, marks the floor completed and highlights the next one.
    func zoomOutAfterFloor(completedFloor: Int, statuses: [Int: FloorStatus], nextFloor: Int?, completion: @escaping () -> Void)
    /// The final escape: gate opens, hero runs across the bridge, sun rises.
    func playVictory(completion: @escaping () -> Void)
    /// Removes any interior and returns to the overview immediately (quit to castle).
    func abandonFloor()
    func setPaused(_ paused: Bool)
    /// Overlay thickness in points so the camera can frame the room between HUD and panel.
    func updateGameplayInsets(top: CGFloat, bottom: CGFloat)
    func updateMenuInsets(top: CGFloat, bottom: CGFloat)
}
