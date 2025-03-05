import SwiftUI

 
class AppState: ObservableObject {
    @Published var selectedArticleId: UUID?
    @Published var deepLinkActive: Bool = false
}

 
@main
struct swiftyhubApp: App {
    @StateObject private var appState = AppState()

    @Environment(\.openURL) var openURL

    init() {
        for fontName in ["Canela-Regular-Trial"] {
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "otf") ??
                           Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
            } else {
                print("⚠️ Failed to find font file: \(fontName)")
            }
        }
        
        print("📱 Registered fonts:")
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("- \(name)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView() 
                .navigationViewStyle(StackNavigationViewStyle())
                .environmentObject(appState) 
                .onOpenURL { url in
                    print("Received URL: \(url)")
                    
                    if url.host == "article", let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                       let pathComponents = components.path.split(separator: "/").last,
                       let uuidString = String(pathComponents).removingPercentEncoding,
                       let articleId = UUID(uuidString: uuidString) {
                        print("Setting deep link for article: \(articleId)")
                        appState.selectedArticleId = articleId
                        appState.deepLinkActive = true
                    }
                }
        }
    }
}
