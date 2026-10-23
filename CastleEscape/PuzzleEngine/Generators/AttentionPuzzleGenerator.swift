import Foundation

/// Visual attention: a grid of near-identical symbols with exactly one odd symbol.
struct AttentionPuzzleGenerator: PuzzleGenerating {
    let category: PuzzleCategory = .visualAttention

    func generate(difficulty: Int, rng: inout SeededRandom) -> Puzzle {
        let d = DifficultyBand.clamp(difficulty)
        let columns: Int
        let rows: Int
        switch d {
        case 1...3: columns = 3; rows = 3
        case 4...6: columns = 4; rows = 3
        default: columns = 4; rows = 4
        }
        let count = columns * rows

        let baseShape = rng.pick(PuzzleSymbol.Shape.allCases)
        let baseTint = rng.pick(PuzzleSymbol.Tint.allCases)
        let base = PuzzleSymbol(shape: baseShape, tint: baseTint)

        // Harder floors differ only by tint, which is subtler than a shape change.
        let differByTint = d >= 5 || rng.chance(0.35)
        let odd: PuzzleSymbol
        if differByTint {
            let otherTints = PuzzleSymbol.Tint.allCases.filter { $0 != baseTint }
            odd = PuzzleSymbol(shape: baseShape, tint: rng.pick(otherTints))
        } else {
            let otherShapes = PuzzleSymbol.Shape.allCases.filter { $0 != baseShape }
            odd = PuzzleSymbol(shape: rng.pick(otherShapes), tint: baseTint)
        }

        let oddIndex = rng.int(in: 0...(count - 1))
        // Grid tiles intentionally share the same glyph; give each a unique label so the
        // structural checks (no duplicate visible answers) still hold.
        let choices = (0..<count).map { index -> PuzzleChoice in
            let symbol = index == oddIndex ? odd : base
            return PuzzleChoice(id: index,
                                label: LocalizedText(ar: "الخانة \(index + 1)", en: "Tile \(index + 1)"),
                                symbol: symbol)
        }

        return Puzzle(id: "attention-\(columns)x\(rows)-\(rng.next())",
                      category: .visualAttention,
                      difficulty: d,
                      question: LocalizedText(ar: "اختر الرمز المختلف", en: "Tap the odd one out"),
                      choices: choices,
                      answer: .single(choiceID: oddIndex),
                      explanation: LocalizedText(ar: "الرمز المختلف هو \(odd.localizedName.ar)", en: "The different symbol is the \(odd.localizedName.en)"),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 18, floor: 7),
                      reward: DifficultyBand.reward(for: d, base: 110),
                      presentation: .symbolGrid(columns: columns))
    }
}
