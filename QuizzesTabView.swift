import SwiftUI

struct QuizzesTabView: View {
    @State private var quizzes: [Quiz] = []
    @State private var isLoading = true
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var animateList = false
    @State private var selectedQuiz: Quiz? = nil
    @State private var isShowingQuizDetail = false
    @State private var preloadedQuizImage: UIImage? = nil

    private let imageCache = NSCache<NSString, UIImage>()
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Loading quizzes...")
                            .foregroundColor(.gray)
                    }
                } else if quizzes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.square.dashed")
                            .font(.system(size: 70))
                            .foregroundColor(.gray)
                        Text("No quizzes available")
                            .font(.title2)
                        Text("Check back soon for new quizzes!")
                            .foregroundColor(.gray)
                            .padding(.bottom, 20)
                        
                        Button(action: {
                            loadQuizzes()
                        }) {
                            Text("Retry")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                                .background(Color("LipstickRed"))
                                .cornerRadius(10)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(Array(quizzes.enumerated()), id: \.element.id) { index, quiz in
                                Button(action: {
                                    // Preload quiz image before showing detail view
                                    if !quiz.heroImagePath.isEmpty {
                                        let encodedImagePath = quiz.heroImagePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? quiz.heroImagePath
                                        let imageUrl = URL(string: bucketUrl + encodedImagePath)
                                        
                                        // Try to use cached image first
                                        if let url = imageUrl,
                                           let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
                                            preloadedQuizImage = cachedImage
                                            selectedQuiz = quiz
                                            isShowingQuizDetail = true
                                        } else {
                                            // Otherwise load the image in background first
                                            URLSession.shared.dataTask(with: imageUrl!) { data, response, error in
                                                if let data = data, let image = UIImage(data: data) {
                                                    DispatchQueue.main.async {
                                                        // Cache the image for future use
                                                        if let url = imageUrl {
                                                            self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
                                                        }
                                                        preloadedQuizImage = image
                                                        selectedQuiz = quiz
                                                        isShowingQuizDetail = true
                                                    }
                                                } else {
                                                    // Show without preloaded image if failed
                                                    DispatchQueue.main.async {
                                                        preloadedQuizImage = nil
                                                        selectedQuiz = quiz
                                                        isShowingQuizDetail = true
                                                    }
                                                }
                                            }.resume()
                                        }
                                    } else {
                                        // If no image, just show the quiz
                                        preloadedQuizImage = nil
                                        selectedQuiz = quiz
                                        isShowingQuizDetail = true
                                    }
                                }) {
                                    QuizCardView(quiz: quiz)
                                        .padding(.horizontal)
                                        .opacity(animateList ? 1 : 0)
                                        .offset(y: animateList ? 0 : 20)
                                        .animation(
                                            .easeOut(duration: 0.7)
                                            .delay(Double(index) * 0.15),
                                            value: animateList
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.bottom, 10)
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await refreshQuizzes()
                    }
                }
            }
            .navigationTitle("Quizzes")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if quizzes.isEmpty {
                    loadQuizzes()
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .fullScreenCover(isPresented: $isShowingQuizDetail) {
                if let quiz = selectedQuiz {
                    QuizDetailView(quiz: quiz, preloadedImage: preloadedQuizImage)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
    
    private func loadQuizzes() {
        isLoading = true
        animateList = false
        
        QuizService().fetchQuizzes { fetchedQuizzes in
            DispatchQueue.main.async {
                self.quizzes = fetchedQuizzes
                self.isLoading = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        self.animateList = true
                    }
                }
            }
        }
    }
    
    private func refreshQuizzes() async {
        await withCheckedContinuation { continuation in
            QuizService().fetchQuizzes { fetchedQuizzes in
                DispatchQueue.main.async {
                    self.quizzes = fetchedQuizzes
                    self.animateList = true
                    continuation.resume()
                }
            }
        }
    }
}

struct QuizCardView: View {
    let quiz: Quiz
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/"
    
    var body: some View {
        ZStack {
            if !quiz.heroImagePath.isEmpty {
                let fullUrl = bucketUrl + quiz.heroImagePath
                let imageUrl = URL(string: fullUrl)
                
                AsyncImage(url: imageUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 240)
                            .onAppear {
                                print("Successfully loaded image from URL: \(String(describing: imageUrl))")
                            }
                    } else if phase.error != nil {
                        fallbackImage
                            .onAppear {
                                print("Error loading image: \(String(describing: phase.error))")
                                print("Failed URL: \(String(describing: imageUrl))")
                                print("Image path: \(quiz.heroImagePath)")
                            }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .background(Color.gray.opacity(0.2))
                            .onAppear {
                                print("Loading image from URL: \(String(describing: imageUrl))")
                            }
                    }
                }
            } else {
                fallbackImage
                    .frame(height: 240)
            }
            
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.6), Color.black.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(alignment: .leading, spacing: 10) {
                Spacer()
                
                Text(quiz.title)
                    .font(.custom("CanelaTrial-Regular", size: 26))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(quiz.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .padding(.bottom, 6)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 12))
                        Text(quiz.difficulty)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor(for: quiz.difficulty).opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 12))
                        Text("\(quiz.no_questions) questions")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Spacer()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            print("QuizCardView appeared for quiz: \(quiz.title), image path: \(quiz.heroImagePath)")
        }
    }
    
    private var fallbackImage: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(16/9, contentMode: .fill)
                .frame(height: 240)
            
            Image(systemName: getSystemImageName(for: quiz.title))
                .font(.system(size: 50))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [getColor(for: quiz.title).opacity(0.7), getColor(for: quiz.title)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    private func getSystemImageName(for title: String) -> String {
        let lowercasedTitle = title.lowercased()
        if lowercasedTitle.contains("swift") {
            return "swift"
        } else if lowercasedTitle.contains("ui") || lowercasedTitle.contains("interface") {
            return "square.on.square"
        } else if lowercasedTitle.contains("ios") || lowercasedTitle.contains("mobile") {
            return "iphone"
        } else if lowercasedTitle.contains("advanced") || lowercasedTitle.contains("expert") {
            return "gear.circle"
        }
        return "questionmark.square"
    }
    
    private func getColor(for title: String) -> Color {
        let lowercasedTitle = title.lowercased()
        if lowercasedTitle.contains("swift") && !lowercasedTitle.contains("ui") {
            return Color.orange
        } else if lowercasedTitle.contains("ui") || lowercasedTitle.contains("interface") {
            return Color.blue
        } else if lowercasedTitle.contains("ios") || lowercasedTitle.contains("mobile") {
            return Color.green
        } else if lowercasedTitle.contains("advanced") || lowercasedTitle.contains("expert") {
            return Color.purple
        }
        return Color.gray
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
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct QuizzesTabView_Previews: PreviewProvider {
    static var previews: some View {
        QuizzesTabView()
    }
}
