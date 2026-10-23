import SpriteKit

/// Screen-fixed sky: gradient, stars, moon and the dawn overlay used by the victory scene.
/// Added as a child of the camera so it never moves with the world.
final class SkyNode: SKNode {
    private let night: SKSpriteNode
    private let dawn: SKSpriteNode
    private let moon = SKNode()
    private let sun = SKNode()
    private let stars = SKNode()
    private var viewSize: CGSize = .zero

    override init() {
        night = SKSpriteNode(texture: TextureCache.gradient(width: 4, height: 256, colors: [GamePalette.nightTop, GamePalette.nightBottom], key: "sky.night"))
        dawn = SKSpriteNode(texture: TextureCache.gradient(width: 4, height: 256, colors: [GamePalette.dawnTop, GamePalette.dawnBottom], key: "sky.dawn"))
        super.init()
        zPosition = -1_000
        night.zPosition = 0
        dawn.zPosition = 1
        dawn.alpha = 0
        addChild(night)
        addChild(dawn)

        stars.zPosition = 2
        addChild(stars)

        let moonGlow = ShapeFactory.glow(radius: 150, color: GamePalette.moon, alpha: 0.5)
        let moonDisc = ShapeFactory.circle(radius: 42, fill: GamePalette.moon)
        let crater1 = ShapeFactory.circle(radius: 7, fill: GamePalette.moon.withAlphaComponent(0.6))
        crater1.position = CGPoint(x: -12, y: 10)
        crater1.fillColor = UIColor(red: 0.90, green: 0.86, blue: 0.72, alpha: 1)
        let crater2 = ShapeFactory.circle(radius: 5, fill: UIColor(red: 0.90, green: 0.86, blue: 0.72, alpha: 1))
        crater2.position = CGPoint(x: 14, y: -8)
        moon.addChild(moonGlow)
        moon.addChild(moonDisc)
        moon.addChild(crater1)
        moon.addChild(crater2)
        moon.zPosition = 3
        addChild(moon)

        let sunGlow = ShapeFactory.glow(radius: 260, color: UIColor(red: 1, green: 0.8, blue: 0.5, alpha: 1), alpha: 0.7)
        let sunDisc = ShapeFactory.circle(radius: 48, fill: UIColor(red: 1, green: 0.93, blue: 0.70, alpha: 1))
        sun.addChild(sunGlow)
        sun.addChild(sunDisc)
        sun.zPosition = 3
        sun.alpha = 0
        addChild(sun)
    }

    required init?(coder aDecoder: NSCoder) { nil }

    func layout(viewSize: CGSize) {
        guard viewSize != self.viewSize else { return }
        self.viewSize = viewSize
        night.size = viewSize
        dawn.size = viewSize
        moon.position = CGPoint(x: viewSize.width * 0.28, y: viewSize.height * 0.34)
        sun.position = CGPoint(x: viewSize.width * 0.1, y: -viewSize.height * 0.55)
        stars.removeAllChildren()
        var rng = SeededRandom(seed: 99)
        for _ in 0..<90 {
            let star = ShapeFactory.circle(radius: CGFloat(rng.int(in: 1...3)) * 0.6, fill: GamePalette.star)
            star.position = CGPoint(x: CGFloat(rng.int(in: -500...500)) / 1_000 * viewSize.width,
                                    y: CGFloat(rng.int(in: -100...500)) / 1_000 * viewSize.height)
            star.alpha = CGFloat(rng.int(in: 30...100)) / 100
            stars.addChild(star)
            if rng.chance(0.3) {
                let twinkle = SKAction.sequence([.fadeAlpha(to: 0.2, duration: Double(rng.int(in: 8...25)) / 10), .fadeAlpha(to: 1, duration: Double(rng.int(in: 8...25)) / 10)])
                star.run(.repeatForever(twinkle))
            }
        }
    }

    /// Crossfades to a sunrise over `duration` seconds.
    func sunrise(duration: TimeInterval) {
        dawn.run(.fadeAlpha(to: 1, duration: duration))
        stars.run(.fadeAlpha(to: 0, duration: duration * 0.6))
        moon.run(.group([.fadeAlpha(to: 0, duration: duration * 0.7), .moveBy(x: 0, y: 120, duration: duration)]))
        let rise = SKAction.moveTo(y: viewSize.height * 0.12, duration: duration)
        rise.timingMode = .easeOut
        sun.run(.group([.fadeAlpha(to: 1, duration: duration * 0.5), rise]))
    }

    func resetToNight() {
        dawn.removeAllActions(); dawn.alpha = 0
        stars.removeAllActions(); stars.alpha = 1
        moon.removeAllActions(); moon.alpha = 1
        sun.removeAllActions(); sun.alpha = 0
        layoutMoonAndSun()
    }

    private func layoutMoonAndSun() {
        moon.position = CGPoint(x: viewSize.width * 0.28, y: viewSize.height * 0.34)
        sun.position = CGPoint(x: viewSize.width * 0.1, y: -viewSize.height * 0.55)
    }
}

