import SpriteKit
import UIKit

/// Small helpers that keep the procedural artwork code readable.
enum ShapeFactory {
    static func rect(_ rect: CGRect, fill: UIColor, stroke: UIColor? = nil, lineWidth: CGFloat = 0, corner: CGFloat = 0) -> SKShapeNode {
        let node = corner > 0 ? SKShapeNode(rect: rect, cornerRadius: corner) : SKShapeNode(rect: rect)
        node.fillColor = fill
        node.strokeColor = stroke ?? .clear
        node.lineWidth = stroke == nil ? 0 : lineWidth
        node.isAntialiased = true
        return node
    }

    static func rect(size: CGSize, fill: UIColor, stroke: UIColor? = nil, lineWidth: CGFloat = 0, corner: CGFloat = 0) -> SKShapeNode {
        rect(CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height),
             fill: fill, stroke: stroke, lineWidth: lineWidth, corner: corner)
    }

    static func circle(radius: CGFloat, fill: UIColor, stroke: UIColor? = nil, lineWidth: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke ?? .clear
        node.lineWidth = stroke == nil ? 0 : lineWidth
        node.isAntialiased = true
        return node
    }

    static func ellipse(size: CGSize, fill: UIColor) -> SKShapeNode {
        let node = SKShapeNode(ellipseOf: size)
        node.fillColor = fill
        node.strokeColor = .clear
        node.lineWidth = 0
        node.isAntialiased = true
        return node
    }

    static func polygon(_ points: [CGPoint], fill: UIColor, stroke: UIColor? = nil, lineWidth: CGFloat = 0) -> SKShapeNode {
        let path = CGMutablePath()
        guard let first = points.first else { return SKShapeNode() }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = fill
        node.strokeColor = stroke ?? .clear
        node.lineWidth = stroke == nil ? 0 : lineWidth
        node.isAntialiased = true
        return node
    }

    static func line(from: CGPoint, to: CGPoint, color: UIColor, width: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let node = SKShapeNode(path: path)
        node.strokeColor = color
        node.lineWidth = width
        node.lineCap = .round
        return node
    }

    /// Arched opening (rectangle with a semicircular top), origin at the bottom centre.
    static func archPath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let radius = width / 2
        path.move(to: CGPoint(x: -radius, y: 0))
        path.addLine(to: CGPoint(x: -radius, y: height - radius))
        path.addArc(center: CGPoint(x: 0, y: height - radius), radius: radius, startAngle: .pi, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: radius, y: 0))
        path.closeSubpath()
        return path
    }

    static func arch(width: CGFloat, height: CGFloat, fill: UIColor, stroke: UIColor? = nil, lineWidth: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(path: archPath(width: width, height: height))
        node.fillColor = fill
        node.strokeColor = stroke ?? .clear
        node.lineWidth = stroke == nil ? 0 : lineWidth
        node.isAntialiased = true
        return node
    }

    /// Soft additive glow sprite using the generated `glow_soft` texture.
    static func glow(radius: CGFloat, color: UIColor, alpha: CGFloat = 0.8) -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: TextureCache.texture("glow_soft"))
        sprite.size = CGSize(width: radius * 2, height: radius * 2)
        sprite.color = color
        sprite.colorBlendFactor = 1
        sprite.blendMode = .add
        sprite.alpha = alpha
        return sprite
    }

    /// Battlement (crenellation) strip along the top of a wall.
    static func crenellations(from startX: CGFloat, to endX: CGFloat, y: CGFloat, fill: UIColor, merlonWidth: CGFloat = 60, height: CGFloat = 70) -> SKNode {
        let container = SKNode()
        var x = startX
        var toggle = true
        while x + merlonWidth <= endX + 1 {
            if toggle {
                container.addChild(rect(CGRect(x: x, y: y, width: merlonWidth, height: height), fill: fill))
            }
            toggle.toggle()
            x += merlonWidth
        }
        return container
    }
}

/// Caches textures so tiled walls share one GPU texture.
enum TextureCache {
    private static var cache: [String: SKTexture] = [:]

    static func texture(_ name: String) -> SKTexture {
        if let cached = cache[name] { return cached }
        let texture = SKTexture(imageNamed: name)
        cache[name] = texture
        return texture
    }

    /// Vertical gradient texture rendered with Core Graphics; `colors[0]` is at the TOP of the texture.
    static func gradient(width: CGFloat, height: CGFloat, colors: [UIColor], key: String) -> SKTexture {
        if let cached = cache[key] { return cached }
        let size = CGSize(width: max(2, width), height: max(2, height))
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgColors = colors.map(\.cgColor) as CFArray
            let locations: [CGFloat] = colors.enumerated().map { CGFloat($0.offset) / CGFloat(max(1, colors.count - 1)) }
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) {
                context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
            }
        }
        let texture = SKTexture(image: image)
        cache[key] = texture
        return texture
    }
}

/// Fills a rectangle with repeated tiles of one texture (SpriteKit has no native tiling).
final class TiledTextureNode: SKNode {
    init(rect: CGRect, textureName: String, tileSize: CGFloat, tint: UIColor? = nil, tintStrength: CGFloat = 0) {
        super.init()
        let texture = TextureCache.texture(textureName)
        let columns = Int(ceil(rect.width / tileSize))
        let rows = Int(ceil(rect.height / tileSize))
        // Crop node keeps partial edge tiles inside the rectangle.
        let crop = SKCropNode()
        let mask = SKSpriteNode(color: .white, size: rect.size)
        mask.position = CGPoint(x: rect.midX, y: rect.midY)
        crop.maskNode = mask
        for row in 0..<rows {
            for column in 0..<columns {
                let sprite = SKSpriteNode(texture: texture)
                sprite.size = CGSize(width: tileSize, height: tileSize)
                sprite.anchorPoint = CGPoint(x: 0, y: 0)
                sprite.position = CGPoint(x: rect.minX + CGFloat(column) * tileSize, y: rect.minY + CGFloat(row) * tileSize)
                if let tint = tint, tintStrength > 0 {
                    sprite.color = tint
                    sprite.colorBlendFactor = tintStrength
                }
                crop.addChild(sprite)
            }
        }
        addChild(crop)
    }

    required init?(coder aDecoder: NSCoder) { nil }
}
