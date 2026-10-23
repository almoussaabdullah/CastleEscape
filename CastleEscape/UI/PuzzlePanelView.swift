import SwiftUI

/// Bottom panel: the question, the timer, and the answer controls.
struct PuzzlePanelView: View {
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager
    @State private var shake: CGFloat = 0
    @State private var feedbackVisible = false

    var body: some View {
        VStack(spacing: 12) {
            if let puzzle = session.currentPuzzle {
                header(puzzle)
                question(puzzle)
                answers(puzzle)
            } else {
                placeholder
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Theme.panel.opacity(0.96), Theme.ink.opacity(0.98)], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(LinearGradient(colors: [Theme.gold, Theme.goldDark.opacity(0.4)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .top) { feedbackBanner }
        .modifier(ShakeEffect(animatableData: shake))
        .onChange(of: session.feedback) { _, newValue in
            guard let newValue = newValue else { feedbackVisible = false; return }
            switch newValue {
            case .wrong, .timeout:
                withAnimation(.linear(duration: 0.45)) { shake += 1 }
            default:
                break
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { feedbackVisible = true }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            ProgressView().tint(Theme.gold)
            Text(loc.t(.menuTagline))
                .font(Theme.body(15))
                .foregroundStyle(Theme.parchment.opacity(0.7))
        }
        .frame(height: 220)
    }

    // MARK: - Header

    private func header(_ puzzle: Puzzle) -> some View {
        VStack(spacing: 8) {
            HStack {
                Label(loc.t(puzzle.category.localizedName), systemImage: puzzle.category.systemImageName)
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.gold)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Theme.panelLight))
                Spacer()
                Text(loc.t(.puzzleProgress, session.encounterIndex + 1, session.currentFloor?.encounterCount ?? 0))
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.parchment.opacity(0.8))
                Spacer()
                Label("\(session.progress.coins)", systemImage: "circle.hexagongrid.fill")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.gold)
            }
            if let limit = puzzle.timeLimit {
                TimerBar(remaining: session.timeRemaining ?? limit, total: limit, paused: session.isMemorizing || session.interactionLocked)
            }
        }
    }

    // MARK: - Question

    private func question(_ puzzle: Puzzle) -> some View {
        VStack(spacing: 6) {
            Text(loc.t(puzzle.question))
                .font(Theme.heading(puzzle.question.resolved(loc.language).count > 60 ? 15 : 18))
                .foregroundStyle(Theme.parchment)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
            if let expression = puzzle.expression {
                Text(expression)
                    .font(Theme.mono(expression.count > 16 ? 22 : 30))
                    .foregroundStyle(Theme.gold)
                    .environment(\.layoutDirection, .leftToRight)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panelLight.opacity(0.6)))
            }
            if case .memorySequence(let sequence, _) = puzzle.presentation {
                MemoryStrip(sequence: sequence, isMemorizing: session.isMemorizing, selectedCount: session.selection.count)
            }
        }
    }

    // MARK: - Answers

    @ViewBuilder
    private func answers(_ puzzle: Puzzle) -> some View {
        switch puzzle.presentation {
        case .buttons:
            buttonGrid(puzzle)
        case .symbolGrid(let columns):
            symbolGrid(puzzle, columns: columns)
        case .memorySequence:
            symbolGrid(puzzle, columns: min(4, max(3, puzzle.choices.count / 2)))
        }
    }

    private func buttonGrid(_ puzzle: Puzzle) -> some View {
        let rows = puzzle.choices.chunked(into: 2)
        return VStack(spacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row) { choice in
                        AnswerButton(choice: choice, puzzle: puzzle)
                    }
                }
            }
            hintRow
        }
    }

    private func symbolGrid(_ puzzle: Puzzle, columns: Int) -> some View {
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
        return LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(puzzle.choices) { choice in
                SymbolTile(choice: choice, puzzle: puzzle)
            }
        }
    }

    @ViewBuilder
    private var hintRow: some View {
        if session.canUseHint {
            HStack {
                Spacer()
                Button {
                    session.useHint()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                        Text(loc.t(.puzzleHint))
                        Text(session.canAffordHint ? loc.t(.puzzleHintCost, session.hintCost) : loc.t(.puzzleHintAd))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink.opacity(0.75))
                    }
                }
                .buttonStyle(FantasyButtonStyle(kind: .primary, compact: true))
            }
        }
    }

    // MARK: - Feedback

    @ViewBuilder
    private var feedbackBanner: some View {
        if let feedback = session.feedback, feedbackVisible {
            FeedbackBanner(feedback: feedback)
                .offset(y: -22)
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Components

struct TimerBar: View {
    let remaining: Double
    let total: Double
    let paused: Bool

    var body: some View {
        let fraction = total > 0 ? max(0, min(1, remaining / total)) : 0
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.panelLight.opacity(0.7))
                Capsule()
                    .fill(fraction > 0.35 ? Theme.success : (fraction > 0.15 ? Theme.gold : Theme.danger))
                    .frame(width: proxy.size.width * fraction)
                    .animation(.linear(duration: 0.05), value: fraction)
            }
        }
        .frame(height: 8)
        .opacity(paused ? 0.4 : 1)
    }
}

struct AnswerButton: View {
    let choice: PuzzleChoice
    let puzzle: Puzzle
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager

