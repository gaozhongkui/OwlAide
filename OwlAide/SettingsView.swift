import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Personal Info
                Section(header: Text("Personal Information")) {
                    TextField(String(localized: "Your Name"), text: $settings.userName)
                        .font(AppTheme.bodyFont)
                }

                // MARK: Accessibility
                Section(header: Text("Accessibility"), footer: Text("Elder Mode increases font size and enables voice feedback.")) {
                    Toggle("Elder Mode", isOn: $settings.isElderMode)
                        .tint(AppTheme.teal)
                        .font(AppTheme.bodyFont)

                    if settings.isElderMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(String(localized: "Font Scale")): \(String(format: "%.1f", settings.fontScale))x")
                                .font(AppTheme.captionFont)
                            Slider(value: $settings.fontScale, in: 1.0...2.5, step: 0.1)
                                .tint(AppTheme.teal)
                        }
                    }

                    Toggle("High Contrast", isOn: $settings.highContrast)
                        .tint(AppTheme.teal)
                        .font(AppTheme.bodyFont)
                }

                // MARK: AI Summary Config
                Section(
                    header: Text("AI Summary (Optional)"),
                    footer: Text("Configure an OpenAI-compatible API for more accurate visit summaries. Local analysis is used otherwise.")
                ) {
                    TextField(String(localized: "API Base URL (e.g., https://api.openai.com/v1)"), text: $settings.llmBaseURL)
                        .font(AppTheme.captionFont)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField(String(localized: "API Key"), text: $settings.llmApiKey)
                        .font(AppTheme.captionFont)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField(String(localized: "Model Name"), text: $settings.llmModel)
                        .font(AppTheme.captionFont)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                // MARK: Subscription
                Section(header: Text("OwlAide Pro")) {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(AppTheme.orange)
                            Text("Manage Subscription")
                                .font(AppTheme.bodyFont)
                            Spacer()
                            if SubscriptionManager.shared.isPurchased {
                                Text("Unlocked")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.teal)
                            }
                        }
                    }
                }

                // MARK: About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.gray)
                    }
                    .font(AppTheme.bodyFont)

                    Text("OwlAide is an assistant app for senior healthcare visits.\nAll data is encrypted and synced via iCloud; no third-party servers involved.")
                        .font(AppTheme.captionFont)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.buttonFont)
                }
            }
        }
    }
}
