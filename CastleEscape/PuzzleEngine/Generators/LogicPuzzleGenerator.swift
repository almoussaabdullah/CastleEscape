import Foundation

/// Short logical-reasoning puzzles with a single verifiable answer:
/// ordering deductions, weekday arithmetic, "safe door" rule puzzles,
/// word categories and small counting riddles.
struct LogicPuzzleGenerator: PuzzleGenerating {
    let category: PuzzleCategory = .logicalReasoning

    enum Template: String, CaseIterable {
        case ordering, weekday, safeDoor, wordCategory, counting
    }

    var allowedTemplates: [Template]

    init(allowedTemplates: [Template] = Template.allCases) {
        self.allowedTemplates = allowedTemplates
    }

    private static let names: [LocalizedText] = [
        LocalizedText(ar: "سامي", en: "Sami"), LocalizedText(ar: "ليلى", en: "Layla"),
        LocalizedText(ar: "عمر", en: "Omar"), LocalizedText(ar: "نور", en: "Noor"),
        LocalizedText(ar: "زيد", en: "Zaid"), LocalizedText(ar: "مريم", en: "Maryam"),
        LocalizedText(ar: "كريم", en: "Karim"), LocalizedText(ar: "سلمى", en: "Salma"),
        LocalizedText(ar: "يوسف", en: "Yousef"), LocalizedText(ar: "هدى", en: "Huda"),
    ]

    private static let weekdays: [LocalizedText] = [
        LocalizedText(ar: "السبت", en: "Saturday"), LocalizedText(ar: "الأحد", en: "Sunday"),
        LocalizedText(ar: "الاثنين", en: "Monday"), LocalizedText(ar: "الثلاثاء", en: "Tuesday"),
        LocalizedText(ar: "الأربعاء", en: "Wednesday"), LocalizedText(ar: "الخميس", en: "Thursday"),
        LocalizedText(ar: "الجمعة", en: "Friday"),
    ]

    /// Each group: three members of one category plus one intruder (last element).
    private static let wordGroups: [[LocalizedText]] = [
        [LocalizedText(ar: "تفاحة", en: "Apple"), LocalizedText(ar: "موز", en: "Banana"), LocalizedText(ar: "عنب", en: "Grapes"), LocalizedText(ar: "جزر", en: "Carrot")],
        [LocalizedText(ar: "قطة", en: "Cat"), LocalizedText(ar: "كلب", en: "Dog"), LocalizedText(ar: "حصان", en: "Horse"), LocalizedText(ar: "كرسي", en: "Chair")],
        [LocalizedText(ar: "أحمر", en: "Red"), LocalizedText(ar: "أزرق", en: "Blue"), LocalizedText(ar: "أخضر", en: "Green"), LocalizedText(ar: "سبعة", en: "Seven")],
        [LocalizedText(ar: "سيف", en: "Sword"), LocalizedText(ar: "درع", en: "Shield"), LocalizedText(ar: "خوذة", en: "Helmet"), LocalizedText(ar: "تفاحة", en: "Apple")],
        [LocalizedText(ar: "مثلث", en: "Triangle"), LocalizedText(ar: "مربع", en: "Square"), LocalizedText(ar: "دائرة", en: "Circle"), LocalizedText(ar: "سمكة", en: "Fish")],
        [LocalizedText(ar: "الاثنين", en: "Monday"), LocalizedText(ar: "الثلاثاء", en: "Tuesday"), LocalizedText(ar: "الجمعة", en: "Friday"), LocalizedText(ar: "يناير", en: "January")],
        [LocalizedText(ar: "شمس", en: "Sun"), LocalizedText(ar: "قمر", en: "Moon"), LocalizedText(ar: "نجمة", en: "Star"), LocalizedText(ar: "حذاء", en: "Shoe")],
        [LocalizedText(ar: "برج", en: "Tower"), LocalizedText(ar: "جسر", en: "Bridge"), LocalizedText(ar: "بوابة", en: "Gate"), LocalizedText(ar: "غيمة", en: "Cloud")],
        [LocalizedText(ar: "قلم", en: "Pen"), LocalizedText(ar: "دفتر", en: "Notebook"), LocalizedText(ar: "ممحاة", en: "Eraser"), LocalizedText(ar: "ملعقة", en: "Spoon")],
    ]

    func generate(difficulty: Int, rng: inout SeededRandom) -> Puzzle {
        let d = DifficultyBand.clamp(difficulty)
        let template = rng.pick(allowedTemplates)
        switch template {
        case .ordering: return ordering(d, &rng)
        case .weekday: return weekday(d, &rng)
        case .safeDoor: return safeDoor(d, &rng)
        case .wordCategory: return wordCategory(d, &rng)
        case .counting: return counting(d, &rng)
        }
    }

