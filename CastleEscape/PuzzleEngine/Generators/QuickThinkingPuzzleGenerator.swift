import Foundation

/// Fast, timed micro-decisions: comparisons, parity, true/false, extremes.
struct QuickThinkingPuzzleGenerator: PuzzleGenerating {
    let category: PuzzleCategory = .quickThinking

    enum Template: String, CaseIterable {
        case larger, evenNumber, trueFalse, biggest
    }

    func generate(difficulty: Int, rng: inout SeededRandom) -> Puzzle {
        let d = DifficultyBand.clamp(difficulty)
        let template = rng.pick(Template.allCases)
        let limit = max(4.0, 9.0 - Double(d) * 0.5)
        switch template {
        case .larger:
            let a = rng.int(in: 2...(6 + d))
            let b = rng.int(in: 2...(6 + d))
            let product = a * b
            var other = product + rng.int(in: 1...(4 + d)) * (rng.chance(0.5) ? 1 : -1)
            if other < 1 { other = product + rng.int(in: 1...(4 + d)) }
            if other == product { other += 1 }
            let left = LocalizedText("\(a) × \(b)")
            let right = LocalizedText("\(other)")
            let correct = product > other ? left : right
            let (choices, correctID) = ChoiceBuilder.textChoices(correct: correct, distractors: [correct == left ? right : left], rng: &rng)
            return Puzzle(id: "quick-larger-\(rng.next())", category: .quickThinking, difficulty: d,
                          question: LocalizedText(ar: "بسرعة! أيّهما أكبر؟", en: "Quick! Which is larger?"),
                          choices: choices, answer: .single(choiceID: correctID),
                          explanation: LocalizedText(ar: "\(a) × \(b) = \(product)", en: "\(a) × \(b) = \(product)"),
                          timeLimit: limit, reward: DifficultyBand.reward(for: d, base: 110))
        case .evenNumber:
            let even = rng.int(in: 1...(10 + d * 3)) * 2
            var odds = Set<Int>()
            while odds.count < 3 {
                odds.insert(rng.int(in: 0...(10 + d * 3)) * 2 + 1)
            }
            let (choices, correctID) = ChoiceBuilder.textChoices(correct: LocalizedText(String(even)), distractors: odds.map { LocalizedText(String($0)) }, rng: &rng)
            return Puzzle(id: "quick-even-\(rng.next())", category: .quickThinking, difficulty: d,
                          question: LocalizedText(ar: "اضغط على الرقم الزوجي", en: "Tap the even number"),
                          choices: choices, answer: .single(choiceID: correctID),
                          explanation: LocalizedText(ar: "\(even) يقبل القسمة على 2", en: "\(even) is divisible by 2"),
                          timeLimit: limit, reward: DifficultyBand.reward(for: d, base: 110))
        case .trueFalse:
            let a = rng.int(in: 1...(20 + d * 5))
            let b = rng.int(in: 1...(20 + d * 5))
            let statementIsTrue = rng.chance(0.5)
            let greater: Bool
            if a == b {
                greater = false
            } else {
                greater = a > b
            }
            // Build a statement whose truth matches `statementIsTrue`.
            let useGreaterSign = statementIsTrue ? greater : !greater
            let expression = "\(a) \(useGreaterSign ? ">" : "<") \(b)"
            let actuallyTrue = useGreaterSign ? (a > b) : (a < b)
            let yes = LocalizedText(ar: "صحيح", en: "True")
            let no = LocalizedText(ar: "خطأ", en: "False")
            let correct = actuallyTrue ? yes : no
            let (choices, correctID) = ChoiceBuilder.textChoices(correct: correct, distractors: [actuallyTrue ? no : yes], rng: &rng)
            return Puzzle(id: "quick-tf-\(rng.next())", category: .quickThinking, difficulty: d,
                          question: LocalizedText(ar: "صحيح أم خطأ؟", en: "True or false?"),
                          expression: expression,
                          choices: choices, answer: .single(choiceID: correctID),
                          explanation: LocalizedText(ar: "العبارة \(actuallyTrue ? "صحيحة" : "خاطئة")", en: "The statement is \(actuallyTrue ? "true" : "false")"),
                          timeLimit: limit, reward: DifficultyBand.reward(for: d, base: 110))
        case .biggest:
            var values = Set<Int>()
            while values.count < 4 { values.insert(rng.int(in: 10...(40 + d * 10))) }
            let sorted = values.sorted()
            let askMax = rng.chance(0.5)
            let correct = askMax ? sorted.last! : sorted.first!
            let (choices, correctID) = ChoiceBuilder.textChoices(correct: LocalizedText(String(correct)), distractors: sorted.filter { $0 != correct }.map { LocalizedText(String($0)) }, rng: &rng)
            return Puzzle(id: "quick-extreme-\(rng.next())", category: .quickThinking, difficulty: d,
                          question: askMax ? LocalizedText(ar: "اضغط على أكبر رقم", en: "Tap the biggest number")
                                           : LocalizedText(ar: "اضغط على أصغر رقم", en: "Tap the smallest number"),
                          choices: choices, answer: .single(choiceID: correctID),
                          explanation: LocalizedText(ar: "الإجابة \(correct)", en: "The answer is \(correct)"),
                          timeLimit: limit, reward: DifficultyBand.reward(for: d, base: 110))
        }
    }
}
