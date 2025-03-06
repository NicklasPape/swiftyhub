import SwiftUI

struct SettingsView: View {
    // Get the current app version from the bundle
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("SwiftyNews is your go-to source for your daily Taylor Swift dose.")
                .font(.custom("CanelaTrial-Regular", size: 34))
                .lineSpacing(4)


            Text("Every article is AI-generated based on real news sources, designed to be engaging and fun—while staying true to the facts. When not reading news, ask Taylor about anything. We’re always improving and would love your feedback, Swifties!")
                .font(.body)
            
            Spacer()
            
            Text(appVersion)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
