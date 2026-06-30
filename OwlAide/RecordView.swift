import SwiftUI

struct RecordView: View {
    @StateObject private var audioManager = AudioManager()
    var onStopRecording: (URL?) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Visit Recording")
                    .font(.system(size: 18, weight: .bold))
                Text("July 3 · Cardiology · General Hospital")
                    .font(.system(size: 13))
                    .opacity(0.6)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
            .background(Color(hex: "1a1a1a"))

            VStack(spacing: 32) {
                Spacer()

                // Pulsing Circle
                ZStack {
                    Circle()
                        .stroke(AppTheme.teal.opacity(0.15), lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .scaleEffect(1.0 + CGFloat(audioManager.audioLevel) * 0.4)

                    Circle()
                        .stroke(AppTheme.teal.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(1.0 + CGFloat(audioManager.audioLevel) * 0.2)

                    Circle()
                        .fill(AppTheme.teal)
                        .frame(width: 140, height: 140)
                        .shadow(color: AppTheme.teal.opacity(0.4), radius: 15)

                    VStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)

                        Text(audioManager.timeString(from: audioManager.recordingTime))
                            .font(.system(size: 16, weight: .bold))
                            .monospacedDigit()
                            .foregroundColor(.white)
                    }
                }

                VStack(spacing: 8) {
                    Text("Recording...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Text("Saved automatically to local storage")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Button(action: {
                    let url = audioManager.stopRecording()
                    onStopRecording(url)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                        Text("End Recording & Summarize")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(AppTheme.teal)
                    .cornerRadius(30)
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "1a1a1a"))
        }
        .onAppear {
            // Unique filename with timestamp
            let timestamp = Int(Date().timeIntervalSince1970)
            audioManager.startRecording(outputName: "visit_\(timestamp)")
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
