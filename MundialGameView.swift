// MundialGameView.swift
// Juego de Memoria del Mundial - Servicio Social
// Autor: Luis Gabriel Sáenz Contreras

import SwiftUI
import AudioToolbox

struct MundialGameView: View {
    @StateObject private var game = MundialMemoryGame()
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let successFeedback = UINotificationFeedbackGenerator()
    private let errorFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.7),
                    Color.white.opacity(0.5),
                    Color.red.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.title)
                    Text("⚽ Memoria del Mundial ⚽")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.title)
                }
                .padding(.top, 30)
                .shadow(color: .black.opacity(0.3), radius: 5)
                
                HStack(spacing: 12) {
                    Text("🐉")
                        .font(.system(size: 40))
                    
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
                
                HStack(spacing: 20) {
                    VStack {
                        Text("Movimientos")
                            .font(.caption2)
                            .foregroundColor(.white)
                        Text("\(game.moves)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(12)
                    
                    VStack {
                        Text("Parejas")
                            .font(.caption2)
                            .foregroundColor(.white)
                        Text("\(game.matchedPairs)/\(game.totalPairs)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(12)
                    
                    Button(action: {
                        impactFeedback.impactOccurred()
                        AudioServicesPlaySystemSound(1104)
                        game.newGame()
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(game.currentTip)
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60, maximum: 80))], spacing: 10) {
                        ForEach(Array(game.cards.enumerated()), id: \.element.id) { index, card in
                            MundialCardView(card: card)
                                .aspectRatio(0.7, contentMode: .fit)
                                .onTapGesture {
                                    handleCardTap(card)
                                }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
            
            if game.isGameWon {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("🐉")
                            .font(.system(size: 80))
                        
                        Text("¡GANASTE!")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.yellow)
                        
                        Text(game.rating)
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text("Movimientos: \(game.moves)")
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Text("¡Quetzal está orgulloso de ti! 🎉")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            impactFeedback.impactOccurred()
                            AudioServicesPlaySystemSound(1104)
                            game.newGame()
                        }) {
                            Text("Jugar de nuevo")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(20)
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
                    AudioServicesPlaySystemSound(1025)
                }
            }
        }
    }
    
    private func handleCardTap(_ card: MundialGameCard) {
        AudioServicesPlaySystemSound(1104)
        impactFeedback.impactOccurred()
        
        let wasMatch = game.cards.filter({ $0.isMatched }).count
        
        withAnimation {
            game.choose(card)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let newMatches = game.cards.filter({ $0.isMatched }).count
            if newMatches > wasMatch {
                AudioServicesPlaySystemSound(1057)
                successFeedback.notificationOccurred(.success)
            } else if game.moves > 0 {
                errorFeedback.notificationOccurred(.warning)
            }
        }
    }
}

struct MundialCardView: View {
    let card: MundialGameCard
    
    var body: some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: 12)
            
            if card.isFaceUp {
                shape.fill(.white)
                shape.strokeBorder(lineWidth: 2)
                    .foregroundColor(.blue)
                Text(card.content)
                    .font(.system(size: 35))
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
    }
}

struct MundialGameCard: Identifiable {
    let id = UUID()
    let content: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

class MundialMemoryGame: ObservableObject {
    @Published private(set) var cards: [MundialGameCard] = []
    @Published private(set) var moves: Int = 0
    @Published private(set) var matchedPairs: Int = 0
    @Published private(set) var isGameWon: Bool = false
    @Published private(set) var mascotMessage: String = "¡Vamos a jugar!"
    @Published private(set) var currentTip: String = ""
    
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
    
    var totalPairs: Int {
        cards.count / 2
    }
    
    var rating: String {
        if moves <= 15 {
            return "¡Excelente! ⭐⭐⭐"
        } else if moves <= 25 {
            return "¡Muy bien! ⭐⭐"
        } else {
            return "¡Lo lograste! ⭐"
        }
    }
    
    private var indexOfOneAndOnlyFaceUpCard: Int? {
        get {
            let faceUpCardIndices = cards.indices.filter { cards[$0].isFaceUp }
            return faceUpCardIndices.count == 1 ? faceUpCardIndices.first : nil
        }
        set {
            cards.indices.forEach { cards[$0].isFaceUp = ($0 == newValue) }
        }
    }
    
    init() {
        newGame()
    }
    
    func newGame() {
        let gameSymbols = Array(worldCupSymbols.prefix(8))
        let cardContents = gameSymbols + gameSymbols
        cards = cardContents.shuffled().map { MundialGameCard(content: $0) }
        
        moves = 0
        matchedPairs = 0
        isGameWon = false
        mascotMessage = "¡Vamos a jugar!"
        currentTip = educationalTips.randomElement() ?? "¡Diviértete aprendiendo!"
    }
    
    func choose(_ card: MundialGameCard) {
        guard let chosenIndex = cards.firstIndex(where: { $0.id == card.id }),
              !cards[chosenIndex].isFaceUp,
              !cards[chosenIndex].isMatched else {
            return
        }
        
        if let potentialMatchIndex = indexOfOneAndOnlyFaceUpCard {
            moves += 1
            cards[chosenIndex].isFaceUp = true
            
            if cards[chosenIndex].content == cards[potentialMatchIndex].content {
                cards[chosenIndex].isMatched = true
                cards[potentialMatchIndex].isMatched = true
                matchedPairs += 1
                mascotMessage = mascotMessages.randomElement() ?? "¡Genial!"
                
                if matchedPairs == totalPairs {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isGameWon = true
                    }
                }
            } else {
                let firstIndex = potentialMatchIndex
                let secondIndex = chosenIndex
                mascotMessage = "¡Sigue intentando!"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.cards[firstIndex].isFaceUp = false
                    self.cards[secondIndex].isFaceUp = false
                }
            }
        } else {
            indexOfOneAndOnlyFaceUpCard = chosenIndex
        }
    }
}

#Preview {
    MundialGameView()
}
