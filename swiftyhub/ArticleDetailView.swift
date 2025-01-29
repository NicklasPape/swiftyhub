import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                Text(article.title)
                    .font(.custom("PlayfairDisplay-Bold", size: 24))
                    .foregroundColor(Color("DarkGrey"))
                
                Text("\(article.source.name) • \(formatDate(article.publishedAt))")
                    .font(.custom("EBGaramond-Regular", size: 14))
                    .foregroundColor(Color("MutedGray"))
                
                Link("Read Full Article", destination: URL(string: article.url)!)
                    .font(.custom("EBGaramond-Regular", size: 18))
                    .foregroundColor(Color("DarkGrey"))
                
                Spacer()
            }
            .padding()
        }
        .background(Color("SoftWhite"))
        .navigationTitle("Swift News")
        .navigationBarTitleDisplayMode(.inline)
    }
}
