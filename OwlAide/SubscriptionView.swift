import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var manager = SubscriptionManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.orange)
                            .padding(.top, 20)
                        Text("OwlAide Pro")
                            .font(AppTheme.titleFont)
                        Text("一次购买，永久使用")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }

                    // 当前状态
                    if manager.isPurchased {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("您已是 Pro 用户")
                                .font(AppTheme.bodyFont)
                            Spacer()
                            Text("已解锁")
                                .font(AppTheme.captionFont)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(AppTheme.tealLight)
                                .foregroundColor(AppTheme.teal)
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                    }

                    // 功能对比
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Pro 专属功能")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                            .padding(.bottom, 12)

                        FeatureRow(feature: "🧠 AI 摘要", free: "本地分析", pro: "远程 GPT-4o", purchased: manager.isPurchased)
                        Divider()
                        FeatureRow(feature: "☁️ iCloud 家庭分享", free: "单设备", pro: "多设备 + 家人共享", purchased: manager.isPurchased)
                        Divider()
                        FeatureRow(feature: "🏥 复诊推送通知", free: "手动查看", pro: "自动提醒", purchased: manager.isPurchased)
                        Divider()
                        FeatureRow(feature: "💊 用药提醒", free: "✅ 免费", pro: "✅ 免费", purchased: true)
                        Divider()
                        FeatureRow(feature: "🎤 语音输入", free: "✅ 免费", pro: "✅ 免费", purchased: true)
                        Divider()
                        FeatureRow(feature: "❤️ HealthKit", free: "✅ 免费", pro: "✅ 免费", purchased: true)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(14)

                    // 购买按钮
                    if !manager.isPurchased {
                        VStack(spacing: 12) {
                            if manager.isLoading {
                                ProgressView()
                            }

                            if let product = manager.product {
                                Button(action: {
                                    Task { await manager.purchase() }
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("立即解锁 — \(product.displayPrice)")
                                            .font(AppTheme.buttonFont)
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .background(AppTheme.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                }
                            } else {
                                ProgressView()
                            }

                            if let error = manager.purchaseError {
                                Text(error)
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(.red)
                            }

                            Button(action: {
                                Task { await manager.restorePurchases() }
                            }) {
                                Text("恢复购买")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                await manager.loadProducts()
                await manager.checkPurchaseStatus()
            }
        }
    }
}

struct FeatureRow: View {
    let feature: String
    let free: String
    let pro: String
    let purchased: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(feature)
                .font(AppTheme.bodyFont)
                .frame(width: 140, alignment: .leading)
            Spacer()
            if purchased {
                Text(free)
                    .font(AppTheme.captionFont)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            } else {
                Text(pro)
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.orangeLight)
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    SubscriptionView()
}
