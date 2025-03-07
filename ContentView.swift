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
    @State private var showSettings = false
    @State private var selectedArticleId: UUID? = nil
    @State private var isRefreshing = false
    @State private var animateList = false

    init() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.largeTitleTextAttributes = [
            .font: UIFont(name: "CanelaTrial-Regular", size: 38)!
        ]
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.shadowColor = .clear
        
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.largeTitleTextAttributes[.foregroundColor] = UIColor.label
        
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().standardAppearance = navBarAppearance
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 12)
                
                if isContentReady {
                    List {
                        ForEach(Array(sortedArticles.enumerated()), id: \.element.id) { index, article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                HStack(alignment: .top, spacing: 8) {
                                    if let imagePath = article.image_path {
                                        AsyncImage(url: URL(string: bucketUrl + imagePath)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 60, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                            } else {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 60, height: 80)
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                            }
                                        }
                                    } else {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 80)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(article.title)
                                            .font(.custom("CanelaTrial-Regular", size: 18))
                                            .lineSpacing(4)
                                            .padding(.vertical, 2)
                                            .padding(.top, 2)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        ArticleTimestampView(timestamp: article.created_at, showTime: false)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onAppear {
                                if index == sortedArticles.count - 3 && hasMoreContent && !isLoadingMore {
                                    loadMoreArticles()
                                }
                            }
                            .opacity(animateList ? 1 : 0)
                            .offset(y: animateList ? 0 : 20)
                            .animation(.easeOut(duration: 1).delay(Double(index) * 0.2), value: animateList)
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
                    .refreshable {
                        await refreshArticles()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<5, id: \.self) { _ in
                                HStack(alignment: .top, spacing: 8) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 80)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 18)
                                            .padding(.vertical, 2)
                                            .padding(.top, 2)
                                        
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 100, height: 14)
                                    }
                                    .padding(.trailing, 16)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal)
                    }
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
            .navigationTitle("SwiftyNews")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color(UIColor.label))
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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

    private func loadInitialArticles() {
        print("Starting to load initial articles...")
        isLoading = false
        isContentReady = false
        currentPage = 1
        animateList = false
        
        NewsService().fetchArticles(page: currentPage, pageSize: pageSize) { fetchedArticles, hasMore in
            DispatchQueue.main.async {
                print("Received response on main thread")
                if let fetchedArticles = fetchedArticles {
                    print("Successfully fetched \(fetchedArticles.count) articles")
                    self.articles = fetchedArticles
                    self.hasMoreContent = hasMore
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.isContentReady = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                self.animateList = true
                            }
                        }
                    }
                } else {
                    print("Failed to fetch articles")
                    self.isContentReady = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            self.animateList = true
                        }
                    }
                }
            }
        }
    }
    
    private func refreshArticles() async {
        isRefreshing = true
        animateList = false
        
        withAnimation(.easeOut(duration: 0.3)) {
            isContentReady = false
        }
        
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NewsService().fetchArticles(page: 1, pageSize: pageSize) { fetchedArticles, hasMore in
                    DispatchQueue.main.async {
                        if let fetchedArticles = fetchedArticles {
                            print("Refreshed with \(fetchedArticles.count) articles")
                            self.articles = fetchedArticles
                            self.currentPage = 1
                            self.hasMoreContent = hasMore
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.isContentReady = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    self.animateList = true
                                }
                            }
                            
                            self.isRefreshing = false
                            continuation.resume()
                        }
                    }
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
                if let article = articles.first(where: { $0.id == articleId }) {
                    print("Deep link found article: \(article.title)")
                    selectedArticleId = articleId
                    appState.deepLinkActive = false
                } else {
                    print("Deep link article not found in loaded articles, ID: \(articleId)")
                }
            } else {
                print("Waiting for articles to load before activating deep link")
            }
        }
    }
}
