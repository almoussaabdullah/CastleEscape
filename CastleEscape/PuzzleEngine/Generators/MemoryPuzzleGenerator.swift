import Foundation

/// Visual memory: a sequence of colored symbols is revealed, hidden, and the
/// player must tap the symbols back in the same order.
struct MemoryPuzzleGenerator: PuzzleGenerating {
    let category: PuzzleCategory = .visualMemory

    func generate(difficulty: Int, rng: inout SeededRandom) -> Puzzle {
        let d = DifficultyBand.clamp(difficulty)
        let length = min(6, 3 + (d - 1) / 3)           // 3 ... 6 symbols
        let distractorCount = d >= 4 ? 2 : 1
        let total = length + distractorCount

        // Unique symbols: never repeat a shape+tint pair inside one puzzle.
        var pool: [PuzzleSymbol] = []
        for shape in PuzzleSymbol.Shape.allCases {
            for tint in PuzzleSymbol.Tint.allCases {
                pool.append(PuzzleSymbol(shape: shape, tint: tint))
            }
        }
        let picked = Array(rng.shuffled(pool).prefix(total))
        let sequence = Array(picked.prefix(length))

        let shuffled = rng.shuffled(picked)
        let choices = shuffled.enumerated().map { index, symbol in PuzzleChoice(id: index, symbol: symbol) }
        let orderedIDs: [Int] = sequence.map { symbol in choices.first { $0.symbol == symbol }!.id }

        let reveal = max(2.0, 1.2 + Double(length) * 0.55 - Double(d) * 0.08)
        return Puzzle(id: "memory-\(length)-\(rng.next())",
                      category: .visualMemory,
                      difficulty: d,
                      question: LocalizedText(ar: "احفظ الرموز بالترتيب ثم أعد ترتيبها",
                                              en: "Memorize the symbols, then tap them in the same order"),
                      choices: choices,
                      answer: .ordered(choiceIDs: orderedIDs),
                      explanation: LocalizedText(ar: "الترتيب الصحيح: " + sequence.map { $0.localizedName.ar }.joined(separator: "، "),
                                                 en: "Correct order: " + sequence.map { $0.localizedName.en }.joined(separator: ", ")),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 30, floor: 16),
                      reward: DifficultyBand.reward(for: d, base: 120),
                      presentation: .memorySequence(sequence: sequence, revealSeconds: reveal))
    }
}
