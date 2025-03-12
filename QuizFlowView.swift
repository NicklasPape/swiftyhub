import SwiftUI
import ConfettiSwiftUI

struct QuizFlowView: View {
    let quiz: Quiz
    @Environment(\.dismiss) private var dismiss
    @Binding var refreshQuizList: Bool
    
    // Quiz state
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var isAnswerSubmitted = false
    @State private var correctAnswers = 0
    @State private var incorrectAnswers = 0
    @State private var isQuizFinished = false
    @State private var confettiCounter = 0 // For triggering confetti at the end
    @State private var correctAnswerConfetti = 0 // For triggering confetti on correct answers
    @State private var resultsConfettiTimers: [Timer] = [] // For tracking multiple confetti timers
    
    // Computed properties
    private var currentQuestion: Question? {
        guard let questions = quiz.questions,
              currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    private var isLastQuestion: Bool {
        guard let questions = quiz.questions else { return true }
        return currentQuestionIndex >= questions.count - 1
    }
    
    private var correctAnswerSelected: Bool {
        guard let selectedAnswer = selectedAnswerIndex,
              let question = currentQuestion else { return false }
        return selectedAnswer == question.correctAnswerIndex
    }
    
    private var percentage: Double {
        let total = correctAnswers + incorrectAnswers
        guard total > 0 else { return 0 }
        return Double(correctAnswers) / Double(total) * 100.0
    }
    
    private var resultMessage: String {
        if percentage >= 100 {
            // Perfect score message with "Long Live" reference
            return "🏆 Long Live Your Perfect Score!\nOne day they'll tell the story of how you reigned! You're the best of the best, and in the words of Taylor Swift: 'Long live all the magic we made!'"
        } else if percentage >= 81 {
            // Near perfect with "Wildest Dreams" reference
            return "🌟 Say You'll Remember This!\nStanding ovation, what a masterful show! Even in your wildest dreams, you couldn't have done much better. You're getting closer to that perfect score - nothing lasts forever, but this score is looking pretty good!"
        } else if percentage >= 51 {
            // Good score with "Shake It Off" reference
            return "📚 Keep Cruising, Don't Stop!\nPlayers gonna play, and learners gonna learn - just shake off those wrong answers! You're doing great, and remember: 'The haters gonna hate... but I'm just gonna shake!'"
        } else if percentage >= 21 {
            // Lower score with "Begin Again" reference
            return "🌱 Time to Begin Again!\nOn a Wednesday, in a café... okay, maybe not, but it's time to start fresh! Take a deep breath, and remember: every expert was once a beginner. This is just the beginning of your story!"
        } else {
            // Low score with "Anti-Hero" reference
            return "🎯 It's Me, Hi, I'm... Learning!\nSometimes it's hard to be the anti-hero of your own quiz story, but hey - it's me, hi, I'm the one learning, it's me! Time to study up and try again. You've got this!"
        }
    }
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            if isQuizFinished {
                quizResultView
                    .onAppear {
                        // Fire multiple confetti cannons with delays
                        for i in 0..<correctAnswers {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                                self.confettiCounter += 1
                                
                                // Add haptic feedback for each cannon
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred(intensity: 0.7 + Double(i) * 0.1)
                            }
                        }
                    }
            } else if let question = currentQuestion {
                questionFlowView(question: question)
            } else {
                // Fallback if questions aren't available
                VStack {
                    Text("No questions available for this quiz")
                    Button("Go Back") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .padding()
            }
            
            // Place confetti at the bottom of the screen
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    ConfettiCannon(trigger: $confettiCounter,
                                  num: 100,
                                  confettis: [.text("🎉"), .text("⭐"), .text("🩷")],
                                  colors: [.red, .green, .blue, .yellow, .purple],
                                  openingAngle: Angle(degrees: 0),
                                  closingAngle: Angle(degrees: 180),
                                  radius: 400)
                        .offset(y: 40) // Move below screen edge
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Confetti for correct answers remains at the options level
            if let question = currentQuestion, isAnswerSubmitted, correctAnswerSelected {
                VStack {
                    Spacer().frame(height: 350)
                    ConfettiCannon(trigger: $correctAnswerConfetti,
                                  num: 50,
                                  confettis: [.text("💛"), .text("⭐")],
                                  colors: [.green, .yellow],
                                  radius: 400)
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                    Text("Back")
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    private func questionFlowView(question: Question) -> some View {
        VStack(spacing: 24) {
            // Question header
            Text("Question \(currentQuestionIndex + 1) of \(quiz.questions?.count ?? 0)")
                .font(.custom("CanelaTrial-Regular", size: 24))
                .foregroundColor(.black)
                .padding(.top)
            
            // Question text
            Text(question.text)
                .font(.custom("AvenirNext-Regular", size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)
            
            Spacer()
                .frame(height: 20)
            
            // Answer options
            VStack(spacing: 12) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    Button(action: {
                        if !isAnswerSubmitted {
                            selectedAnswerIndex = index
                            isAnswerSubmitted = true
                            processAnswer()
                        }
                    }) {
                        Text(question.options[index])
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(answerBackgroundColor(for: index))
                            .foregroundColor(answerTextColor(for: index))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(answerBorderColor(for: index), lineWidth: 2)
                            )
                    }
                    .disabled(isAnswerSubmitted)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Next button
            if isAnswerSubmitted {
                Button(action: {
                    if isLastQuestion {
                        isQuizFinished = true
                    } else {
                        nextQuestion()
                    }
                }) {
                    Text(isLastQuestion ? "See Results" : "Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private var quizResultView: some View {
        VStack(spacing: 24) {
            Text("Results")
                .font(.custom("CanelaTrial-Regular", size: 32))
                .foregroundColor(.black)
            
            Text(resultMessage)
                .font(.custom("AvenirNext-Regular", size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.8))
                .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("\(correctAnswers)")
                        .font(.custom("CanelaTrial-Regular", size: 32))
                    VStack(alignment: .leading) {
                        Text("Correct answers")
                            .font(.system(size: 16))
                    }
                    Spacer()
                }
                
                HStack {
                    Text("\(incorrectAnswers)")
                        .font(.custom("CanelaTrial-Regular", size: 32))
                    VStack(alignment: .leading) {
                        Text("Incorrect answers")
                            .font(.system(size: 16))
                    }
                    Spacer()
                }
                
                HStack {
                    Text("\(Int(percentage))%")
                        .font(.custom("CanelaTrial-Regular", size: 32))
                    VStack(alignment: .leading) {
                        Text("Percentage correct")
                            .font(.system(size: 16))
                    }
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                completeQuiz()
            }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func answerBackgroundColor(for index: Int) -> Color {
        guard isAnswerSubmitted else { return Color.white }
        
        if index == currentQuestion?.correctAnswerIndex {
            return Color.green.opacity(0.2) // Correct answer
        } else if index == selectedAnswerIndex {
            return Color.red.opacity(0.2) // Selected but wrong
        }
        return Color.white
    }
    
    private func answerBorderColor(for index: Int) -> Color {
        if !isAnswerSubmitted && index == selectedAnswerIndex {
            return Color.blue // Selected but not submitted
        } else if isAnswerSubmitted {
            if index == currentQuestion?.correctAnswerIndex {
                return Color.green // Correct answer
            } else if index == selectedAnswerIndex {
                return Color.red // Selected answer
            }
        }
        return Color.gray.opacity(0.3)
    }
    
    private func answerTextColor(for index: Int) -> Color {
        if isAnswerSubmitted && index == currentQuestion?.correctAnswerIndex {
            return Color.green // Correct answer
        } else if isAnswerSubmitted && index == selectedAnswerIndex && index != currentQuestion?.correctAnswerIndex {
            return Color.red // Wrong answer
        }
        return Color.black
    }
    
    private func processAnswer() {
        if correctAnswerSelected {
            correctAnswers += 1
            
            // Trigger confetti for correct answer with slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.correctAnswerConfetti += 1
            }
            
            // Add medium impact haptic feedback for correct answers
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } else {
            incorrectAnswers += 1
            
            // Add light haptic feedback for incorrect answers
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private func nextQuestion() {
        currentQuestionIndex += 1
        selectedAnswerIndex = nil
        isAnswerSubmitted = false
    }
    
    private func completeQuiz() {
        Quiz.markCompleted(quiz.id, score: Double(percentage))
        refreshQuizList = true
        dismiss()
    }
}
