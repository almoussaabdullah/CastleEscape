import XCTest
@testable import CastleEscape

final class PuzzleValidationTests: XCTestCase {
    private func singlePuzzle() -> Puzzle {
        Puzzle(id: "t1", category: .mathematics, difficulty: 1,
               question: LocalizedText("5 + 7"), expression: "5 + 7 = ?",
               choices: [PuzzleChoice(id: 0, text: "11"), PuzzleChoice(id: 1, text: "12"), PuzzleChoice(id: 2, text: "13")],
               answer: .single(choiceID: 1), timeLimit: 10)
    }

    private func orderedPuzzle() -> Puzzle {
        let symbols = [PuzzleSymbol(shape: .star, tint: .gold), PuzzleSymbol(shape: .heart, tint: .ruby), PuzzleSymbol(shape: .moon, tint: .sapphire)]
        return Puzzle(id: "t2", category: .visualMemory, difficulty: 2,
                      question: LocalizedText("memory"),
                      choices: symbols.enumerated().map { PuzzleChoice(id: $0.offset, symbol: $0.element) } + [PuzzleChoice(id: 3, symbol: PuzzleSymbol(shape: .circle, tint: .teal))],
                      answer: .ordered(choiceIDs: [2, 0, 1]), timeLimit: nil,
                      presentation: .memorySequence(sequence: [symbols[2], symbols[0], symbols[1]], revealSeconds: 2))
    }

    func testSingleAnswerValidation() {
        let puzzle = singlePuzzle()
        XCTAssertTrue(PuzzleValidator.isCorrect(puzzle: puzzle, selection: [1]))
        XCTAssertFalse(PuzzleValidator.isCorrect(puzzle: puzzle, selection: [0]))
        XCTAssertFalse(PuzzleValidator.isCorrect(puzzle: puzzle, selection: []))
        XCTAssertFalse(PuzzleValidator.isCorrect(puzzle: puzzle, selection: [1, 1]))
    }

    func testOrderedAnswerValidation() {
        let puzzle = orderedPuzzle()
        XCTAssertTrue(PuzzleValidator.isCorrect(puzzle: puzzle, selection: [2, 0, 1]))
        XCTAssertFalse(PuzzleValidator.isCorrect(puzzle: puzzle, selection: [0, 2, 1]))
        XCTAssertFalse(PuzzleValidator.isCorrect(puzzle: puzzle, selection: [2, 0]))
    }

    func testOrderedPrefixValidation() {
        let puzzle = orderedPuzzle()
        XCTAssertTrue(PuzzleValidator.isPrefixValid(puzzle: puzzle, selection: []))
        XCTAssertTrue(PuzzleValidator.isPrefixValid(puzzle: puzzle, selection: [2]))
        XCTAssertTrue(PuzzleValidator.isPrefixValid(puzzle: puzzle, selection: [2, 0]))
        XCTAssertFalse(PuzzleValidator.isPrefixValid(puzzle: puzzle, selection: [0]))
        XCTAssertFalse(PuzzleValidator.isPrefixValid(puzzle: puzzle, selection: [2, 0, 1, 3]))
    }

    func testWellFormedRejectsDuplicateChoicesAndMissingAnswers() {
        let duplicate = Puzzle(id: "d", category: .mathematics, difficulty: 1, question: LocalizedText("q"),
                               choices: [PuzzleChoice(id: 0, text: "4"), PuzzleChoice(id: 1, text: "4")],
                               answer: .single(choiceID: 0), timeLimit: nil)
        XCTAssertFalse(duplicate.isWellFormed)
        let missing = Puzzle(id: "m", category: .mathematics, difficulty: 1, question: LocalizedText("q"),
                             choices: [PuzzleChoice(id: 0, text: "4"), PuzzleChoice(id: 1, text: "5")],
                             answer: .single(choiceID: 9), timeLimit: nil)
        XCTAssertFalse(missing.isWellFormed)
        XCTAssertTrue(singlePuzzle().isWellFormed)
        XCTAssertTrue(orderedPuzzle().isWellFormed)
    }

    func testChoiceBuilderNeverDuplicatesTheCorrectValue() {
        for seed in 0..<300 {
            var rng = SeededRandom(seed: UInt64(seed))
            let correct = rng.int(in: 0...50)
            let (choices, correctID) = ChoiceBuilder.numericChoices(correct: correct, count: 4, rng: &rng, spread: 1 + seed % 6)
            XCTAssertEqual(choices.count, 4)
            XCTAssertEqual(Set(choices.map(\.label.en)).count, 4)
            XCTAssertEqual(choices.first { $0.id == correctID }?.label.en, String(correct))
            XCTAssertTrue(choices.allSatisfy { Int($0.label.en)! >= 0 })
        }
    }

    func testLocalizedTextResolvesPerLanguage() {
        let text = LocalizedText(ar: "مرحبا", en: "Hello")
        XCTAssertEqual(text.resolved(.arabic), "مرحبا")
        XCTAssertEqual(text.resolved(.english), "Hello")
        XCTAssertEqual(LocalizedText("42").resolved(.arabic), "42")
    }
}
