import SwiftUI
import VisionKit

struct CameraScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    var onDetected: (String, String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        // Create scanner: recognize text, disable symbologies, enable highlighting
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning
        try? uiViewController.startScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: CameraScannerView

        init(parent: CameraScannerView) {
            self.parent = parent
        }

        // Triggered when user taps on a recognized item
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .text(let text):
                // Transcript is the recognized medication name
                // Take the transcript as name and simulate a default dosage
                let detectedName = text.transcript
                parent.onDetected(detectedName, String(localized: "Recognized from photo"))
                parent.dismiss()
            default:
                break
            }
        }

        // Logic for automatic capture
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if let firstItem = addedItems.first {
                switch firstItem {
                case .text(let text):
                    // Basic length check to avoid accidental triggers
                    if text.transcript.count > 3 {
                        DispatchQueue.main.async {
                            self.parent.onDetected(text.transcript, String(localized: "Auto-detected dosage"))
                            self.parent.dismiss()
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
