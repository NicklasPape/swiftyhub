import SwiftUI

struct QuizDetailView: View {
    let quiz: Quiz
    let preloadedImage: UIImage? 
    @Environment(\.presentationMode) var presentationMode
    @State private var isQuizStarted = false
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/"

    init(quiz: Quiz, preloadedImage: UIImage? = nil) {
        self.quiz = quiz
        self.preloadedImage = preloadedImage
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if let preloadedImage = preloadedImage {
                    Image(uiImage: preloadedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                } else if !quiz.heroImagePath.isEmpty {
                    difficultyColor(for: quiz.difficulty)
                        .edgesIgnoringSafeArea(.all)
                    
                    let encodedImagePath = quiz.heroImagePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? quiz.heroImagePath
                    let imageUrl = URL(string: bucketUrl + encodedImagePath)
                    
                    AsyncImage(url: imageUrl) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        } else if phase.error != nil {
                            Color.clear
                        } else {
                            Color.clear
                        }
                    }
                } else {
                    difficultyColor(for: quiz.difficulty)
                        .edgesIgnoringSafeArea(.all)
                }
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Spacer(minLength: 120)
                            
                            Text(quiz.title)
                                .font(.custom("CanelaTrial-Regular", size: 40))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Text(quiz.description)
                                .font(.body)
                                .foregroundColor(.white)
                                .lineSpacing(4)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            
                            HStack(spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "speedometer")
                                        .font(.system(size: 14))
                                    Text(quiz.difficulty)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(difficultyColor(for: quiz.difficulty).opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 14))
                                    Text("\(quiz.no_questions) questions")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            Spacer(minLength: 60)
                        }
                        .padding(.bottom, 100)
                    }
                    
                    Spacer()
                }
                
                VStack {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 60)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isQuizStarted = true
                    }) {
                        HStack {
                            Text("Start now")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Image(systemName: "arrow.right")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $isQuizStarted) {
            Alert(
                title: Text("Coming Soon"),
                message: Text("The quiz functionality will be implemented in a future update."),
                dismissButton: .default(Text("OK"))
            )
        }
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
