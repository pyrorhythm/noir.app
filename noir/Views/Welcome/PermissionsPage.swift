import SwiftUI
import ApplicationServices

struct PermissionsPage: View {
    @State private var isGranted = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Image(systemName: "macwindow")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                        .background(Circle().fill(.white))
                        .offset(x: 30, y: 30)
                }
            }
            .padding(40)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
            
            VStack(spacing: 16) {
                Text("Accessibility Access")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Noir needs Accessibility permission to detect window managers and respond to media keys.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button {
                    let options = ["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary
                    let trusted = AXIsProcessTrustedWithOptions(options)
                    isGranted = trusted
                } label: {
                    Text(isGranted ? "Access Granted" : "Grant Access")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(isGranted ? Color.green : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(isGranted)
                .padding(.top, 16)
            }
        }
        .onAppear {
            isGranted = AXIsProcessTrusted()
        }
    }
}
