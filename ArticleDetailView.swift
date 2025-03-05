import SwiftUI
import Foundation

public struct ArticleDetailView: View {
    public let article: Article
    private let bucketUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/news-images/"
    @Environment(\.dismiss) private var dismiss

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
                                    .frame(height: 300)
                                    .clipped()
                            } placeholder: {
                                ProgressView()
                                    .frame(height: 300)
                            }
                        }
                    }
                    .frame(height: 300)

                    VStack(alignment: .leading, spacing: 16) {
                        Text(article.title)
                            .font(.custom("CanelaTrial-Regular", size: 36))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 20)
                            .lineSpacing(6)

                        ArticleTimestampView(timestamp: article.created_at)
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundColor(.gray)
                            .padding(.top, -8)

                        Text(article.ai_content)
                            .font(.custom("AvenirNext-Regular", size: 18))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)

                        if let url = URL(string: article.source_url) {
                            Link("Read more", destination: url)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
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
    }
}
