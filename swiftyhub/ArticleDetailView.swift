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
                            .font(.custom("AvenirNext-DemiBold", size: 24))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 16)

                        Text(article.ai_content)
                            .font(.custom("AvenirNext-Regular", size: 17))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)

                        if let url = URL(string: article.source_url) {
                            Link("Read more", destination: url)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 16)
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
            .padding(.top, 48)
            .padding(.leading, 16)
        }
        .navigationBarHidden(true)
    }
}
