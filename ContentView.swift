import SwiftUI

struct ContentView: View {
    @State private var articles: [Article] = []
    @State private var isLoading = false
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/news-images/"
    @State private var appeared = false

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
                    
                    List {
                        ForEach(Array(sortedArticles.enumerated()), id: \.element.id) { index, article in
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
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                .easeIn(duration: 1)
                                .delay(Double(index) * 0.1),
                                value: appeared
                            )
                        }
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
        appeared = false
        
        NewsService().fetchArticles { fetchedArticles in
            DispatchQueue.main.async {
                print("Received response on main thread")
                if let fetchedArticles = fetchedArticles {
                    print("Successfully fetched \(fetchedArticles.count) articles")
                    self.articles = fetchedArticles
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.appeared = true
                    }
                    
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
