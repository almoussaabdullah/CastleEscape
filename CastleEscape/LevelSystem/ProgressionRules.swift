import Foundation

/// Pure rules describing how a floor run converts into progress.
enum ProgressionRules {
    /// Stars awarded for a completed floor based on mistakes made.
    static func stars(forMistakes mistakes: Int) -> Int {
        switch mistakes {
        case 0: return 3
        case 1: return 2
        default: return 1
        }
    }

    /// Coins earned by a completed floor.
    static func coins(forFloor floor: Int, stars: Int, config: ScoreConfig) -> Int {
        config.floorCompletionCoins + stars * config.coinsPerStar + (FloorCatalog.topFloor - floor) * 5
    }

    /// Accuracy in 0...1.
    static func accuracy(correct: Int, attempted: Int) -> Double {
        guard attempted > 0 else { return 0 }
        return Double(correct) / Double(attempted)
    }
}

/// Unlockable achievements. Conditions are evaluated by `AchievementTracker`.
struct Achievement: Identifiable, Equatable {
    let id: String
    let title: LocalizedText
    let detail: LocalizedText
    let systemImageName: String

    static let all: [Achievement] = [
        Achievement(id: "first_light", title: LocalizedText(ar: "أول شعاع", en: "First Light"),
                    detail: LocalizedText(ar: "حُلَّ أول لغز", en: "Solve your first puzzle"), systemImageName: "sparkle"),
        Achievement(id: "tower_breaker", title: LocalizedText(ar: "كاسر البرج", en: "Tower Breaker"),
                    detail: LocalizedText(ar: "أكمل برج السجن", en: "Complete the Prison Tower"), systemImageName: "building.columns"),
        Achievement(id: "combo_ten", title: LocalizedText(ar: "عقل متّقد", en: "On Fire"),
                    detail: LocalizedText(ar: "عشر إجابات صحيحة متتالية", en: "Ten correct answers in a row"), systemImageName: "flame.fill"),
        Achievement(id: "flawless_floor", title: LocalizedText(ar: "بلا خطأ", en: "Flawless"),
                    detail: LocalizedText(ar: "أكمل طابقًا دون أي خطأ", en: "Complete a floor without a single mistake"), systemImageName: "checkmark.seal.fill"),
        Achievement(id: "halfway", title: LocalizedText(ar: "منتصف الطريق", en: "Halfway There"),
                    detail: LocalizedText(ar: "الوصول إلى الطابق الخامس", en: "Reach the fifth floor"), systemImageName: "figure.stairs"),
        Achievement(id: "score_5000", title: LocalizedText(ar: "خمسة آلاف", en: "Five Thousand"),
                    detail: LocalizedText(ar: "اجمع 5000 نقطة", en: "Collect 5,000 points"), systemImageName: "star.circle.fill"),
        Achievement(id: "puzzles_50", title: LocalizedText(ar: "خمسون لغزًا", en: "Fifty Puzzles"),
                    detail: LocalizedText(ar: "حُلَّ خمسين لغزًا", en: "Solve fifty puzzles"), systemImageName: "puzzlepiece.extension.fill"),
        Achievement(id: "escaped", title: LocalizedText(ar: "حرّ أخيرًا", en: "Free at Last"),
                    detail: LocalizedText(ar: "الهروب من القلعة", en: "Escape the castle"), systemImageName: "sunrise.fill"),
    ]

    static func named(_ id: String) -> Achievement? { all.first { $0.id == id } }
}

/// Evaluates achievement conditions against the saved progress.
enum AchievementTracker {
    /// Returns newly unlocked achievement IDs (not previously in `progress.achievements`).
    static func evaluate(progress: GameProgress, currentCombo: Int, lastFloorMistakes: Int?) -> [String] {
        var unlocked: [String] = []
        func unlock(_ id: String, when condition: Bool) {
            if condition && !progress.achievements.contains(id) && !unlocked.contains(id) { unlocked.append(id) }
        }
        unlock("first_light", when: progress.totalPuzzlesSolved >= 1)
        unlock("tower_breaker", when: progress.completedFloors[10] != nil)
        unlock("combo_ten", when: currentCombo >= 10)
        unlock("flawless_floor", when: (lastFloorMistakes ?? 1) == 0)
        unlock("halfway", when: progress.completedFloors[6] != nil)
        unlock("score_5000", when: progress.totalScore >= 5000)
        unlock("puzzles_50", when: progress.totalPuzzlesSolved >= 50)
        unlock("escaped", when: progress.hasEscaped)
        return unlocked
    }
}
