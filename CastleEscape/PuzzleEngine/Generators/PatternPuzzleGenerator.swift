import Foundation

/// "What comes next?" number sequences. Each rule is generated so that the
/// shown terms are consistent with exactly one intended continuation.
struct PatternPuzzleGenerator: PuzzleGenerating {
    let category: PuzzleCategory = .numberPatterns

    enum Rule: String, CaseIterable {
        case arithmetic, geometric, alternating, squares, fibonacciLike, descending
    }

    func generate(difficulty: Int, rng: inout SeededRandom) -> Puzzle {
        let d = DifficultyBand.clamp(difficulty)
        let rule = rng.pick(rules(for: d))
        let (terms, next, hint) = sequence(rule: rule, difficulty: d, rng: &rng)

        // Plausible but wrong continuations.
        var distractors = Set<Int>()
        let lastStep = terms[terms.count - 1] - terms[terms.count - 2]
        distractors.insert(terms.last! + lastStep + rng.int(in: 1...3))
        distractors.insert(terms.last! + max(1, abs(lastStep) / 2))
        distractors.insert(next + rng.int(in: 2...6))
        distractors.insert(next - rng.int(in: 1...4))
        distractors.remove(next)
        var candidates = rng.shuffled(Array(distractors.filter { $0 >= 0 })).prefix(3).map { $0 }
        var filler = 1
        while candidates.count < 3 {
            let value = next + 7 + filler
            if !candidates.contains(value) { candidates.append(value) }
            filler += 1
        }

        var values = candidates
        values.append(next)
        values = rng.shuffled(values)
        var correctID = 0
        let choices = values.enumerated().map { index, value -> PuzzleChoice in
            if value == next { correctID = index }
            return PuzzleChoice(id: index, text: String(value))
        }

        let shown = terms.map(String.init).joined(separator: ", ") + ", ?"
        return Puzzle(id: "pattern-\(rule.rawValue)-\(rng.next())",
                      category: .numberPatterns,
                      difficulty: d,
                      question: LocalizedText(ar: "ما الرقم التالي في النمط؟", en: "What number comes next?"),
                      expression: shown,
                      choices: choices,
                      answer: .single(choiceID: correctID),
                      explanation: hint,
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 30, floor: 14),
                      reward: DifficultyBand.reward(for: d, base: 110))
    }

    private func rules(for d: Int) -> [Rule] {
        switch d {
        case 1...2: return [.arithmetic, .descending]
        case 3...4: return [.arithmetic, .geometric, .descending]
        case 5...6: return [.arithmetic, .geometric, .alternating, .squares]
        default: return Rule.allCases
        }
    }

    private func sequence(rule: Rule, difficulty d: Int, rng: inout SeededRandom) -> ([Int], Int, LocalizedText) {
        let length = d >= 6 ? 5 : 4
        switch rule {
        case .arithmetic:
            let step = rng.int(in: 2...(2 + d))
            let start = rng.int(in: 1...(5 + d * 2))
            let terms = (0..<length).map { start + $0 * step }
            return (terms, start + length * step,
                    LocalizedText(ar: "يزيد كل رقم بمقدار \(step)", en: "Each number increases by \(step)"))
        case .geometric:
            let ratio = d >= 7 ? rng.int(in: 2...3) : 2
            let start = rng.int(in: 1...4)
            var terms: [Int] = []
            var value = start
            for _ in 0..<length { terms.append(value); value *= ratio }
            return (terms, value,
                    LocalizedText(ar: "يُضرب كل رقم في \(ratio)", en: "Each number is multiplied by \(ratio)"))
        case .alternating:
            let a = rng.int(in: 1...(2 + d))
            let b = rng.int(in: (a + 1)...(a + 3 + d))
            let start = rng.int(in: 1...10)
            var terms: [Int] = [start]
            for i in 0..<(length - 1) {
                terms.append(terms.last! + (i % 2 == 0 ? a : b))
            }
            let next = terms.last! + ((length - 1) % 2 == 0 ? a : b)
            return (terms, next,
                    LocalizedText(ar: "النمط يتناوب بين +\(a) و +\(b)", en: "The pattern alternates +\(a) and +\(b)"))
        case .squares:
            let start = rng.int(in: 1...3)
            let terms = (0..<length).map { (start + $0) * (start + $0) }
            let n = start + length
            return (terms, n * n,
                    LocalizedText(ar: "الأرقام مربعات كاملة", en: "The numbers are perfect squares"))
        case .fibonacciLike:
            let a = rng.int(in: 1...3)
            let b = rng.int(in: a...(a + 3))
            var terms = [a, b]
            while terms.count < length { terms.append(terms[terms.count - 1] + terms[terms.count - 2]) }
            let next = terms[terms.count - 1] + terms[terms.count - 2]
            return (terms, next,
                    LocalizedText(ar: "كل رقم هو مجموع الرقمين السابقين", en: "Each number is the sum of the previous two"))
        case .descending:
            let step = rng.int(in: 2...(2 + d))
            let start = step * (length + 2) + rng.int(in: 0...10)
            let terms = (0..<length).map { start - $0 * step }
            return (terms, start - length * step,
                    LocalizedText(ar: "ينقص كل رقم بمقدار \(step)", en: "Each number decreases by \(step)"))
        }
    }
}
