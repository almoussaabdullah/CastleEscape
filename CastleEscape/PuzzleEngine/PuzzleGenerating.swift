import Foundation

/// Every puzzle category is produced by a generator conforming to this protocol.
/// Generators are pure: same seed + difficulty => same puzzle.
protocol PuzzleGenerating {
    var category: PuzzleCategory { get }
    func generate(difficulty: Int, rng: inout SeededRandom) -> Puzzle
}

/// Shared helpers for building unique answer sets.
enum ChoiceBuilder {
    /// Builds text choices from a correct value plus numeric distractors.
    /// Guarantees the correct value is present exactly once and there are no duplicates.
    static func numericChoices(correct: Int,
                               count: Int,
                               rng: inout SeededRandom,
                               spread: Int,
                               allowNegative: Bool = false,
                               formatter: (Int) -> String = { String($0) }) -> (choices: [PuzzleChoice], correctID: Int) {
        var values = Set<Int>([correct])
        var attempts = 0
        while values.count < count && attempts < 200 {
            attempts += 1
            let delta = rng.int(in: 1...max(1, spread)) * (rng.chance(0.5) ? 1 : -1)
            let candidate = correct + delta
            if !allowNegative && candidate < 0 { continue }
            values.insert(candidate)
        }
        // Fallback: widen deterministically if the spread was too tight.
        var extra = 1
        while values.count < count {
            let candidate = correct + spread + extra
            if allowNegative || candidate >= 0 { values.insert(candidate) }
            extra += 1
        }
        let ordered = rng.shuffled(Array(values))
        var correctID = 0
        let choices = ordered.enumerated().map { index, value -> PuzzleChoice in
            if value == correct { correctID = index }
            return PuzzleChoice(id: index, text: formatter(value))
        }
        return (choices, correctID)
    }

    /// Builds text choices from arbitrary unique strings, shuffled.
    static func textChoices(correct: LocalizedText,
                            distractors: [LocalizedText],
                            rng: inout SeededRandom) -> (choices: [PuzzleChoice], correctID: Int) {
        var all = [correct]
        for d in distractors where !all.contains(d) { all.append(d) }
        let ordered = rng.shuffled(all)
        var correctID = 0
        let choices = ordered.enumerated().map { index, text -> PuzzleChoice in
            if text == correct { correctID = index }
            return PuzzleChoice(id: index, label: text)
        }
        return (choices, correctID)
    }
}

/// Difficulty helpers shared by generators.
enum DifficultyBand {
    static func clamp(_ difficulty: Int) -> Int { min(10, max(1, difficulty)) }

    /// A generous default time limit that shrinks as difficulty rises.
    static func timeLimit(for difficulty: Int, base: Double = 24, floor: Double = 10) -> Double {
        max(floor, base - Double(clamp(difficulty) - 1) * 1.4)
    }

    static func reward(for difficulty: Int, base: Int = 100) -> Int {
        base + (clamp(difficulty) - 1) * 10
    }
}

/// Produces Arabic-friendly plain digits; the game keeps Western digits in both languages
/// so mathematical expressions never need reshaping.
enum NumberText {
    static func string(_ value: Int) -> String { String(value) }
}