    private var state: AnswerState {
        if session.hiddenChoiceIDs.contains(choice.id) { return .hidden }
        if session.phase == .resolving, let feedback = session.feedback {
            let isCorrect = puzzle.correctChoiceIDs.contains(choice.id)
            switch feedback {
            case .correct: return isCorrect ? .correct : .idle
            case .wrong, .timeout, .shieldSaved: return session.selection.last == choice.id ? .wrong : .idle
            }
        }
        return .idle
    }

    var body: some View {
        Button {
            session.select(choiceID: choice.id)
        } label: {
            Text(loc.t(choice.label))
                .font(Theme.heading(20))
                .foregroundStyle(state == .correct ? Theme.ink : Theme.parchment)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, choice.label.en == choice.label.ar ? .leftToRight : loc.language.layoutDirection)
                .frame(maxWidth: .infinity, minHeight: 58)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(stroke, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(state == .hidden || session.interactionLocked)
        .opacity(state == .hidden ? 0.18 : 1)
        .scaleEffect(state == .correct ? 1.04 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state)
    }

    private var fill: Color {
        switch state {
        case .correct: return Theme.success
        case .wrong: return Theme.danger.opacity(0.85)
        default: return Theme.panelLight
        }
    }

    private var stroke: Color {
        switch state {
        case .correct: return Theme.success
        case .wrong: return Theme.danger
        default: return Theme.gold.opacity(0.55)
        }
    }

    enum AnswerState: Equatable { case idle, correct, wrong, hidden }
}

struct SymbolTile: View {
    let choice: PuzzleChoice
    let puzzle: Puzzle
    @EnvironmentObject private var session: GameSession

    private var selectionIndex: Int? { session.selection.firstIndex(of: choice.id) }

    private var highlight: Color? {
        guard session.phase == .resolving, let feedback = session.feedback else { return nil }
        switch feedback {
        case .correct: return puzzle.correctChoiceIDs.contains(choice.id) ? Theme.success : nil
        case .wrong, .timeout, .shieldSaved: return session.selection.last == choice.id ? Theme.danger : nil
        }
    }

    var body: some View {
        Button {
            session.select(choiceID: choice.id)
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(highlight?.opacity(0.35) ?? Theme.panelLight)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(highlight ?? (selectionIndex != nil ? Theme.gold : Theme.gold.opacity(0.35)), lineWidth: selectionIndex != nil ? 3 : 1.5))
                if let symbol = choice.symbol {
                    SymbolGlyph(symbol: symbol, size: puzzle.choices.count > 12 ? 24 : 30)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if let index = selectionIndex {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Theme.gold))
                        .padding(4)
                }
            }
            .frame(height: puzzle.choices.count > 12 ? 48 : 60)
        }
        .buttonStyle(.plain)
        .disabled(session.interactionLocked || selectionIndex != nil)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selectionIndex)
    }
}

/// Shows the memory sequence during the reveal phase, then empty slots that fill as the player taps.
struct MemoryStrip: View {
    let sequence: [PuzzleSymbol]
    let isMemorizing: Bool
    let selectedCount: Int
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        VStack(spacing: 4) {
            Text(isMemorizing ? loc.t(.puzzleMemorize) : loc.t(.puzzleYourTurn))
                .font(Theme.body(13))
                .foregroundStyle(isMemorizing ? Theme.gold : Theme.success)
            HStack(spacing: 8) {
                ForEach(Array(sequence.enumerated()), id: \.offset) { index, symbol in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.panelLight.opacity(0.7))
                            .frame(width: 44, height: 44)
                        if isMemorizing {
                            SymbolGlyph(symbol: symbol, size: 24)
                        } else if index < selectedCount {
                            Image(systemName: "checkmark").font(.system(size: 16, weight: .heavy)).foregroundStyle(Theme.success)
                        } else {
                            Text("\(index + 1)").font(Theme.body(14)).foregroundStyle(Theme.parchment.opacity(0.5))
                        }
                    }
                }
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .animation(.easeInOut(duration: 0.25), value: isMemorizing)
    }
}

struct FeedbackBanner: View {
    let feedback: AnswerFeedback
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(Theme.heading(16))
        .foregroundStyle(Theme.ink)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Capsule().fill(color))
        .shadow(color: color.opacity(0.6), radius: 10)
    }

    private var icon: String {
        switch feedback {
        case .correct: return "checkmark.circle.fill"
        case .wrong: return "xmark.circle.fill"
        case .timeout: return "clock.badge.exclamationmark.fill"
        case .shieldSaved: return "shield.lefthalf.filled"
        }
    }

    private var color: Color {
        switch feedback {
        case .correct: return Theme.success
        case .wrong, .timeout: return Theme.danger
        case .shieldSaved: return Theme.magic
        }
    }

    private var text: String {
        switch feedback {
        case .correct(let points, let fast, let multiplier, let tier):
            var parts = [loc.t(.puzzleCorrect), loc.t(.puzzlePoints, points)]
            if fast > 0 { parts.append(loc.t(.puzzleFastBonus, fast)) }
            if tier { parts.append(loc.t(.puzzleComboTier, Int(multiplier))) }
            return parts.joined(separator: "  ")
        case .wrong: return loc.t(.puzzleWrong) + " · " + loc.t(.puzzleGuardCloser)
        case .timeout: return loc.t(.puzzleTimeout)
        case .shieldSaved: return loc.t(.puzzleShieldSaved)
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
