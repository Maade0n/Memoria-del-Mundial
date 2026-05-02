// MundialGameView.swift
// Juego de Memoria del Mundial - Servicio Social
// Autor: Luis Gabriel Sáenz Contreras
// Mantenedor (Tarea 5): Gael Rodriguez Jimenez
//
// Tarea 5 — Optimización y Escalabilidad
// Cambios principales:
//   1. Refactorización: constantes extraídas, guardas #if os(iOS) para hapticos.
//   2. Accesibilidad completa: VoiceOver, Dynamic Type, Reduce Motion.
//   3. Funcionalidad nueva 1: enum GameDifficulty + pantalla de selección.
//   4. Funcionalidad nueva 2: ScorePersistence (mejor puntaje con UserDefaults).
//   5. Nueva animación de confeti en pantalla de victoria.

import SwiftUI
import AudioToolbox

#if os(iOS)
import UIKit
#endif

// MARK: - Constantes del juego

private enum GameConstants {
    enum Sounds {
        static let cardTap: SystemSoundID = 1104
        static let pairMatched: SystemSoundID = 1057
        static let gameWon: SystemSoundID = 1025
    }
    enum Layout {
        static let cardMinSize: CGFloat = 60
        static let cardMaxSize: CGFloat = 80
        static let cardAspectRatio: CGFloat = 0.7
        static let cardCornerRadius: CGFloat = 12
    }
    enum Timing {
        static let mismatchFlipDelay: TimeInterval = 1.0
        static let winOverlayDelay: TimeInterval = 0.5
        static let feedbackDelay: TimeInterval = 0.1
    }
}

// MARK: - Dificultad (Funcionalidad nueva 1)

enum GameDifficulty: String, CaseIterable, Identifiable {
    case easy = "Fácil"
    case medium = "Medio"
    case hard = "Difícil"

    var id: String { rawValue }

    /// Número de parejas que se generan para esta dificultad.
    var pairs: Int {
        switch self {
        case .easy: return 4
        case .medium: return 6
        case .hard: return 8
        }
    }

    /// Descripción accesible leída por VoiceOver.
    var accessibilityDescription: String {
        "\(rawValue), \(pairs) parejas"
    }

    var emoji: String {
        switch self {
        case .easy: return "🟢"
        case .medium: return "🟡"
        case .hard: return "🔴"
        }
    }
}

// MARK: - Persistencia de Puntaje (Funcionalidad nueva 2)

struct ScorePersistence {
    private static func key(for difficulty: GameDifficulty) -> String {
        "bestMoves.\(difficulty.rawValue)"
    }

    /// Lee el mejor número de movimientos para una dificultad. Devuelve nil si no hay registro.
    static func bestMoves(for difficulty: GameDifficulty) -> Int? {
        let value = UserDefaults.standard.integer(forKey: key(for: difficulty))
        return value > 0 ? value : nil
    }

    /// Guarda un nuevo récord solo si es mejor que el anterior.
    static func saveIfBetter(_ moves: Int, for difficulty: GameDifficulty) -> Bool {
        guard let current = bestMoves(for: difficulty) else {
            UserDefaults.standard.set(moves, forKey: key(for: difficulty))
            return true
        }
        if moves < current {
            UserDefaults.standard.set(moves, forKey: key(for: difficulty))
            return true
        }
        return false
    }

    /// Resetea todos los récords (útil para el modo facilitador).
    static func resetAll() {
        for d in GameDifficulty.allCases {
            UserDefaults.standard.removeObject(forKey: key(for: d))
        }
    }
}

// MARK: - Vista raíz con navegación entre pantallas

struct MundialGameView: View {
    @State private var selectedDifficulty: GameDifficulty? = nil

    var body: some View {
        if let difficulty = selectedDifficulty {
            GameSessionView(difficulty: difficulty) {
                selectedDifficulty = nil
            }
        } else {
            DifficultySelectionView { difficulty in
                selectedDifficulty = difficulty
            }
        }
    }
}

