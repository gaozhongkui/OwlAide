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
                        Text("One-time purchase, lifetime access")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }

                    // Current Status
                    if manager.isPurchased {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("You are a Pro user")
                                .font(AppTheme.bodyFont)
                            Spacer()
                            Text("Unlocked")
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

                    // Feature Comparison
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Pro Exclusive Features")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                            .padding(.bottom, 12)

                        FeatureRow(feature: "🧠 AI Summary", free: "Local Analysis", pro: "Remote GPT-4o", purchased: manager.isPurchased)
                        Divider()
                        FeatureRow(feature: "☁️ iCloud Family Share", free: "Single Device", pro: "Multi-device + Sharing", purchased: manager.isPurchased)
                        Divider()
                        FeatureRow(feature: "🏥 Visit Reminders", free: "Manual", pro: "Automatic Push", purchased: manager.isPurchased)
                        Divider()
                        FeatureRow(feature: "💊 Med Reminders", free: "✅ Free", pro: "✅ Free", purchased: true)
                        Divider()
                        FeatureRow(feature: "🎤 Voice Input", free: "✅ Free", pro: "✅ Free", purchased: true)
                        Divider()
                        FeatureRow(feature: "❤️ HealthKit", free: "✅ Free", pro: "✅ Free", purchased: true)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(14)

                    // Purchase Buttons
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
                                        Text("Unlock Now — \(product.displayPrice)")
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
                                Text("Restore Purchase")
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
                    Button("Close") { dismiss() }
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
