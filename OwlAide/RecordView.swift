import SwiftUI

struct RecordView: View {
    @StateObject private var audioManager = AudioManager()
    var onStopRecording: (URL?) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("就诊录音")
                    .font(.system(size: 18, weight: .bold))
                Text("7月3日 · 心内科 · 协和医院")
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
                    Text("正在录音中…")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Text("已为您自动保存至本地")
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
                        Text("结束录音，生成摘要")
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
            // 使用时间戳作为文件名，确保唯一性
            let timestamp = Int(Date().timeIntervalSince1970)
            audioManager.startRecording(outputName: "visit_\(timestamp)")
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