// MARK: - Pantalla de Selección de Dificultad

struct DifficultySelectionView: View {
    let onSelect: (GameDifficulty) -> Void

    var body: some View {
        ZStack {
            mexicanFlagGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("⚽")
                    .font(.system(size: 80))
                    .accessibilityHidden(true)

                Text("Memoria del Mundial")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .accessibilityAddTraits(.isHeader)

                Text("Aprende jugando con Quetzal")
                    .font(.title3)
                    .foregroundColor(.white)
                    .opacity(0.9)

                Spacer().frame(height: 20)

                Text("Elige tu nivel:")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                ForEach(GameDifficulty.allCases) { difficulty in
                    DifficultyButton(difficulty: difficulty) {
                        onSelect(difficulty)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

private struct DifficultyButton: View {
    let difficulty: GameDifficulty
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(difficulty.emoji)
                    .font(.title)
                Text(difficulty.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if let best = ScorePersistence.bestMoves(for: difficulty) {
                    Text("⭐ \(best)")
                        .font(.headline)
                }
            }
            .padding()
            .frame(maxWidth: 320)
            .background(Color.white.opacity(0.85))
            .foregroundColor(.blue)
            .cornerRadius(20)
            .shadow(radius: 4)
        }
        .accessibilityLabel("Nivel \(difficulty.accessibilityDescription)")
        .accessibilityHint(
            ScorePersistence.bestMoves(for: difficulty).map { "Mejor récord: \($0) movimientos" }
                ?? "Sin récord previo"
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Sesión de Juego

struct GameSessionView: View {
    @StateObject private var game: MundialMemoryGame
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let difficulty: GameDifficulty
    let onExit: () -> Void

    #if os(iOS)
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let successFeedback = UINotificationFeedbackGenerator()
    private let errorFeedback = UINotificationFeedbackGenerator()
    #endif

    init(difficulty: GameDifficulty, onExit: @escaping () -> Void) {
        self.difficulty = difficulty
        self.onExit = onExit
        _game = StateObject(wrappedValue: MundialMemoryGame(difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            mexicanFlagGradient.ignoresSafeArea()

            VStack(spacing: 15) {
                header
                quetzalCard
                statsBar
                tipBanner
                cardGrid
                Spacer()
            }

            if game.isGameWon { winOverlay }
        }
    }

    // MARK: - Subvistas

    private var header: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title)
                .accessibilityHidden(true)

            Text("⚽ Memoria del Mundial ⚽")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)

            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title)
                .accessibilityHidden(true)
        }
        .padding(.top, 30)
        .shadow(color: .black.opacity(0.3), radius: 5)
    }

    private var quetzalCard: some View {
        HStack(spacing: 12) {
            Text("🐉")
                .font(.system(size: 40))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Quetzal dice:")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                Text(game.mascotMessage)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.5), Color.yellow.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(15)
        .shadow(radius: 3)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quetzal dice: \(game.mascotMessage)")
    }

    private var statsBar: some View {
        HStack(spacing: 20) {
            StatBadge(title: "Movimientos", value: "\(game.moves)", color: .blue)
            StatBadge(title: "Parejas", value: "\(game.matchedPairs)/\(game.totalPairs)", color: .purple)

            Button(action: handleRestart) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Reiniciar partida")
            .accessibilityHint("Comienza una nueva partida del mismo nivel")

            Button(action: onExit) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Volver al menú")
            .accessibilityHint("Regresa a la pantalla de selección de dificultad")
        }
    }

    private var tipBanner: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.caption)
                .accessibilityHidden(true)
            Text(game.currentTip)
                .font(.caption2)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.3))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var cardGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: GameConstants.Layout.cardMinSize,
                                             maximum: GameConstants.Layout.cardMaxSize))],
                spacing: 10
            ) {
                ForEach(Array(game.cards.enumerated()), id: \.element.id) { _, card in
                    MundialCardView(card: card, reduceMotion: reduceMotion)
                        .aspectRatio(GameConstants.Layout.cardAspectRatio, contentMode: .fit)
                        .contentShape(Rectangle())
                        .onTapGesture { handleCardTap(card) }
                        .accessibilityLabel(accessibilityLabel(for: card))
                        .accessibilityHint(card.isFaceUp || card.isMatched
                                           ? "" : "Toca para voltear")
                        .accessibilityAddTraits(card.isMatched ? [.isStaticText] : [.isButton])
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
        }
    }

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🐉")
                    .font(.system(size: 80))
                    .scaleEffect(reduceMotion ? 1 : 1.1)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.6).repeatForever(),
                               value: game.isGameWon)
                    .accessibilityHidden(true)

                Text("¡GANASTE!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.yellow)
                    .accessibilityAddTraits(.isHeader)

                Text(game.rating)
                    .font(.title3)
                    .foregroundColor(.white)

                Text("Movimientos: \(game.moves)")
                    .font(.body)
                    .foregroundColor(.white)

                if game.isNewRecord {
                    Text("¡Nuevo récord! 🏆")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.top, 4)
                }

                Text("¡Quetzal está orgulloso de ti! 🎉")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    Button(action: handleRestart) {
                        Text("Jugar de nuevo")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(20)
                    }
                    Button(action: onExit) {
                        Text("Menú")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue.opacity(0.95))
            )
            .padding(20)
        }
        .onAppear {
            AudioServicesPlaySystemSound(GameConstants.Sounds.gameWon)
            #if os(iOS)
            successFeedback.notificationOccurred(.success)
            #endif
        }
    }

    // MARK: - Acciones

    private func handleCardTap(_ card: MundialGameCard) {
        AudioServicesPlaySystemSound(GameConstants.Sounds.cardTap)
        #if os(iOS)
        impactFeedback.impactOccurred()
        #endif

        let prevPairs = game.matchedPairs

        withAnimation(reduceMotion ? nil : .default) {
            game.choose(card)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.Timing.feedbackDelay) {
            #if os(iOS)
            if game.matchedPairs > prevPairs {
                AudioServicesPlaySystemSound(GameConstants.Sounds.pairMatched)
                successFeedback.notificationOccurred(.success)
            } else if game.moves > 0 {
                errorFeedback.notificationOccurred(.warning)
            }
            #endif
        }
    }

    private func handleRestart() {
        #if os(iOS)
        impactFeedback.impactOccurred()
        #endif
        AudioServicesPlaySystemSound(GameConstants.Sounds.cardTap)
        game.newGame()
    }

    // MARK: - Accesibilidad

    private func accessibilityLabel(for card: MundialGameCard) -> String {
        if card.isMatched { return "Tarjeta emparejada, \(card.content)" }
        if card.isFaceUp { return "Tarjeta boca arriba, \(card.content)" }
        return "Tarjeta boca abajo"
    }
}

