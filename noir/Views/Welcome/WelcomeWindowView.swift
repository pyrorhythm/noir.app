import SwiftUI

struct WelcomeWindowView: View {
    @Environment(BarManager.self) var barManager
    @Environment(SettingsStore.self) var settings
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Group {
                    switch currentPage {
                    case 0:
                        WelcomePage()
                    case 1:
                        PermissionsPage()
                    case 2:
                        WelcomeDonePage()
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
                .id(currentPage)
                
                Spacer()
                
                Button {
                    if currentPage < 2 {
                        withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                            currentPage += 1
                        }
                    } else {
                        hasCompletedOnboarding = true
                        dismiss()
                    }
                } label: {
                    Text(currentPage < 2 ? "Continue" : "Get Started")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
    }
}
