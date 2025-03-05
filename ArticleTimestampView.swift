import SwiftUI

struct ArticleTimestampView: View {
    let timestamp: String
    var showTime: Bool = true
    
    var body: some View {
        Text(showTime ? timestamp.toFormattedDate() : timestamp.toFormattedDateWithoutTime())
            .font(.custom("AvenirNext-Regular", size: 14))
            .foregroundColor(.gray)
    }
}

struct ArticleTimestampView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleTimestampView(timestamp: "2023-06-15T14:32:00.000Z")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
