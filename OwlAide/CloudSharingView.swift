import SwiftUI
import CloudKit

/// UICloudSharingController 的 SwiftUI 包装
/// 用于弹出系统原生分享界面，选择 iCloud 联系人共享就诊报告
struct CloudSharingView: UIViewControllerRepresentable {
    let container: CKContainer
    let share: CKShare
    var onDismiss: () -> Void = {}

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController { [share, container] _, preparationHandler in
            preparationHandler(share, container, nil)
        }
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadOnly]
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onDismiss: () -> Void
        init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            onDismiss()
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onDismiss()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onDismiss()
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "就诊报告"
        }
    }
}
