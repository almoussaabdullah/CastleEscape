import Foundation

/// The ten floors of the castle, from the prison tower down to the main gate.
enum FloorCatalog {
    static let topFloor = 10
    static let bottomFloor = 1

    static let floors: [FloorDefinition] = [
        FloorDefinition(number: 10, theme: .prisonTower,
                        name: LocalizedText(ar: "برج السجن", en: "Prison Tower"),
                        tagline: LocalizedText(ar: "استيقظت في أعلى القلعة... الطريق الوحيد هو النزول", en: "You woke up at the very top... the only way out is down"),
                        encounterCount: 5,
                        recipe: PuzzleRecipe(entries: [.init(category: .mathematics, weight: 1)], baseDifficulty: 1, difficultyRamp: 0.34),
                        obstacles: [.lockedGate, .gap, .crates, .spikes, .lockedGate],
                        safetyMargin: 3),
        FloorDefinition(number: 9, theme: .guardBarracks,
                        name: LocalizedText(ar: "ثكنة الحرس", en: "Guard Barracks"),
                        tagline: LocalizedText(ar: "الحراس نائمون... فكّر بسرعة وبهدوء", en: "The guards are dozing... think fast and stay quiet"),
                        encounterCount: 6,
                        recipe: PuzzleRecipe(entries: [.init(category: .mathematics, weight: 2), .init(category: .quickThinking, weight: 3)], baseDifficulty: 2, difficultyRamp: 0.34),
                        obstacles: [.crates, .pendulum, .gap, .lockedGate, .spikes, .crates],
                        safetyMargin: 3),
        FloorDefinition(number: 8, theme: .ancientLibrary,
                        name: LocalizedText(ar: "المكتبة القديمة", en: "Ancient Library"),
                        tagline: LocalizedText(ar: "الكتب تهمس بالأنماط لمن يُحسن الإصغاء", en: "The books whisper patterns to those who listen"),
                        encounterCount: 6,
                        recipe: PuzzleRecipe(entries: [.init(category: .numberPatterns, weight: 3), .init(category: .logicalReasoning, weight: 1)], baseDifficulty: 3, difficultyRamp: 0.4),
                        obstacles: [.crates, .magicBarrier, .gap, .lockedGate, .crates, .magicBarrier],
                        safetyMargin: 3),
        FloorDefinition(number: 7, theme: .clockTower,
                        name: LocalizedText(ar: "برج الساعة", en: "Clock Tower"),
                        tagline: LocalizedText(ar: "كل ثانية تُقرّب الحارس خطوة", en: "Every second brings the guard one step closer"),
                        encounterCount: 6,
                        recipe: PuzzleRecipe(entries: [.init(category: .timeAndOrder, weight: 3), .init(category: .numberPatterns, weight: 1)], baseDifficulty: 4, difficultyRamp: 0.4),
                        obstacles: [.pendulum, .gap, .pendulum, .lockedGate, .spikes, .pendulum],
                        safetyMargin: 3),
        FloorDefinition(number: 6, theme: .alchemistLab,
                        name: LocalizedText(ar: "مختبر الخيميائي", en: "Alchemist Laboratory"),
                        tagline: LocalizedText(ar: "تذكّر الرموز قبل أن تتبخّر", en: "Remember the symbols before they evaporate"),
                        encounterCount: 6,
                        recipe: PuzzleRecipe(entries: [.init(category: .visualMemory, weight: 3), .init(category: .mathematics, weight: 1)], baseDifficulty: 4, difficultyRamp: 0.5),
                        obstacles: [.magicBarrier, .spikes, .magicBarrier, .gap, .crates, .magicBarrier],
                        safetyMargin: 3),
        FloorDefinition(number: 5, theme: .mirrorHall,
                        name: LocalizedText(ar: "قاعة المرايا", en: "Mirror Hall"),
                        tagline: LocalizedText(ar: "كل شيء يبدو متشابهًا... إلا واحدًا", en: "Everything looks the same... except one"),
                        encounterCount: 7,
                        recipe: PuzzleRecipe(entries: [.init(category: .visualAttention, weight: 3), .init(category: .quickThinking, weight: 1)], baseDifficulty: 5, difficultyRamp: 0.5),
                        obstacles: [.magicBarrier, .gap, .lockedGate, .magicBarrier, .spikes, .crates, .magicBarrier],
                        safetyMargin: 3),
        FloorDefinition(number: 4, theme: .secretCorridors,
                        name: LocalizedText(ar: "الممرات السرية", en: "Secret Corridors"),
                        tagline: LocalizedText(ar: "ثلاثة أبواب، وواحد فقط لا يقود إلى الحارس", en: "Three doors, and only one leads away from the guard"),
                        encounterCount: 7,
                        recipe: PuzzleRecipe(entries: [.init(category: .logicalReasoning, weight: 3), .init(category: .numberPatterns, weight: 1)], baseDifficulty: 6, difficultyRamp: 0.5),
                        obstacles: [.lockedGate, .spikes, .gap, .lockedGate, .pendulum, .magicBarrier, .lockedGate],
                        safetyMargin: 3),
        FloorDefinition(number: 3, theme: .armory,
                        name: LocalizedText(ar: "مستودع الأسلحة", en: "Armory"),
                        tagline: LocalizedText(ar: "عقلك هو سلاحك الوحيد هنا", en: "Your mind is the only weapon you need here"),
                        encounterCount: 7,
                        recipe: PuzzleRecipe(entries: [.init(category: .mathematics, weight: 2), .init(category: .numberPatterns, weight: 2), .init(category: .quickThinking, weight: 1)], baseDifficulty: 7, difficultyRamp: 0.5),
                        obstacles: [.crates, .pendulum, .spikes, .gap, .lockedGate, .crates, .pendulum],
                        safetyMargin: 3),
        FloorDefinition(number: 2, theme: .throneRoom,
                        name: LocalizedText(ar: "قاعة العرش", en: "Throne Room"),
                        tagline: LocalizedText(ar: "كل مهاراتك ستُختبر أمام العرش", en: "Every skill you have is tested before the throne"),
                        encounterCount: 8,
                        recipe: PuzzleRecipe(entries: [.init(category: .mathematics, weight: 1), .init(category: .numberPatterns, weight: 1), .init(category: .visualMemory, weight: 1), .init(category: .visualAttention, weight: 1), .init(category: .logicalReasoning, weight: 1), .init(category: .timeAndOrder, weight: 1)], baseDifficulty: 8, difficultyRamp: 0.3),
                        obstacles: [.magicBarrier, .lockedGate, .gap, .pendulum, .spikes, .crates, .magicBarrier, .lockedGate],
                        safetyMargin: 3),
        FloorDefinition(number: 1, theme: .mainGate,
                        name: LocalizedText(ar: "البوابة الرئيسية", en: "Main Castle Gate"),
                        tagline: LocalizedText(ar: "الحرية خلف البوابة... تحدٍّ أخير", en: "Freedom lies beyond the gate... one final challenge"),
                        encounterCount: 8,
                        recipe: PuzzleRecipe(entries: [.init(category: .mathematics, weight: 1), .init(category: .numberPatterns, weight: 1), .init(category: .visualMemory, weight: 1), .init(category: .visualAttention, weight: 1), .init(category: .logicalReasoning, weight: 1), .init(category: .quickThinking, weight: 1), .init(category: .timeAndOrder, weight: 1)], baseDifficulty: 9, difficultyRamp: 0.25),
                        obstacles: [.lockedGate, .spikes, .magicBarrier, .gap, .pendulum, .crates, .lockedGate, .magicBarrier],
                        safetyMargin: 3),
    ]

    static func floor(_ number: Int) -> FloorDefinition {
        floors.first { $0.number == number } ?? floors[0]
    }

    /// Floor reached after completing `number`; `nil` once the gate is passed.
    static func nextFloor(after number: Int) -> Int? {
        number > bottomFloor ? number - 1 : nil
    }

    /// Floors in play order (10 ... 1).
    static var playOrder: [FloorDefinition] { floors.sorted { $0.number > $1.number } }
}
