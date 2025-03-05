import SwiftUI

struct ContentView: View {
    @State private var articles: [Article] = []
    @State private var isLoading = false
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/news-images/"

    var body: some View {
        NavigationView {
            ZStack {
                List(sortedArticles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        HStack {
                            if let imagePath = article.image_path {
                                AsyncImage(url: URL(string: bucketUrl + imagePath)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(article.title)
                                    .font(.custom("AvenirNext-DemiBold", size: 17))
                                ArticleTimestampView(timestamp: article.created_at, showTime: false)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if isLoading {
                    ProgressView()
                }
            }
            .onAppear {
                loadArticles()
            }
            .navigationTitle("Swiftynews")
        }
    }

    private func loadArticles() {
        print("Starting to load articles...")
        isLoading = true
        NewsService().fetchArticles { fetchedArticles in
            DispatchQueue.main.async {
                print("Received response on main thread")
                if let fetchedArticles = fetchedArticles {
                    print("Successfully fetched \(fetchedArticles.count) articles")
                    self.articles = fetchedArticles
                } else {
                    print("Failed to fetch articles")
                }
                self.isLoading = false
            }
        }
    }

    var sortedArticles: [Article] {
        return articles.sorted { $0.created_at > $1.created_at }
    }
}
