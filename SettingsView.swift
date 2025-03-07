import SwiftUI

struct SettingsView: View {
    // Get the current app version from the bundle
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "Version \(version) (\(build))"
    }
    
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("Swiftyhub is your go-to source for a daily Taylor Swift dose")
                .font(.custom("CanelaTrial-Regular", size: 34))
                .lineSpacing(4)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).delay(0.2), value: appeared)
            
            Text("✨ Stay up-to-date with the latest Taylor-related news from around the world—each article is sourced from real news outlets but rewritten by AI to be engaging, fun, and factually accurate. When you’re not catching up on news, chat with our Taylor-inspired AI assistant about anything Swiftie-related! We’re constantly improving and would love to hear your feedback, Swifties! 💜")
                .font(.custom("AvenirNext-Regular", size: 16))
                .lineSpacing(2)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).delay(0.3), value: appeared)
            
            Spacer()
            
            Spacer()
            
            // Add disclaimer text above the version number
            Text("Swiftyhub is an aggregation of publicly available information and is committed to accuracy, but is not responsible for inaccurate notifications. Swiftyhub has no affiliation, association, endorsement, or connection with Taylor Swift.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .offset(y: appeared ? 0 : 10)
                .opacity(appeared ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).delay(0.4), value: appeared)
            
            HStack {
                Spacer()
                Text(appVersion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                    .offset(y: appeared ? 0 : 10)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).delay(0.4), value: appeared)
                Spacer()
            }
        }
        .padding(20)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appeared = true
        }
        .onDisappear {
            appeared = false
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
