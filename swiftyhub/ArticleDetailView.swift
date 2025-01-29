import SwiftUI

struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(spacing: 0) { // ✅ Remove extra spacing
                if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill() // ✅ Ensures full width without distortion
                            .frame(width: UIScreen.main.bounds.width, height: 300) // ✅ Uses full screen width
                            .clipped() // ✅ Prevents overflow outside frame
                            .ignoresSafeArea(edges: .top) // ✅ Extends image to the top
                    } placeholder: {
                        ProgressView()
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(article.title)
                        .font(.custom("PlayfairDisplay-Bold", size: 24))
                        .foregroundColor(Color("DarkGrey"))

                    Text("\(article.source.name) • \(formatDate(article.publishedAt))")
                        .font(.custom("EBGaramond-Regular", size: 14))
                        .foregroundColor(Color("MutedGray"))

                    Text((article.content ?? "Full article available via link.").prefix(600) + "...")
                        .font(.custom("EBGaramond-Regular", size: 16))
                        .foregroundColor(Color("DarkGrey"))

                    Link("Read Full Article", destination: URL(string: article.url)!)
                        .font(.custom("EBGaramond-Regular", size: 18))
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color("SoftWhite")) // ✅ Matches app background
                .clipShape(RoundedRectangle(cornerRadius: 16)) // ✅ Smooth rounded look
            }
            .frame(maxWidth: .infinity, alignment: .top) // ✅ Force content to top
        }
        .background(Color("SoftWhite")) // ✅ Background covers entire view
        .ignoresSafeArea(edges: .top) // ✅ Extend ScrollView to top
    }
}
