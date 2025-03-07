import SwiftUI
import Foundation
import WebKit

struct SafariView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

public struct ArticleDetailView: View {
    public let article: Article
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/news-images/"
    @Environment(\.dismiss) private var dismiss
    @State private var showWebView = false
    @State private var appeared = false
    @State private var showShareSheet = false

    public init(article: Article) {
        self.article = article
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { geometry in
                        if let imagePath = article.image_path {
                            AsyncImage(url: URL(string: bucketUrl + imagePath)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width)
                                    .frame(height: 460)
                                    .clipped()
                                    
                            } placeholder: {
                                ProgressView()
                                    .frame(height: 460)
                            }
                        }
                    }
                    .frame(height: 460)
                    .offset(y: appeared ? 0 : 60)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).delay(0.2), value: appeared)

                    VStack(alignment: .leading, spacing: 16) {
                        Text(article.title)
                            .font(.custom("CanelaTrial-Regular", size: 36))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 20)
                            .lineSpacing(6)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(0.2), value: appeared)

                        ArticleTimestampView(
                            timestamp: article.created_at,
                            sourceURL: article.source_url,
                            onSourceTap: {
                                if let url = URL(string: article.source_url) {
                                    showWebView = true
                                }
                            }
                        )
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, -8)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.3), value: appeared)
                        .sheet(isPresented: $showWebView) {
                            if let url = URL(string: article.source_url) {
                                NavigationView {
                                    SafariView(url: url)
                                        .navigationBarItems(trailing: Button("Done") {
                                            showWebView = false
                                        })
                                }
                                .navigationViewStyle(StackNavigationViewStyle())
                            }
                        }

                        Text(article.ai_content)
                            .font(.custom("AvenirNext-Regular", size: 18))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(0.4), value: appeared)
                        
                        Button(action: {
                            showShareSheet = true
                        }) {
                            HStack {
                                Text("Share article")
                                Image(systemName: "square.and.arrow.up")
                            }
                            .padding()
                            .background(Color("LipstickRed"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.top, 20)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.5), value: appeared)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
                }
                .sheet(isPresented: $showShareSheet) {
                    let appLink = "swiftyhub://article/\(article.id.uuidString)"
                    
                    let shareText = "\(article.title)\n\n\(String(article.ai_content.prefix(100)))...\n\nRead in SwiftyHub: \(appLink)"
                    
                    ActivityViewController(activityItems: [shareText])
                }
            }
            .edgesIgnoringSafeArea(.top)

            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(.top, 8)
            .padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .onAppear {
            appeared = true
        }
        .onDisappear {
            appeared = false
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