/// Layered mountain ranges and forest behind the castle (world space).
final class MountainsNode: SKNode {
    override init() {
        super.init()
        zPosition = -50
        var rng = SeededRandom(seed: 7)
        addRange(baseY: -1_200, peakMin: 1_600, peakMax: 2_900, width: 14_000, color: GamePalette.mountainFar, z: -3, rng: &rng)
        addRange(baseY: -1_300, peakMin: 900, peakMax: 2_000, width: 12_000, color: GamePalette.mountainMid, z: -2, rng: &rng)
        addRange(baseY: -1_400, peakMin: 300, peakMax: 1_100, width: 11_000, color: GamePalette.mountainNear, z: -1, rng: &rng)
        // Snow caps on the far range.
    }

    required init?(coder aDecoder: NSCoder) { nil }

    private func addRange(baseY: CGFloat, peakMin: CGFloat, peakMax: CGFloat, width: CGFloat, color: UIColor, z: CGFloat, rng: inout SeededRandom) {
        var points: [CGPoint] = [CGPoint(x: -width / 2, y: baseY - 3_000)]
        var x = -width / 2
        points.append(CGPoint(x: x, y: baseY))
        while x < width / 2 {
            let step = CGFloat(rng.int(in: 500...1_100))
            let peak = CGFloat(rng.int(in: Int(peakMin)...Int(peakMax)))
            points.append(CGPoint(x: x + step / 2, y: baseY + peak))
            x += step
            points.append(CGPoint(x: x, y: baseY + CGFloat(rng.int(in: 0...300))))
        }
        points.append(CGPoint(x: width / 2, y: baseY - 3_000))
        let range = ShapeFactory.polygon(points, fill: color)
        range.zPosition = z
        addChild(range)
        if z == -3 {
            // Snow caps on tallest peaks.
            for i in stride(from: 2, to: points.count - 1, by: 2) where points[i].y > baseY + peakMax * 0.75 {
                let p = points[i]
                let cap = ShapeFactory.polygon([
                    CGPoint(x: p.x - 180, y: p.y - 260), CGPoint(x: p.x - 90, y: p.y - 200), CGPoint(x: p.x - 30, y: p.y - 250),
                    CGPoint(x: p.x + 30, y: p.y - 190), CGPoint(x: p.x + 100, y: p.y - 240), CGPoint(x: p.x + 180, y: p.y - 260), p,
                ], fill: UIColor(red: 0.80, green: 0.84, blue: 0.96, alpha: 0.9))
                cap.zPosition = z + 0.1
                addChild(cap)
            }
        }
    }
}

/// Drifting clouds between the mountains and the castle.
final class CloudLayerNode: SKNode {
    init(count: Int = 7) {
        super.init()
        zPosition = -20
        var rng = SeededRandom(seed: 21)
        for i in 0..<count {
            let cloud = SKSpriteNode(texture: TextureCache.texture("cloud_puff"))
            let scale = CGFloat(rng.int(in: 18...34)) / 10
            cloud.size = CGSize(width: 520 * scale, height: 260 * scale)
            cloud.alpha = CGFloat(rng.int(in: 18...40)) / 100
            cloud.color = GamePalette.fog
            cloud.colorBlendFactor = 0.6
            let y = CGFloat(rng.int(in: 1_800...6_400))
            let startX = CGFloat(-4_200) + CGFloat(i) * 1_200 + CGFloat(rng.int(in: -300...300))
            cloud.position = CGPoint(x: startX, y: y)
            cloud.zPosition = CGFloat(i)
            addChild(cloud)
            let travel: CGFloat = 8_400
            let duration = Double(rng.int(in: 240...420))
            let remaining = (4_200 - startX) / travel
            let firstLeg = SKAction.moveBy(x: 4_200 - startX, y: 0, duration: duration * Double(remaining))
            let loop = SKAction.repeatForever(.sequence([.moveTo(x: -4_200, duration: 0), .moveBy(x: travel, y: 0, duration: duration)]))
            cloud.run(.sequence([firstLeg, loop]))
        }
    }

    required init?(coder aDecoder: NSCoder) { nil }
}

/// Low fog hugging the rock and the bridge, gently breathing.
final class FogLayerNode: SKNode {
    override init() {
        super.init()
        zPosition = 30
        var rng = SeededRandom(seed: 5)
        for i in 0..<10 {
            let puff = SKSpriteNode(texture: TextureCache.texture("cloud_puff"))
            let w = CGFloat(rng.int(in: 1_400...2_600))
            puff.size = CGSize(width: w, height: w * 0.32)
            puff.alpha = CGFloat(rng.int(in: 10...22)) / 100
            puff.color = GamePalette.fog
            puff.colorBlendFactor = 0.5
            puff.position = CGPoint(x: CGFloat(rng.int(in: -3_200...2_200)), y: CGFloat(rng.int(in: -700...200)))
            puff.zPosition = CGFloat(i)
            addChild(puff)
            let drift = SKAction.sequence([
                .moveBy(x: CGFloat(rng.int(in: 120...320)), y: 0, duration: Double(rng.int(in: 14...26))),
                .moveBy(x: -CGFloat(rng.int(in: 120...320)), y: 0, duration: Double(rng.int(in: 14...26))),
            ])
            drift.timingMode = .easeInEaseOut
            puff.run(.repeatForever(drift))
            let breathe = SKAction.sequence([.fadeAlpha(by: 0.06, duration: Double(rng.int(in: 4...8))), .fadeAlpha(by: -0.06, duration: Double(rng.int(in: 4...8)))])
            puff.run(.repeatForever(breathe))
        }
    }

    required init?(coder aDecoder: NSCoder) { nil }
}
