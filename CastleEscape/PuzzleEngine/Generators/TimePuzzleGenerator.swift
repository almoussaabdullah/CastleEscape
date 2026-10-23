import Foundation

/// Clock Tower puzzles: clock arithmetic, earlier/later comparisons and number ordering.
struct TimePuzzleGenerator: PuzzleGenerating {
    let category: PuzzleCategory = .timeAndOrder

    enum Template: String, CaseIterable {
        case clockAdd, earlier, ordering
    }

    func generate(difficulty: Int, rng: inout SeededRandom) -> Puzzle {
        let d = DifficultyBand.clamp(difficulty)
        let template = rng.pick(Template.allCases)
        switch template {
        case .clockAdd: return clockAdd(d, &rng)
        case .earlier: return earlier(d, &rng)
        case .ordering: return ordering(d, &rng)
        }
    }

    private static func format(_ minutes: Int) -> String {
        let total = ((minutes % 720) + 720) % 720
        var hour = total / 60
        if hour == 0 { hour = 12 }
        let minute = total % 60
        return String(format: "%d:%02d", hour, minute)
    }

    private func clockAdd(_ d: Int, _ rng: inout SeededRandom) -> Puzzle {
        let startMinutes = rng.int(in: 1...12) * 60 + rng.pick(d >= 4 ? [0, 5, 10, 15, 20, 25, 30, 40, 45, 50] : [0, 15, 30, 45])
        let delta = rng.pick(d >= 5 ? [20, 25, 35, 40, 45, 50, 70, 90] : [15, 30, 45, 60])
        let result = startMinutes + delta
        let correct = Self.format(result)
        var distractors = Set<String>()
        for candidate in [result + 15, result - 15, result + 30, result - 30, result + 60, result + 5] {
            let text = Self.format(candidate)
            if text != correct { distractors.insert(text) }
        }
        let picked = Array(rng.shuffled(Array(distractors)).prefix(3)).map { LocalizedText($0) }
        let (choices, correctID) = ChoiceBuilder.textChoices(correct: LocalizedText(correct), distractors: picked, rng: &rng)
        let shown = Self.format(startMinutes)
        return Puzzle(id: "time-add-\(rng.next())", category: .timeAndOrder, difficulty: d,
                      question: LocalizedText(ar: "الساعة الآن \(shown). كم ستكون الساعة بعد \(delta) دقيقة؟",
                                              en: "The clock shows \(shown). What time will it be in \(delta) minutes?"),
                      expression: "\(shown) + \(delta) min",
                      choices: choices, answer: .single(choiceID: correctID),
                      explanation: LocalizedText(ar: "\(shown) + \(delta) دقيقة = \(correct)", en: "\(shown) + \(delta) minutes = \(correct)"),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 30, floor: 14),
                      reward: DifficultyBand.reward(for: d, base: 115))
    }

    private func earlier(_ d: Int, _ rng: inout SeededRandom) -> Puzzle {
        // Two times within the same 12-hour span; ask which is earlier/later.
        let a = rng.int(in: 1...11) * 60 + rng.pick([0, 10, 15, 20, 30, 40, 45, 50])
        var b = a + rng.pick([5, 10, 15, 20, 25, 30, 45]) * (rng.chance(0.5) ? 1 : -1)
        if b <= 0 || b >= 720 { b = a + 10 }
        if b == a { b += 5 }
        let askEarlier = rng.chance(0.5)
        let correctMinutes = askEarlier ? min(a, b) : max(a, b)
        let correct = LocalizedText(Self.format(correctMinutes))
        let wrong = LocalizedText(Self.format(correctMinutes == a ? b : a))
        let (choices, correctID) = ChoiceBuilder.textChoices(correct: correct, distractors: [wrong], rng: &rng)
        return Puzzle(id: "time-earlier-\(rng.next())", category: .timeAndOrder, difficulty: d,
                      question: askEarlier ? LocalizedText(ar: "أي الوقتين أبكر؟", en: "Which time is earlier?")
                                           : LocalizedText(ar: "أي الوقتين أبعد؟", en: "Which time is later?"),
                      choices: choices, answer: .single(choiceID: correctID),
                      explanation: LocalizedText(ar: "\(Self.format(min(a, b))) يأتي قبل \(Self.format(max(a, b)))", en: "\(Self.format(min(a, b))) comes before \(Self.format(max(a, b)))"),
                      timeLimit: max(5, 10 - Double(d) * 0.4),
                      reward: DifficultyBand.reward(for: d, base: 105))
    }

    private func ordering(_ d: Int, _ rng: inout SeededRandom) -> Puzzle {
        var values = Set<Int>()
        let hi = d >= 5 ? 999 : 99
        while values.count < 4 { values.insert(rng.int(in: 10...hi)) }
        let sorted = values.sorted()
        let position = rng.int(in: 0...3)   // which rank is asked
        let correct = sorted[position]
        let rankAr = ["الأصغر", "الثاني في الترتيب من الأصغر", "الثالث في الترتيب من الأصغر", "الأكبر"]
        let rankEn = ["smallest", "second smallest", "third smallest", "largest"]
        let (choices, correctID) = ChoiceBuilder.textChoices(correct: LocalizedText(String(correct)), distractors: sorted.filter { $0 != correct }.map { LocalizedText(String($0)) }, rng: &rng)
        let listed = rng.shuffled(sorted).map(String.init).joined(separator: ", ")
        return Puzzle(id: "time-order-\(rng.next())", category: .timeAndOrder, difficulty: d,
                      question: LocalizedText(ar: "من بين هذه الأرقام، أيها \(rankAr[position])؟", en: "Among these numbers, which is the \(rankEn[position])?"),
                      expression: listed,
                      choices: choices, answer: .single(choiceID: correctID),
                      explanation: LocalizedText(ar: "الترتيب التصاعدي: " + sorted.map(String.init).joined(separator: " < "), en: "Ascending order: " + sorted.map(String.init).joined(separator: " < ")),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 20, floor: 9),
                      reward: DifficultyBand.reward(for: d, base: 105))
    }
}
