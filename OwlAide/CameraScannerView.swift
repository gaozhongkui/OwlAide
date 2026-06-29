import SwiftUI
import VisionKit

struct CameraScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    var onDetected: (String, String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        // 创建扫描器：识别文字，禁用意标，允许高光显示识别区域
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
        // 启动扫描
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

        // 当扫描器点击识别出的文字项时触发（或者自动捕获）
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .text(let text):
                // 这里的文本就是识别出的药名
                // 我们简单地取第一行作为药名，并模拟一个默认剂量
                let detectedName = text.transcript
                parent.onDetected(detectedName, "识别自药盒照片")
                parent.dismiss()
            default:
                break
            }
        }

        // 如果你想实现“自动捕获”而不是点击捕获，可以使用 didAdd 并在里面逻辑判断
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if let firstItem = addedItems.first {
                switch firstItem {
                case .text(let text):
                    // 为了防止误触，这里通常会加一些逻辑判断（比如文字长度或关键词）
                    // 在此我们直接返回识别到的第一个长文字
                    if text.transcript.count > 3 {
                        DispatchQueue.main.async {
                            self.parent.onDetected(text.transcript, "自动识别剂量")
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
