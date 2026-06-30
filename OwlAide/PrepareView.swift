import SwiftUI
import SwiftData

struct PrepareView: View {
    @Bindable var record: VisitRecord
    var onStartRecording: () -> Void = {}

    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var questionRecognizer = SpeechRecognizer()
    @State private var isRecordingSymptom = false
    @State private var isRecordingQuestion = false
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(record.department)
                    .font(.system(size: 13))
                    .opacity(0.75)
                Text("Prepare for Visit")
                    .font(.system(size: 20, weight: .bold))
                Text("Tell the doctor about your condition")
                    .font(.system(size: 13))
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(AppTheme.teal)

            ScrollView {
                VStack(spacing: 12) {
                    // Step 1: Symptoms
                    PrepStepCard(number: 1, title: String(localized: "What's bothering you?")) {
                        VStack(spacing: 12) {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: isRecordingSymptom ? "waveform" : "mic.fill")
                                    Text(isRecordingSymptom ? "Listening..." : "Hold to Speak")
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
                                            do {
                                                try speechRecognizer.startLiveRecognition()
                                            } catch {
                                                isRecordingSymptom = false
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        isRecordingSymptom = false
                                        speechRecognizer.stopLiveRecognition()
                                        let text = speechRecognizer.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !text.isEmpty && !record.symptoms.contains(text) {
                                            withAnimation {
                                                record.symptoms.append(text)
                                            }
                                        }
                                    }
                            )

                            if isRecordingSymptom && !speechRecognizer.recognizedText.isEmpty {
                                Text("\(String(localized: "Recognizing")): \(speechRecognizer.recognizedText)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .lineLimit(3)
                                    .padding(.horizontal, 4)
                            }

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

                    // Step 2: Medication
                    PrepStepCard(number: 2, title: String(localized: "Current Medications")) {
                        VStack(spacing: 0) {
                            ForEach(record.medications) { med in
                                MedicationRow(name: med.name, dose: med.dose)
                            }

                            Button(action: { showCamera = true }) {
                                Text("+ \(String(localized: "Scan Pill Box"))")
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

                    // Step 3: Questions
                    PrepStepCard(number: 3, title: String(localized: "Questions for the Doctor")) {
                        VStack(spacing: 0) {
                            ForEach(0..<record.questions.count, id: \.self) { index in
                                QuestionRow(number: index + 1, text: record.questions[index])
                            }

                            Button(action: {}) {
                                HStack {
                                    Image(systemName: isRecordingQuestion ? "waveform" : "mic.fill")
                                    Text(isRecordingQuestion ? "Listening..." : "Hold to Ask Question")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.teal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(isRecordingQuestion ? AppTheme.tealMid.opacity(0.2) : AppTheme.tealLight)
                                .cornerRadius(12)
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if !isRecordingQuestion {
                                            isRecordingQuestion = true
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            do {
                                                try questionRecognizer.startLiveRecognition()
                                            } catch {
                                                isRecordingQuestion = false
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        isRecordingQuestion = false
                                        questionRecognizer.stopLiveRecognition()
                                        let text = questionRecognizer.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !text.isEmpty {
                                            withAnimation {
                                                record.questions.append(text)
                                            }
                                        }
                                    }
                            )

                            if isRecordingQuestion && !questionRecognizer.recognizedText.isEmpty {
                                Text("\(String(localized: "Recognizing")): \(questionRecognizer.recognizedText)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .lineLimit(3)
                                    .padding(.horizontal, 4)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background)

            // Bottom Action
            Button(action: onStartRecording) {
                Text("Ready, Start Visit →")
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
        .onAppear {
            speechRecognizer.requestAuthorization()
            questionRecognizer.requestAuthorization()
        }
    }
}
