import SwiftUI

struct QuizDetailView: View {
    let quiz: Quiz
    let preloadedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var isQuizStarted = false
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    @State private var isLoadingQuizDetails = false
    @State private var quizWithQuestions: Quiz?
    @State private var refreshQuizList = false
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/"
    private let quizService = QuizService()

    init(quiz: Quiz, preloadedImage: UIImage? = nil) {
        self.quiz = quiz
        self.preloadedImage = preloadedImage
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    backgroundView
                    
                    VStack(alignment: .trailing, spacing: 20) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding([.top, .leading])
                            Spacer()
                        }
                        .zIndex(1)
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text(quiz.title)
                                .font(.custom("CanelaTrial-Regular", size: 40))
                                .lineSpacing(6)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            Text(quiz.description)
                                .font(.custom("AvenirNext-Regular", size: 18))
                                .lineSpacing(4)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        
                            HStack {
                                Label(quiz.difficulty, systemImage: "speedometer")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(difficultyColor(for: quiz.difficulty))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                
                                Label("\(quiz.no_questions) questions", systemImage: "list.bullet")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    }
                            .padding(.horizontal)
                            
                            if isLoadingQuizDetails {
                                Button(action: {}) {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        Text("Loading quiz...")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                                }
                                .disabled(true)
                                .padding(.horizontal)
                            } else if let questions = (quizWithQuestions ?? quiz).questions, !questions.isEmpty {
                                NavigationLink(destination: QuizFlowView(quiz: quizWithQuestions ?? quiz, refreshQuizList: .constant(true))) {
                                    Text("Start Quiz")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            } else {
                                Button(action: { isQuizStarted = true }) {
                                    Text("Start Quiz")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                loadImage()
                fetchQuizDetails()
            }
            .alert("No Questions Available", isPresented: $isQuizStarted) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This quiz doesn't have any questions yet. Please check back later.")
            }
        }
        .onChange(of: refreshQuizList) { newValue in
            if newValue {
                dismiss()
            }
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            difficultyColor(for: quiz.difficulty)
                .edgesIgnoringSafeArea(.all)
            
            Group {
                if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                } else if let image = image ?? preloadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                        .transition(.opacity)
                } else {
                    Rectangle()
                        .fill(difficultyColor(for: quiz.difficulty))
                        .frame(height: 200)
                }
            }
            
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func loadImage() {
        guard !quiz.heroImagePath.isEmpty else {
            isLoading = false
            return
        }
        
        let encodedImagePath = quiz.heroImagePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? quiz.heroImagePath
        guard let imageUrl = URL(string: bucketUrl + encodedImagePath) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: imageUrl) { data, _, _ in
            defer {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
            
            if let data = data, let downloadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = downloadedImage
                }
            }
        }.resume()
    }
    
    private func difficultyColor(for difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy":
            return Color.green
        case "medium":
            return Color.orange
        case "hard":
            return Color.red
        case "expert":
            return Color.purple
        default:
            return Color.blue
        }
    }
    
    private func fetchQuizDetails() {
        print("Fetching quiz details for: \(quiz.title) (ID: \(quiz.id))")
        isLoadingQuizDetails = true
        
        quizService.fetchQuizDetails(quizId: quiz.id) { fetchedQuiz in
            isLoadingQuizDetails = false
            if let fetchedQuiz = fetchedQuiz {
                self.quizWithQuestions = fetchedQuiz
                print("✅ Fetched quiz: \(fetchedQuiz.title)")
                if let questions = fetchedQuiz.questions {
                    print("✅ Found \(questions.count) questions")
                    for (i, q) in questions.enumerated() {
                        print("  Question \(i+1): \(q.text)")
                    }
                } else {
                    print("❌ No questions found in quiz")
                }
            } else {
                print("❌ Failed to fetch quiz details")
            }
        }
    }
}