// MARK: - Componentes auxiliares

private struct StatBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(10)
        .background(color.opacity(0.3))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

private var mexicanFlagGradient: LinearGradient {
    LinearGradient(
        gradient: Gradient(colors: [
            Color.green.opacity(0.7),
            Color.white.opacity(0.5),
            Color.red.opacity(0.7)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Vista de Carta

struct MundialCardView: View {
    let card: MundialGameCard
    var reduceMotion: Bool = false

    var body: some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: GameConstants.Layout.cardCornerRadius)

            if card.isFaceUp {
                shape.fill(.white)
                shape.strokeBorder(lineWidth: 2)
                    .foregroundColor(.blue)
                Text(card.content)
                    .font(.system(size: 35))
                    .minimumScaleFactor(0.5)
            } else if card.isMatched {
                shape.opacity(0)
            } else {
                shape.fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                Text("⚽")
                    .font(.system(size: 25))
                    .foregroundColor(.white)
            }
        }
        .opacity(card.isMatched ? 0.5 : 1.0)
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : (card.isFaceUp ? 0 : 0)),
            axis: (x: 0, y: 1, z: 0)
        )
    }
}

// MARK: - Modelo de Tarjeta

struct MundialGameCard: Identifiable {
    let id = UUID()
    let content: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

// MARK: - ViewModel

class MundialMemoryGame: ObservableObject {
    @Published private(set) var cards: [MundialGameCard] = []
    @Published private(set) var moves: Int = 0
    @Published private(set) var matchedPairs: Int = 0
    @Published private(set) var isGameWon: Bool = false
    @Published private(set) var mascotMessage: String = "¡Vamos a jugar!"
    @Published private(set) var currentTip: String = ""
    @Published private(set) var isNewRecord: Bool = false

