import SpriteKit
import UIKit

/// Original colour palette for the castle world (night, torchlight, dawn).
enum GamePalette {
    // Sky
    static let nightTop = UIColor(red: 0.04, green: 0.05, blue: 0.16, alpha: 1)
    static let nightBottom = UIColor(red: 0.16, green: 0.17, blue: 0.40, alpha: 1)
    static let dawnTop = UIColor(red: 0.36, green: 0.42, blue: 0.70, alpha: 1)
    static let dawnBottom = UIColor(red: 1.00, green: 0.66, blue: 0.42, alpha: 1)
    static let moon = UIColor(red: 0.99, green: 0.96, blue: 0.84, alpha: 1)
    static let star = UIColor(red: 1.0, green: 1.0, blue: 0.94, alpha: 1)

    // Landscape
    static let mountainFar = UIColor(red: 0.14, green: 0.16, blue: 0.33, alpha: 1)
    static let mountainMid = UIColor(red: 0.10, green: 0.12, blue: 0.26, alpha: 1)
    static let mountainNear = UIColor(red: 0.07, green: 0.08, blue: 0.19, alpha: 1)
    static let forest = UIColor(red: 0.05, green: 0.10, blue: 0.14, alpha: 1)
    static let rock = UIColor(red: 0.19, green: 0.19, blue: 0.27, alpha: 1)
    static let rockDark = UIColor(red: 0.12, green: 0.12, blue: 0.19, alpha: 1)
    static let fog = UIColor(red: 0.72, green: 0.76, blue: 0.92, alpha: 1)

    // Castle
    static let stone = UIColor(red: 0.42, green: 0.45, blue: 0.56, alpha: 1)
    static let stoneLight = UIColor(red: 0.56, green: 0.59, blue: 0.70, alpha: 1)
    static let stoneDark = UIColor(red: 0.24, green: 0.26, blue: 0.36, alpha: 1)
    static let stoneShadow = UIColor(red: 0.15, green: 0.16, blue: 0.25, alpha: 1)
    static let roof = UIColor(red: 0.52, green: 0.18, blue: 0.24, alpha: 1)
    static let roofDark = UIColor(red: 0.36, green: 0.11, blue: 0.16, alpha: 1)
    static let flag = UIColor(red: 0.90, green: 0.22, blue: 0.28, alpha: 1)
    static let flagGold = UIColor(red: 0.98, green: 0.78, blue: 0.30, alpha: 1)
    static let wood = UIColor(red: 0.45, green: 0.29, blue: 0.16, alpha: 1)
    static let woodDark = UIColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1)
    static let iron = UIColor(red: 0.30, green: 0.32, blue: 0.38, alpha: 1)
    static let ironLight = UIColor(red: 0.55, green: 0.58, blue: 0.66, alpha: 1)

    // Light
    static let torch = UIColor(red: 1.0, green: 0.70, blue: 0.30, alpha: 1)
    static let torchCore = UIColor(red: 1.0, green: 0.92, blue: 0.62, alpha: 1)
    static let windowDark = UIColor(red: 0.08, green: 0.09, blue: 0.20, alpha: 1)
    static let windowLit = UIColor(red: 1.0, green: 0.78, blue: 0.38, alpha: 1)
    static let windowCurrent = UIColor(red: 1.0, green: 0.86, blue: 0.50, alpha: 1)
    static let windowCompleted = UIColor(red: 0.45, green: 0.95, blue: 0.62, alpha: 1)
    static let magic = UIColor(red: 0.55, green: 0.65, blue: 1.0, alpha: 1)
    static let magicPink = UIColor(red: 0.95, green: 0.45, blue: 0.85, alpha: 1)

    // Characters
    static let skin = UIColor(red: 0.98, green: 0.84, blue: 0.70, alpha: 1)
    static let hair = UIColor(red: 0.42, green: 0.26, blue: 0.13, alpha: 1)
    static let tunic = UIColor(red: 0.22, green: 0.47, blue: 0.90, alpha: 1)
    static let tunicDark = UIColor(red: 0.15, green: 0.33, blue: 0.68, alpha: 1)
    static let scarf = UIColor(red: 0.90, green: 0.22, blue: 0.26, alpha: 1)
    static let boots = UIColor(red: 0.40, green: 0.25, blue: 0.14, alpha: 1)
    static let backpack = UIColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1)
    static let armor = UIColor(red: 0.58, green: 0.62, blue: 0.70, alpha: 1)
    static let armorDark = UIColor(red: 0.36, green: 0.40, blue: 0.48, alpha: 1)
    static let guardCloth = UIColor(red: 0.55, green: 0.18, blue: 0.22, alpha: 1)
    static let shieldRed = UIColor(red: 0.75, green: 0.20, blue: 0.22, alpha: 1)
    static let eyeWhite = UIColor.white
    static let pupil = UIColor(red: 0.12, green: 0.10, blue: 0.14, alpha: 1)
    static let success = UIColor(red: 0.42, green: 0.90, blue: 0.56, alpha: 1)
    static let danger = UIColor(red: 1.0, green: 0.32, blue: 0.32, alpha: 1)

    static func color(for tint: PuzzleSymbol.Tint) -> UIColor {
        let c = tint.rgb
        return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: 1)
    }
}