    // MARK: - Templates

    private func ordering(_ d: Int, _ rng: inout SeededRandom) -> Puzzle {
        let picked = Array(rng.shuffled(Self.names).prefix(3))
        let a = picked[0], b = picked[1], c = picked[2]   // ranking: a > b > c
        let attributes: [(more: LocalizedText, mostQ: LocalizedText, leastQ: LocalizedText)] = [
            (LocalizedText(ar: "أطول من", en: "is taller than"), LocalizedText(ar: "من الأطول؟", en: "Who is the tallest?"), LocalizedText(ar: "من الأقصر؟", en: "Who is the shortest?")),
            (LocalizedText(ar: "أسرع من", en: "is faster than"), LocalizedText(ar: "من الأسرع؟", en: "Who is the fastest?"), LocalizedText(ar: "من الأبطأ؟", en: "Who is the slowest?")),
            (LocalizedText(ar: "أكبر سنًا من", en: "is older than"), LocalizedText(ar: "من الأكبر سنًا؟", en: "Who is the oldest?"), LocalizedText(ar: "من الأصغر سنًا؟", en: "Who is the youngest?")),
        ]
        let attr = rng.pick(attributes)
        // Two statement styles; both determine the full order.
        let chained = d < 5 || rng.chance(0.5)
        let s1 = LocalizedText(ar: "\(a.ar) \(attr.more.ar) \(b.ar)", en: "\(a.en) \(attr.more.en) \(b.en)")
        let bareComparative = attr.more.en.replacingOccurrences(of: "is ", with: "")
        let s2 = chained
            ? LocalizedText(ar: "\(b.ar) \(attr.more.ar) \(c.ar)", en: "\(b.en) \(attr.more.en) \(c.en)")
            : LocalizedText(ar: "\(c.ar) ليس \(attr.more.ar) \(b.ar)، و\(b.ar) ليس \(attr.more.ar) \(a.ar)",
                            en: "\(c.en) is not \(bareComparative) \(b.en), and \(b.en) is not \(bareComparative) \(a.en)")
        let askMost = rng.chance(0.5)
        let question = LocalizedText(ar: "\(s1.ar). \(s2.ar). \(askMost ? attr.mostQ.ar : attr.leastQ.ar)",
                                     en: "\(s1.en). \(s2.en). \(askMost ? attr.mostQ.en : attr.leastQ.en)")
        let correct = askMost ? a : c
        let (choices, correctID) = ChoiceBuilder.textChoices(correct: correct, distractors: picked.filter { $0 != correct }, rng: &rng)
        return Puzzle(id: "logic-ordering-\(rng.next())",
                      category: .logicalReasoning,
                      difficulty: d,
                      question: question,
                      choices: choices,
                      answer: .single(choiceID: correctID),
                      explanation: LocalizedText(ar: "الترتيب: \(a.ar) ثم \(b.ar) ثم \(c.ar)", en: "The order is \(a.en), then \(b.en), then \(c.en)"),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 34, floor: 16),
                      reward: DifficultyBand.reward(for: d, base: 120))
    }

    private func weekday(_ d: Int, _ rng: inout SeededRandom) -> Puzzle {
        let todayIndex = rng.int(in: 0...6)
        let offset = d >= 5 ? rng.int(in: 3...10) : rng.int(in: 1...4)
        let targetIndex = (todayIndex + offset) % 7
        let today = Self.weekdays[todayIndex]
        let target = Self.weekdays[targetIndex]
        var distractors: [LocalizedText] = []
        var k = 1
        while distractors.count < 3 {
            let candidate = Self.weekdays[(targetIndex + k) % 7]
            if candidate != target && !distractors.contains(candidate) { distractors.append(candidate) }
            k += rng.int(in: 1...2)
        }
        let (choices, correctID) = ChoiceBuilder.textChoices(correct: target, distractors: distractors, rng: &rng)
        return Puzzle(id: "logic-weekday-\(rng.next())",
                      category: .logicalReasoning,
                      difficulty: d,
                      question: LocalizedText(ar: "إذا كان اليوم هو \(today.ar)، فما هو اليوم بعد \(offset) أيام؟",
                                              en: "If today is \(today.en), what day will it be in \(offset) days?"),
                      choices: choices,
                      answer: .single(choiceID: correctID),
                      explanation: LocalizedText(ar: "\(today.ar) + \(offset) أيام = \(target.ar)", en: "\(today.en) + \(offset) days = \(target.en)"),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 28, floor: 14),
                      reward: DifficultyBand.reward(for: d, base: 110))
    }

    private func safeDoor(_ d: Int, _ rng: inout SeededRandom) -> Puzzle {
        let colors: [LocalizedText] = [LocalizedText(ar: "الأحمر", en: "red"), LocalizedText(ar: "الأزرق", en: "blue"), LocalizedText(ar: "الأخضر", en: "green")]
        var numbers = Set<Int>()
        while numbers.count < 3 { numbers.insert(rng.int(in: 1...9)) }
        let nums = rng.shuffled(Array(numbers))
        let doors = (0..<3).map { (color: colors[$0], number: nums[$0]) }
        let target = rng.int(in: 0...2)
        let others = (0..<3).filter { $0 != target }
        let excludedByColor = others[0]
        let other = others[1]
        let numberRule: LocalizedText
        if doors[target].number > doors[other].number {
            numberRule = LocalizedText(ar: "رقمه أكبر من \(doors[other].number)", en: "its number is greater than \(doors[other].number)")
        } else {
            numberRule = LocalizedText(ar: "رقمه أصغر من \(doors[other].number)", en: "its number is smaller than \(doors[other].number)")
        }
        let listAr = doors.map { "\($0.color.ar) (\($0.number))" }.joined(separator: "، ")
        let listEn = doors.map { "\($0.color.en) (\($0.number))" }.joined(separator: ", ")
        let question = LocalizedText(
            ar: "أمامك ثلاثة أبواب: \(listAr). الباب الآمن ليس \(doors[excludedByColor].color.ar)، و\(numberRule.ar). أي باب هو الآمن؟",
            en: "Three doors: \(listEn). The safe door is not \(doors[excludedByColor].color.en), and \(numberRule.en). Which door is safe?")
        let labels = doors.map { LocalizedText(ar: "الباب \($0.color.ar) \($0.number)", en: "\($0.color.en.capitalized) door \($0.number)") }
        let (choices, correctID) = ChoiceBuilder.textChoices(correct: labels[target], distractors: labels.filter { $0 != labels[target] }, rng: &rng)
        return Puzzle(id: "logic-door-\(rng.next())",
                      category: .logicalReasoning,
                      difficulty: d,
                      question: question,
                      choices: choices,
                      answer: .single(choiceID: correctID),
                      explanation: LocalizedText(ar: "الباب الوحيد الذي يحقق الشرطين هو \(labels[target].ar)", en: "Only \(labels[target].en) satisfies both rules"),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 40, floor: 20),
                      reward: DifficultyBand.reward(for: d, base: 130))
    }

    private func wordCategory(_ d: Int, _ rng: inout SeededRandom) -> Puzzle {
        let group = rng.pick(Self.wordGroups)
        let intruder = group[3]
        let (choices, correctID) = ChoiceBuilder.textChoices(correct: intruder, distractors: Array(group.prefix(3)), rng: &rng)
        return Puzzle(id: "logic-category-\(rng.next())",
                      category: .logicalReasoning,
                      difficulty: d,
                      question: LocalizedText(ar: "أي كلمة لا تنتمي إلى المجموعة؟", en: "Which word does not belong?"),
                      choices: choices,
                      answer: .single(choiceID: correctID),
                      explanation: LocalizedText(ar: "\(intruder.ar) من فئة مختلفة", en: "\(intruder.en) belongs to a different category"),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 22, floor: 10),
                      reward: DifficultyBand.reward(for: d))
    }

    private func counting(_ d: Int, _ rng: inout SeededRandom) -> Puzzle {
        let towers = rng.int(in: 2...(3 + d / 2))
        let windows = rng.int(in: 2...(4 + d / 2))
        let total = towers * windows
        let (choices, correctID) = ChoiceBuilder.numericChoices(correct: total, count: 4, rng: &rng, spread: 4 + d)
        return Puzzle(id: "logic-count-\(rng.next())",
                      category: .logicalReasoning,
                      difficulty: d,
                      question: LocalizedText(ar: "في القلعة \(towers) أبراج، وفي كل برج \(windows) نوافذ. كم نافذة في القلعة؟",
                                              en: "The castle has \(towers) towers, and each tower has \(windows) windows. How many windows are there?"),
                      choices: choices,
                      answer: .single(choiceID: correctID),
                      explanation: LocalizedText(ar: "\(towers) × \(windows) = \(total)", en: "\(towers) × \(windows) = \(total)"),
                      timeLimit: DifficultyBand.timeLimit(for: d, base: 28, floor: 12),
                      reward: DifficultyBand.reward(for: d))
    }
}
