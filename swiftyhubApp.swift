import SwiftUI

@main
struct swiftyhubApp: App {
    init() {
        // Register each custom font
        for fontName in ["Canela-Regular-Trial"] {
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "otf") ??
                           Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
            } else {
                print("⚠️ Failed to find font file: \(fontName)")
            }
        }
        
        // Print registered fonts for debugging
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
            ContentView() // Open your main content view instead of test text
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
