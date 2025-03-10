import SwiftUI

struct SplashView: View {
    @State private var opacity = 0.0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.showSplash {
            GeometryReader { geometry in
                ZStack(alignment: .center) {
                    // Full screen background image with centered positioning
                    Image("splash_background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .ignoresSafeArea()
            .opacity(opacity)
            .onAppear {
                // Fade in animation
                withAnimation(.easeIn(duration: 1.0)) {
                    self.opacity = 1.0
                }
                
                // Transition to main content after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        // Instead of using isActive state, update the appState
                        appState.showSplash = false
                    }
                }
            }
        } else {
            ContentView()
                .environmentObject(appState)
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .environmentObject(AppState())
    }
}
