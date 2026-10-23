import Foundation

/// Arithmetic puzzles: addition and subtraction at low difficulty, then
/// multiplication, division and two-step expressions.
struct MathPuzzleGenerator: PuzzleGenerating {
    let category: PuzzleCategory = .mathematics

    enum Operation: String, CaseIterable {
        case add, subtract, multiply, divide, twoStep
    }

    /// Restricts the generator to a subset of operations (e.g. Floor 10 only uses +/-).
    var allowedOperations: [Operation]

    init(allowedOperations: [Operation] = Operation.allCases) {
        self.allowedOperations = allowedOperations
    }

    func generate(difficulty: Int, rng: inout SeededRandom) -> Puzzle {
        let d = DifficultyBand.clamp(difficulty)
        let pool = operations(for: d)
        let op = rng.pick(pool)

        let (expression, result) = build(op: op, difficulty: d, rng: &rng)
        let spread = max(2, min(12, 2 + d * 2))
        let (choices, correctID) = ChoiceBuilder.numericChoices(correct: result, count: 4, rng: &rng, spread: spread)

        return Puzzle(id: "math-\(op.rawValue)-\(rng.next())",
                      category: .mathematics,
                      difficulty: d,
                      question: LocalizedText(ar: "ما ناتج العملية الحسابية؟", en: "What is the result?"),
                      expression: expression + " = ?",
                      choices: choices,
                      answer: .single(choiceID: correctID),
                      explanation: LocalizedText(ar: "\(expression) = \(result)", en: "\(expression) = \(result)"),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 26, floor: 12),
                      reward: DifficultyBand.reward(for: d))
    }

    private func operations(for difficulty: Int) -> [Operation] {
        var pool: [Operation]
        switch difficulty {
        case 1...2: pool = [.add, .subtract]
        case 3...4: pool = [.add, .subtract, .multiply]
        case 5...6: pool = [.add, .subtract, .multiply, .divide]
        default: pool = Operation.allCases
        }
        let filtered = pool.filter { allowedOperations.contains($0) }
        return filtered.isEmpty ? allowedOperations : filtered
    }

    private func build(op: Operation, difficulty d: Int, rng: inout SeededRandom) -> (String, Int) {
        switch op {
        case .add:
            let maxValue = 8 + d * 9
            let a = rng.int(in: 1...maxValue)
            let b = rng.int(in: 1...maxValue)
            return ("\(a) + \(b)", a + b)
        case .subtract:
            let maxValue = 8 + d * 9
            let a = rng.int(in: 2...maxValue)
            let b = rng.int(in: 1...a)
            return ("\(a) − \(b)", a - b)
        case .multiply:
            let hi = min(12, 3 + d)
            let a = rng.int(in: 2...hi)
            let b = rng.int(in: 2...hi)
            return ("\(a) × \(b)", a * b)
        case .divide:
            let hi = min(12, 3 + d)
            let b = rng.int(in: 2...hi)
            let q = rng.int(in: 2...hi)
            return ("\(b * q) ÷ \(b)", q)
        case .twoStep:
            let a = rng.int(in: 2...(4 + d))
            let b = rng.int(in: 2...(4 + d))
            let c = rng.int(in: 1...(10 + d * 2))
            if rng.chance(0.5) {
                return ("\(a) × \(b) + \(c)", a * b + c)
            } else {
                let product = a * b
                let sub = min(c, product)
                return ("\(a) × \(b) − \(sub)", product - sub)
            }
        }
    }
}
