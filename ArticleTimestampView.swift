import SwiftUI

struct ArticleTimestampView: View {
    let timestamp: String
    var showTime: Bool = true
    var sourceURL: String? = nil
    var onSourceTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            Text(showTime ? timestamp.toFormattedDate() : timestamp.toFormattedDateWithoutTime())
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(.gray)
            
            if let _ = sourceURL {
                Text("•")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(.gray)
                
                Button(action: {
                    onSourceTap?()
                }) {
                    Text(extractHostname(from: sourceURL ?? ""))
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundColor(.gray)
                        .underline()
                }
            }
        }
    }
    
    private func extractHostname(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else { return urlString }
        
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

struct ArticleTimestampView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleTimestampView(
            timestamp: "2023-06-15T14:32:00.000Z",
            sourceURL: "https://www.pagesix.com/article/example",
            onSourceTap: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