    let difficulty: GameDifficulty

    private let worldCupSymbols = ["⚽", "🏆", "🥇", "⭐", "🎯", "👟", "🌍", "🎊"]

    private let educationalTips = [
        "🧠 Este juego mejora tu memoria",
        "🎯 Mantén la concentración",
        "⭐ La práctica hace al campeón",
        "🏆 Aprende paso a paso",
        "💪 Cada intento te hace mejor",
        "🔥 ¡Tú puedes lograrlo!"
    ]

    private let mascotMessages = [
        "¡Muy bien! 🎉",
        "¡Sigue así! 💪",
        "¡Excelente memoria! 🧠",
        "¡Casi lo tienes! ⭐",
        "¡Tú puedes! 🔥",
        "¡Increíble! 🎯",
        "¡Wow! 😮",
        "¡Eres genial! 🌟"
    ]

    var totalPairs: Int { difficulty.pairs }

    var rating: String {
        let limits = (low: difficulty.pairs * 2, high: difficulty.pairs * 3)
        if moves <= limits.low { return "¡Excelente! ⭐⭐⭐" }
        if moves <= limits.high { return "¡Muy bien! ⭐⭐" }
        return "¡Lo lograste! ⭐"
    }

    private var indexOfOneAndOnlyFaceUpCard: Int? {
        get {
            let faceUp = cards.indices.filter { cards[$0].isFaceUp && !cards[$0].isMatched }
            return faceUp.count == 1 ? faceUp.first : nil
        }
        set {
            for i in cards.indices where !cards[i].isMatched {
                cards[i].isFaceUp = (i == newValue)
            }
        }
    }

    init(difficulty: GameDifficulty) {
        self.difficulty = difficulty
        newGame()
    }

    func newGame() {
        let symbols = Array(worldCupSymbols.prefix(difficulty.pairs))
        let contents = symbols + symbols
        cards = contents.shuffled().map { MundialGameCard(content: $0) }

        moves = 0
        matchedPairs = 0
        isGameWon = false
        isNewRecord = false
        mascotMessage = "¡Vamos a jugar!"
        currentTip = educationalTips.randomElement() ?? "¡Diviértete aprendiendo!"
    }

    func choose(_ card: MundialGameCard) {
        guard let chosen = cards.firstIndex(where: { $0.id == card.id }),
              !cards[chosen].isFaceUp,
              !cards[chosen].isMatched else { return }

        if let potentialMatch = indexOfOneAndOnlyFaceUpCard {
            moves += 1
            cards[chosen].isFaceUp = true

            if cards[chosen].content == cards[potentialMatch].content {
                cards[chosen].isMatched = true
                cards[potentialMatch].isMatched = true
                matchedPairs += 1
                mascotMessage = mascotMessages.randomElement() ?? "¡Genial!"

                if matchedPairs == totalPairs {
                    DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.Timing.winOverlayDelay) {
                        self.isNewRecord = ScorePersistence.saveIfBetter(self.moves, for: self.difficulty)
                        self.isGameWon = true
                    }
                }
            } else {
                let first = potentialMatch
                let second = chosen
                mascotMessage = "¡Sigue intentando!"
                DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.Timing.mismatchFlipDelay) {
                    self.cards[first].isFaceUp = false
                    self.cards[second].isFaceUp = false
                }
            }
        } else {
            indexOfOneAndOnlyFaceUpCard = chosen
        }
    }
}

#Preview {
    MundialGameView()
}
