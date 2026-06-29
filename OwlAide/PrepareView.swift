import SwiftUI
import SwiftData

struct PrepareView: View {
    @Bindable var record: VisitRecord
    var onStartRecording: () -> Void = {}

    @State private var isRecordingSymptom = false
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("\(record.department)")
                    .font(.system(size: 13))
                    .opacity(0.75)
                Text("准备问诊")
                    .font(.system(size: 20, weight: .bold))
                Text("告诉医生您的情况")
                    .font(.system(size: 13))
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(AppTheme.teal)

            ScrollView {
                VStack(spacing: 12) {
                    // Step 1: 症状
                    PrepStepCard(number: 1, title: "哪里不舒服？") {
                        VStack(spacing: 12) {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: isRecordingSymptom ? "waveform" : "mic.fill")
                                    Text(isRecordingSymptom ? "正在听您说..." : "按住说话")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.teal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(isRecordingSymptom ? AppTheme.tealMid.opacity(0.2) : AppTheme.tealLight)
                                .cornerRadius(12)
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if !isRecordingSymptom {
                                            isRecordingSymptom = true
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        }
                                    }
                                    .onEnded { _ in
                                        isRecordingSymptom = false
                                        withAnimation {
                                            let suggestions = ["胸口发闷", "心跳过快", "腿部浮肿", "头晕目眩"]
                                            if let s = suggestions.randomElement(), !record.symptoms.contains(s) {
                                                record.symptoms.append(s)
                                            }
                                        }
                                    }
                            )

                            FlowLayout(spacing: 8) {
                                ForEach(record.symptoms, id: \.self) { symptom in
                                    SymptomChip(text: symptom) {
                                        withAnimation {
                                            record.symptoms.removeAll { $0 == symptom }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Step 2: 用药
                    PrepStepCard(number: 2, title: "目前在吃的药") {
                        VStack(spacing: 0) {
                            ForEach(record.medications) { med in
                                MedicationRow(name: med.name, dose: med.dose)
                            }

                            Button(action: { showCamera = true }) {
                                Text("+ 拍药盒添加")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    )
                            }
                            .padding(.top, 8)
                        }
                    }

                    // Step 3: 问题
                    PrepStepCard(number: 3, title: "想问医生的问题") {
                        VStack(spacing: 0) {
                            ForEach(0..<record.questions.count, id: \.self) { index in
                                QuestionRow(number: index + 1, text: record.questions[index])
                            }

                            Button(action: {
                                withAnimation {
                                    record.questions.append("这个药需要空腹吃吗？")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "mic.fill")
                                    Text("说出您的问题")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.teal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.tealLight)
                                .cornerRadius(12)
                            }
                            .padding(.top, 10)
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background)

            // Bottom Action
            Button(action: onStartRecording) {
                Text("准备好了，开始就诊 →")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.teal)
                    .cornerRadius(14)
                    .padding(16)
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraScannerView { name, dose in
                let newMed = Medication(name: name, dose: dose)
                record.medications.append(newMed)
            }
        }
    }
}
