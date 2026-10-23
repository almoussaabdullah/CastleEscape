import Foundation

/// Visual theme of a castle floor. Floors 10 and 9 have fully custom decoration;
/// the others reuse shared decoration sets tinted per theme.
enum FloorTheme: String, Codable, CaseIterable {
    case prisonTower, guardBarracks, ancientLibrary, clockTower, alchemistLab
    case mirrorHall, secretCorridors, armory, throneRoom, mainGate
}

/// Obstacles the hero clears after a correct answer. Each produces a distinct animation.
enum ObstacleKind: String, Codable, CaseIterable {
    /// A pit in the floor: the hero jumps over it.
    case gap
    /// Iron bars with a padlock: the lock pops open and the bars rise.
    case lockedGate
    /// Floor spikes that retract.
    case spikes
    /// A swinging log that stops so the hero can duck under it.
    case pendulum
    /// Glowing runes blocking the corridor that dissolve.
    case magicBarrier
    /// Wooden crates the hero climbs over.
    case crates
}

/// Static description of one castle floor.
struct FloorDefinition: Identifiable, Equatable {
    /// 10 (top, start) ... 1 (main gate, finish).
    let number: Int
    let theme: FloorTheme
    let name: LocalizedText
    let tagline: LocalizedText
    /// How many puzzles must be solved to unlock the staircase.
    let encounterCount: Int
    let recipe: PuzzleRecipe
    /// Obstacle sequence; cycled when shorter than `encounterCount`.
    let obstacles: [ObstacleKind]
    /// Wrong answers allowed before the guard catches the hero.
    let safetyMargin: Int

    var id: Int { number }

    func obstacle(forEncounter index: Int) -> ObstacleKind {
        obstacles[index % max(1, obstacles.count)]
    }

    var isFinalFloor: Bool { number == 1 }
}

/// Snapshot of a floor's persisted state used by the castle overview.
enum FloorStatus: Equatable {
    case locked
    case current
    case completed(stars: Int)
}
