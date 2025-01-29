import SwiftUI

struct Article: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let source: Source
    let urlToImage: String?
    let publishedAt: String
    let url: String
    let content: String? // ✅ Added missing `content` property

    private enum CodingKeys: String, CodingKey {
        case title, source, urlToImage, publishedAt, url, content
    }
}

struct Source: Codable {
    let name: String
}

class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = true
    
    private let apiKey = "e1dd013d186241249df0823c061e5ec1"
    private let newsURL = "https://newsapi.org/v2/everything?q=Taylor+Swift&sortBy=publishedAt&language=en&apiKey="

    func fetchNews() {
        guard let url = URL(string: newsURL + apiKey) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(NewsResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.articles = decodedResponse.articles.filter {
                            $0.urlToImage != nil && !$0.title.lowercased().contains("gettyimages")
                        }
                        self.isLoading = false
                    }
                } catch {
                    print("Error decoding: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
        }.resume()
    }
}

struct NewsResponse: Codable {
    let articles: [Article]
}

struct ContentView: View {
    @StateObject var viewModel = NewsViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ForEach(0..<5, id: \.self) { _ in
                            ShimmerView()
                        }
                    } else {
                        if viewModel.articles.count >= 5 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.articles.prefix(5)) { article in
                                        NavigationLink(destination: ArticleDetailView(article: article)) {
                                            if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                                                ZStack(alignment: .bottomLeading) {
                                                    AsyncImage(url: url) { image in
                                                        image.resizable()
                                                            .scaledToFill()
                                                            .frame(width: 300, height: 200)
                                                            .clipped()
                                                            .cornerRadius(12)
                                                    } placeholder: {
                                                        ShimmerView()
                                                            .frame(width: 300, height: 200)
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        Text(article.title)
                                                            .font(.custom("Playfair Display Bold", size: 18))
                                                            .foregroundColor(Color("SoftWhite"))
                                                            .baselineOffset(1.5)
                                                            .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)

                                                        
                                                        Text("\(article.source.name) • \(formatDate(article.publishedAt))")
                                                            .font(.custom("EBGaramond-Regular", size: 14))
                                                            .foregroundColor(Color("SoftWhite"))
                                                            .baselineOffset(1.5)

                                                    }
                                                    .padding(20)
                                                    .background(
                                                        LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]), startPoint: .bottom, endPoint: .top)
                                                    )
                                                }
                                                .frame(width: 300, height: 200)
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                                .padding(.leading)
                            }
                        }

                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.articles) { article in
                                NavigationLink(destination: ArticleDetailView(article: article)) {
                                    HStack(spacing: 8) {
                                        if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                                            AsyncImage(url: url) { image in
                                                image.resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipped()
                                                    .cornerRadius(8)
                                            } placeholder: {
                                                ShimmerView()
                                                    .frame(width: 100, height: 100)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(article.title)
                                                .font(.custom("Playfair Display Bold", size: 16))
                                                .foregroundColor(Color("DarkGrey"))
                                                .baselineOffset(1.5)
                                                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)

                                            Text("\(article.source.name) • \(formatDate(article.publishedAt))")
                                                .font(.custom("EB Garamond Regular", size: 12))
                                                .foregroundColor(Color("MutedGray"))
                                                .baselineOffset(1.5)

                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color("SoftWhite"))
            .navigationTitle("Taylor Swift News")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.fetchNews()
            }
        }
    }
}

func formatDate(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
    return "Unknown date"
}
