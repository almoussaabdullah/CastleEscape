import Foundation

/// The brain-training categories supported by the puzzle engine.
enum PuzzleCategory: String, Codable, CaseIterable {
    case mathematics
    case numberPatterns
    case visualMemory
    case visualAttention
    case logicalReasoning
    case quickThinking
    case timeAndOrder

    var localizedName: LocalizedText {
        switch self {
        case .mathematics: return LocalizedText(ar: "حساب", en: "Math")
        case .numberPatterns: return LocalizedText(ar: "أنماط", en: "Patterns")
        case .visualMemory: return LocalizedText(ar: "ذاكرة", en: "Memory")
        case .visualAttention: return LocalizedText(ar: "انتباه", en: "Attention")
        case .logicalReasoning: return LocalizedText(ar: "منطق", en: "Logic")
        case .quickThinking: return LocalizedText(ar: "سرعة بديهة", en: "Quick Thinking")
        case .timeAndOrder: return LocalizedText(ar: "وقت وترتيب", en: "Time & Order")
        }
    }

    var systemImageName: String {
        switch self {
        case .mathematics: return "plus.forwardslash.minus"
        case .numberPatterns: return "arrow.right.arrow.left"
        case .visualMemory: return "brain.head.profile"
        case .visualAttention: return "eye"
        case .logicalReasoning: return "lightbulb"
        case .quickThinking: return "bolt.fill"
        case .timeAndOrder: return "clock"
        }
    }
}

/// One selectable answer.
struct PuzzleChoice: Codable, Equatable, Hashable, Identifiable {
    let id: Int
    var label: LocalizedText
    /// When present the UI draws a glyph instead of text.
    var symbol: PuzzleSymbol?

    init(id: Int, label: LocalizedText, symbol: PuzzleSymbol? = nil) {
        self.id = id
        self.label = label
        self.symbol = symbol
    }

    init(id: Int, text: String) {
        self.init(id: id, label: LocalizedText(text))
    }

    init(id: Int, symbol: PuzzleSymbol) {
        self.init(id: id, label: symbol.localizedName, symbol: symbol)
    }
}

/// The expected player response.
enum PuzzleAnswer: Codable, Equatable {
    /// Exactly one choice is correct.
    case single(choiceID: Int)
    /// Choices must be tapped in this exact order (memory sequences).
    case ordered(choiceIDs: [Int])

    var requiredSelections: Int {
        switch self {
        case .single: return 1
        case .ordered(let ids): return ids.count
        }
    }
}

/// How the choices are laid out by the UI.
enum PuzzlePresentation: Codable, Equatable {
    /// Text buttons (2-4) in a comfortable one-hand grid.
    case buttons
    /// A grid of symbol tiles; `columns` per row (odd-one-out).
    case symbolGrid(columns: Int)
    /// Symbols are briefly revealed, hidden, then the player reproduces the order.
    case memorySequence(sequence: [PuzzleSymbol], revealSeconds: Double)
}

/// A fully specified, self-validating puzzle.
struct Puzzle: Codable, Equatable, Identifiable {
    let id: String
    let category: PuzzleCategory
    /// 1 (easiest) ... 10 (hardest)
    let difficulty: Int
    let question: LocalizedText
    /// Optional math expression rendered on its own LTR line, e.g. "5 + 7 = ?".
    let expression: String?
    let choices: [PuzzleChoice]
    let answer: PuzzleAnswer
    let explanation: LocalizedText?
    /// Seconds allowed; `nil` means untimed.
    let timeLimit: Double?
    /// Points awarded by the scoring system before combo multipliers.
    let reward: Int
    let presentation: PuzzlePresentation

    init(id: String,
         category: PuzzleCategory,
         difficulty: Int,
         question: LocalizedText,
         expression: String? = nil,
         choices: [PuzzleChoice],
         answer: PuzzleAnswer,
         explanation: LocalizedText? = nil,
         timeLimit: Double?,
         reward: Int = 100,
         presentation: PuzzlePresentation = .buttons) {
        self.id = id
        self.category = category
        self.difficulty = difficulty
        self.question = question
        self.expression = expression
        self.choices = choices
        self.answer = answer
        self.explanation = explanation
        self.timeLimit = timeLimit
        self.reward = reward
        self.presentation = presentation
    }

    /// Choice IDs that are correct, in the order they must be selected.
    var correctChoiceIDs: [Int] {
        switch answer {
        case .single(let id): return [id]
        case .ordered(let ids): return ids
        }
    }

    func choice(withID id: Int) -> PuzzleChoice? {
        choices.first { $0.id == id }
    }

    /// Structural validity checks shared by the engine and the unit tests.
    var isWellFormed: Bool {
        guard !choices.isEmpty else { return false }
        let ids = choices.map(\.id)
        guard Set(ids).count == ids.count else { return false }
        // No duplicate visible answers.
        let visible = choices.map { ($0.symbol?.debugName ?? "") + "|" + $0.label.en }
        guard Set(visible).count == visible.count else { return false }
        switch answer {
        case .single(let id):
            return ids.contains(id)
        case .ordered(let order):
            return !order.isEmpty && order.allSatisfy { ids.contains($0) }
        }
    }
}
