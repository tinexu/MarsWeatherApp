import SwiftUI

struct MarsView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.red, Color.orange, Color.red]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .overlay(
                    // Add craters using smaller circles
                    Group {
                        Circle()
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: 50, height: 50)
                            .offset(x: -70, y: -60)
                        
                        Circle()
                            .fill(Color.red.opacity(0.5))
                            .frame(width: 30, height: 30)
                            .offset(x: 80, y: -30)
                        
                        Circle()
                            .fill(Color.orange.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .offset(x: 20, y: 70)
                    }
                )
                .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 10)
        }
    }
}

struct AppRootView: View {
    @State private var showContentView = false

    var body: some View {
        Group {
            if showContentView {
                ContentView()
            } else {
                MarsView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showContentView = true
                        }
                    }
            }
        }
        .animation(.easeInOut, value: showContentView) // Smooth transition
    }
}


@main
struct MARS_WeatherApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
