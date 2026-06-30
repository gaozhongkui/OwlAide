import SwiftUI

struct ProcessingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(AppTheme.teal.opacity(0.1), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(AppTheme.teal, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }

            VStack(spacing: 8) {
                Text("AI is generating your summary...")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textMain)

                Text("Analyzing doctor's advice and medication...")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSub)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
