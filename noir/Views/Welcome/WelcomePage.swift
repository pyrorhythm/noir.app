import SwiftUI

struct WelcomePage: View {
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white)
                .scaleEffect(isVisible ? 1.0 : 0.5)
                .opacity(isVisible ? 1.0 : 0.0)
                .padding(40)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
            
            VStack(spacing: 8) {
                Text("Welcome to Noir")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("A beautiful menu bar for macOS")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                isVisible = true
            }
        }
    }
}
