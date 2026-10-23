import XCTest
@testable import CastleEscape

final class PuzzleGenerationTests: XCTestCase {
    private let factory = PuzzleFactory()

    /// Every generator, every difficulty, many seeds: puzzles must be well formed.
    func testAllGeneratorsProduceWellFormedPuzzles() {
        for category in PuzzleCategory.allCases {
            for difficulty in 1...10 {
                for seed in 0..<40 {
                    var rng = SeededRandom(seed: UInt64(seed * 97 + difficulty))
                    let puzzle = factory.makePuzzle(category: category, difficulty: difficulty, rng: &rng)
                    XCTAssertTrue(puzzle.isWellFormed, "\(category) d\(difficulty) seed \(seed): \(puzzle.id)")
                    XCTAssertEqual(puzzle.category, category)
                    XCTAssertEqual(puzzle.difficulty, difficulty)
                    XCTAssertFalse(puzzle.question.ar.isEmpty)
                    XCTAssertFalse(puzzle.question.en.isEmpty)
                    XCTAssertGreaterThan(puzzle.reward, 0)
                    if let limit = puzzle.timeLimit { XCTAssertGreaterThan(limit, 0) }
                }
            }
        }
    }

    func testGenerationIsDeterministicForASeed() {
        var a = SeededRandom(seed: 42)
        var b = SeededRandom(seed: 42)
        let first = factory.makePuzzle(category: .mathematics, difficulty: 3, rng: &a)
        let second = factory.makePuzzle(category: .mathematics, difficulty: 3, rng: &b)
        XCTAssertEqual(first, second)
    }

    func testMathPuzzleAnswerMatchesExpression() {
        for seed in 0..<200 {
            var rng = SeededRandom(seed: UInt64(seed))
            let puzzle = MathPuzzleGenerator().generate(difficulty: 1 + seed % 10, rng: &rng)
            guard let expression = puzzle.expression?.replacingOccurrences(of: " = ?", with: "") else {
                return XCTFail("math puzzle without expression")
            }
            let expected = evaluate(expression)
            guard case .single(let id) = puzzle.answer, let choice = puzzle.choice(withID: id) else {
                return XCTFail("math puzzle without single answer")
            }
            XCTAssertEqual(Int(choice.label.en), expected, "expression \(expression)")
        }
    }

    func testFloorTenOnlyUsesAdditionAndSubtraction() {
        var rng = SeededRandom(seed: 7)
        let floor = FloorCatalog.floor(10)
        for _ in 0..<30 {
            let run = factory.makeRun(recipe: floor.recipe, count: floor.encounterCount, rng: &rng)
            for puzzle in run {
                XCTAssertEqual(puzzle.category, .mathematics)
                let expression = puzzle.expression ?? ""
                XCTAssertFalse(expression.contains("×"))
                XCTAssertFalse(expression.contains("÷"))
            }
        }
    }

    func testMemoryPuzzleSequenceSymbolsAreUniqueAndPresentInChoices() {
        for seed in 0..<100 {
            var rng = SeededRandom(seed: UInt64(seed))
            let puzzle = MemoryPuzzleGenerator().generate(difficulty: 1 + seed % 10, rng: &rng)
            guard case .memorySequence(let sequence, let reveal) = puzzle.presentation else { return XCTFail("wrong presentation") }
            XCTAssertEqual(Set(sequence.map(\.debugName)).count, sequence.count)
            XCTAssertGreaterThan(reveal, 1)
            guard case .ordered(let ids) = puzzle.answer else { return XCTFail("memory puzzles use ordered answers") }
            XCTAssertEqual(ids.count, sequence.count)
            for (id, symbol) in zip(ids, sequence) {
                XCTAssertEqual(puzzle.choice(withID: id)?.symbol, symbol)
            }
        }
    }

    func testAttentionPuzzleHasExactlyOneOddSymbol() {
        for seed in 0..<100 {
            var rng = SeededRandom(seed: UInt64(seed))
            let puzzle = AttentionPuzzleGenerator().generate(difficulty: 1 + seed % 10, rng: &rng)
            let symbols = puzzle.choices.compactMap(\.symbol)
            XCTAssertEqual(symbols.count, puzzle.choices.count)
            let counts = Dictionary(grouping: symbols, by: \.debugName).mapValues(\.count)
            XCTAssertEqual(counts.count, 2, "grid should contain a base symbol and one odd symbol")
            let oddName = counts.first { $0.value == 1 }?.key
            XCTAssertNotNil(oddName)
            guard case .single(let id) = puzzle.answer else { return XCTFail("single answer expected") }
            XCTAssertEqual(puzzle.choice(withID: id)?.symbol?.debugName, oddName)
        }
    }

    func testRunAvoidsRepeatingCategoriesWhenRecipeAllows() {
        var rng = SeededRandom(seed: 3)
        let floor = FloorCatalog.floor(9)
        let run = factory.makeRun(recipe: floor.recipe, count: 12, rng: &rng)
        for pair in zip(run, run.dropFirst()) {
            XCTAssertNotEqual(pair.0.category, pair.1.category)
        }
        XCTAssertEqual(Set(run.map(\.id)).count, run.count, "puzzle IDs must be unique")
    }

    func testRecipeDifficultyRampIsClamped() {
        let recipe = PuzzleRecipe(entries: [.init(category: .mathematics, weight: 1)], baseDifficulty: 9, difficultyRamp: 1)
        XCTAssertEqual(recipe.difficulty(forEncounter: 0), 9)
        XCTAssertEqual(recipe.difficulty(forEncounter: 1), 10)
        XCTAssertEqual(recipe.difficulty(forEncounter: 5), 10)
    }

    // MARK: - Helpers

    private func evaluate(_ expression: String) -> Int {
        // Supports "a op b" and "a × b op c" using the generator's operator glyphs.
        let tokens = expression.split(separator: " ").map(String.init)
        func apply(_ a: Int, _ op: String, _ b: Int) -> Int {
            switch op {
            case "+": return a + b
            case "−": return a - b
            case "×": return a * b
            case "÷": return a / b
            default: XCTFail("unknown operator \(op)"); return 0
            }
        }
        if tokens.count == 3, let a = Int(tokens[0]), let b = Int(tokens[2]) {
            return apply(a, tokens[1], b)
        }
        if tokens.count == 5, let a = Int(tokens[0]), let b = Int(tokens[2]), let c = Int(tokens[4]) {
            return apply(apply(a, tokens[1], b), tokens[3], c)
        }
        XCTFail("unexpected expression \(expression)")
        return 0
    }
}
