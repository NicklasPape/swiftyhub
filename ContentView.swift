import SwiftUI

struct ContentView: View {
    @State private var articles: [Article] = []
    @State private var isLoading = false
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/news-images/"

    init() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.largeTitleTextAttributes = [
            .font: UIFont(name: "CanelaTrial-Regular", size: 38)!
        ]
        navBarAppearance.backgroundColor = .white
        navBarAppearance.shadowColor = .clear
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().standardAppearance = navBarAppearance
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 12)
                    
                    List(sortedArticles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            HStack(alignment: .top, spacing: 8) {
                                if let imagePath = article.image_path {
                                    AsyncImage(url: URL(string: bucketUrl + imagePath)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .padding(.vertical, 4)
                                            .padding(.horizontal,8)
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 80)
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 80)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(article.title)
                                        .font(.custom("CanelaTrial-Regular", size: 24))
                                        .lineSpacing(4)
                                        .padding(.vertical, 1)
                                    ArticleTimestampView(timestamp: article.created_at, showTime: false)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                }
                
                if isLoading {
                    ProgressView()
                }
            }
            .onAppear {
                loadArticles()
            }
            .navigationTitle("Swiftynews")
            .navigationBarTitleDisplayMode(.large)
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
