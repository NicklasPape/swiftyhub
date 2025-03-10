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
        GeometryReader { geometry in
            ZStack {
                // Full screen background image
                Image("settings_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .edgesIgnoringSafeArea(.all)
                
                // Dark overlay for better text readability
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                // Content overlay
                VStack(spacing: 20) {
                    Spacer()
                    Text("Swiftyhub is your go-to source for a daily Taylor Swift dose")
                        .font(.custom("CanelaTrial-Regular", size: 34))
                        .lineSpacing(4)
                        .foregroundColor(.white)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.2), value: appeared)
                    
                    Text("✨ Stay up-to-date with the latest Taylor-related news from around the world—each article is sourced from real news outlets but rewritten by AI to be engaging, fun, and factually accurate. When you’re not catching up on news, chat with our Taylor-inspired AI assistant about anything Swiftie-related! We’re constantly improving and would love to hear your feedback, Swifties! 💜")
                        .font(.custom("AvenirNext-Regular", size: 16))
                        .lineSpacing(2)
                        .foregroundColor(.white)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.3), value: appeared)
                    
                    Spacer()
                    
                    Spacer()
                    
                    // Add disclaimer text above the version number
                    Text("Swiftyhub is an aggregation of publicly available information and is committed to accuracy, but is not responsible for inaccurate notifications. Swiftyhub has no affiliation, association, endorsement, or connection with Taylor Swift.")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
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
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom)
                            .offset(y: appeared ? 0 : 10)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(0.4), value: appeared)
                        Spacer()
                    }
                }
                .padding(20)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
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
