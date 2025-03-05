import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var articles: [Article] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var isContentReady = false
    @State private var currentPage = 1
    @State private var hasMoreContent = true
    private let pageSize = 10
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/news-images/"
    @State private var appeared = false
    @State private var showSettings = false
    @State private var selectedArticleId: UUID? = nil

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
                    
                    if isContentReady {
                        List {
                            ForEach(Array(sortedArticles.enumerated()), id: \.element.id) { index, article in
                                NavigationLink(isActive: Binding(
                                    get: { selectedArticleId == article.id },
                                    set: { if $0 { selectedArticleId = article.id } else { selectedArticleId = nil } }
                                )) {
                                    ArticleDetailView(article: article)
                                } label: {
                                    HStack(alignment: .top, spacing: 8) {
                                        if let imagePath = article.image_path {
                                            AsyncImage(url: URL(string: bucketUrl + imagePath)) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 60, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal,8)
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 60, height: 80)
                                            }
                                        } else {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 60, height: 80)
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(article.title)
                                                .font(.custom("CanelaTrial-Regular", size: 24))
                                                .lineSpacing(4)
                                                .padding(.vertical, 2)
                                                .padding(.top, 2)
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
                                    .easeIn(duration: 0.5)
                                    .delay(Double(index) * 0.2),
                                    value: appeared
                                )
                                .onAppear {
                                    if index == sortedArticles.count - 3 && hasMoreContent && !isLoadingMore {
                                        loadMoreArticles()
                                    }
                                }
                            }
                            
                            if isLoadingMore && hasMoreContent {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(PlainListStyle())
                    } else {
                        Spacer()
                    }
                }
                
                if isLoading {
                    ProgressView()
                }
            }
            .onAppear {
                if articles.isEmpty {
                    loadInitialArticles()
                }
                
                checkForDeepLink()
            }
            .onChange(of: appState.deepLinkActive) { _, newValue in
                if newValue {
                    checkForDeepLink()
                }
            }
            .navigationTitle("Swiftynews")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    showSettings = false
                                }) {
                                    Text("Done")
                                }
                            }
                        }
                }
            }
        }
        .environmentObject(appState)
    }

    private func loadInitialArticles() {
        print("Starting to load initial articles...")
        isLoading = true
        appeared = false
        isContentReady = false
        currentPage = 1
        
        NewsService().fetchArticles(page: currentPage, pageSize: pageSize) { fetchedArticles, hasMore in
            DispatchQueue.main.async {
                print("Received response on main thread")
                if let fetchedArticles = fetchedArticles {
                    print("Successfully fetched \(fetchedArticles.count) articles")
                    self.articles = fetchedArticles
                    self.hasMoreContent = hasMore
                    self.isLoading = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.isContentReady = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.appeared = true
                        }
                    }
                } else {
                    print("Failed to fetch articles")
                    self.isLoading = false
                    self.isContentReady = true
                }
            }
        }
    }
    
    private func loadMoreArticles() {
        guard hasMoreContent && !isLoadingMore else { return }
        
        print("Loading more articles, page \(currentPage + 1)")
        isLoadingMore = true
        
        NewsService().fetchArticles(page: currentPage + 1, pageSize: pageSize) { fetchedArticles, hasMore in
            DispatchQueue.main.async {
                if let fetchedArticles = fetchedArticles, !fetchedArticles.isEmpty {
                    print("Successfully fetched \(fetchedArticles.count) more articles")
                    self.articles.append(contentsOf: fetchedArticles)
                    self.currentPage += 1
                    self.hasMoreContent = hasMore
                } else {
                    self.hasMoreContent = false
                    print("No more articles to fetch")
                }
                self.isLoadingMore = false
            }
        }
    }

    var sortedArticles: [Article] {
        return articles.sorted { $0.created_at > $1.created_at }
    }

    private func checkForDeepLink() {
        if appState.deepLinkActive, let articleId = appState.selectedArticleId {
            if !articles.isEmpty {
                // Find the article with the matching ID
                if let article = articles.first(where: { $0.id == articleId }) {
                    print("Deep link found article: \(article.title)")
                    // Navigate to the article by setting the selectedArticleId
                    DispatchQueue.main.async {
                        self.selectedArticleId = articleId
                        // Reset the deep link flag to prevent repeated navigation
                        self.appState.deepLinkActive = false
                    }
                } else {
                    print("Deep link article not found in loaded articles, ID: \(articleId)")
                    // The article isn't loaded yet, keep the deep link active
                }
            } else {
                print("Waiting for articles to load before activating deep link")
            }
        }
    }
}
