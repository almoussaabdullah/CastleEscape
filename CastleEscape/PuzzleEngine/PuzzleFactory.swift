import Foundation

/// Describes how a floor mixes puzzle categories.
struct PuzzleRecipe: Equatable {
    struct Entry: Equatable {
        let category: PuzzleCategory
        /// Relative weight when picking the category of the next encounter.
        let weight: Int
    }

    let entries: [Entry]
    /// Difficulty of the first encounter on the floor (1...10).
    let baseDifficulty: Int
    /// Added for every encounter so later rooms on the same floor get harder.
    let difficultyRamp: Double

    init(entries: [Entry], baseDifficulty: Int, difficultyRamp: Double = 0.5) {
        self.entries = entries
        self.baseDifficulty = baseDifficulty
        self.difficultyRamp = difficultyRamp
    }

    func difficulty(forEncounter index: Int) -> Int {
        DifficultyBand.clamp(baseDifficulty + Int((Double(index) * difficultyRamp).rounded(.down)))
    }
}

/// Central registry of generators. Floors ask the factory for a run of puzzles.
struct PuzzleFactory {
    private let generators: [PuzzleCategory: PuzzleGenerating]

    init(generators: [PuzzleGenerating] = PuzzleFactory.defaultGenerators) {
        var map: [PuzzleCategory: PuzzleGenerating] = [:]
        for generator in generators { map[generator.category] = generator }
        self.generators = map
    }

    static let defaultGenerators: [PuzzleGenerating] = [
        MathPuzzleGenerator(),
        PatternPuzzleGenerator(),
        MemoryPuzzleGenerator(),
        AttentionPuzzleGenerator(),
        LogicPuzzleGenerator(),
        QuickThinkingPuzzleGenerator(),
        TimePuzzleGenerator(),
    ]

    func generator(for category: PuzzleCategory) -> PuzzleGenerating {
        generators[category] ?? MathPuzzleGenerator()
    }

    /// Generates a single puzzle of the given category.
    func makePuzzle(category: PuzzleCategory, difficulty: Int, rng: inout SeededRandom) -> Puzzle {
        var attempts = 0
        while true {
            let puzzle = generator(for: category).generate(difficulty: difficulty, rng: &rng)
            if puzzle.isWellFormed || attempts >= 8 { return puzzle }
            attempts += 1
        }
    }

    /// Generates the ordered list of encounters for one floor run.
    /// Consecutive encounters avoid repeating the same category when the recipe allows it.
    func makeRun(recipe: PuzzleRecipe, count: Int, rng: inout SeededRandom) -> [Puzzle] {
        var puzzles: [Puzzle] = []
        var lastCategory: PuzzleCategory?
        for index in 0..<count {
            let category = pickCategory(recipe: recipe, avoiding: lastCategory, rng: &rng)
            let difficulty = recipe.difficulty(forEncounter: index)
            puzzles.append(makePuzzle(category: category, difficulty: difficulty, rng: &rng))
            lastCategory = category
        }
        return puzzles
    }

    private func pickCategory(recipe: PuzzleRecipe, avoiding last: PuzzleCategory?, rng: inout SeededRandom) -> PuzzleCategory {
        var entries = recipe.entries
        if entries.count > 1, let last = last {
            entries = entries.filter { $0.category != last }
        }
        let totalWeight = entries.reduce(0) { $0 + max(1, $1.weight) }
        var roll = rng.int(in: 1...max(1, totalWeight))
        for entry in entries {
            roll -= max(1, entry.weight)
            if roll <= 0 { return entry.category }
        }
        return entries.last?.category ?? .mathematics
    }
}

/// Validates player responses against a puzzle definition.
enum PuzzleValidator {
    /// `selection` holds choice IDs in the order the player tapped them.
    static func isCorrect(puzzle: Puzzle, selection: [Int]) -> Bool {
        switch puzzle.answer {
        case .single(let id):
            return selection.count == 1 && selection[0] == id
        case .ordered(let ids):
            return selection == ids
        }
    }

    /// True when the partial selection is still a valid prefix of an ordered answer.
    /// Used to give instant feedback as soon as the player taps a wrong symbol.
    static func isPrefixValid(puzzle: Puzzle, selection: [Int]) -> Bool {
        switch puzzle.answer {
        case .single(let id):
            return selection.isEmpty || (selection.count == 1 && selection[0] == id)
        case .ordered(let ids):
            guard selection.count <= ids.count else { return false }
            return Array(ids.prefix(selection.count)) == selection
        }
    }
}
