import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 个人信息
                Section(header: Text("个人信息")) {
                    TextField("您的姓名", text: $settings.userName)
                        .font(AppTheme.bodyFont)
                }

                // MARK: 适老化设置
                Section(header: Text("适老化设置"), footer: Text("长者模式下字体会变大，并启用语音反馈。")) {
                    Toggle("长者模式", isOn: $settings.isElderMode)
                        .tint(AppTheme.teal)
                        .font(AppTheme.bodyFont)

                    if settings.isElderMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("字号大小：\(String(format: "%.1f", settings.fontScale))x")
                                .font(AppTheme.captionFont)
                            Slider(value: $settings.fontScale, in: 1.0...2.5, step: 0.1)
                                .tint(AppTheme.teal)
                        }
                    }

                    Toggle("高对比度", isOn: $settings.highContrast)
                        .tint(AppTheme.teal)
                        .font(AppTheme.bodyFont)
                }

                // MARK: AI 摘要配置
                Section(
                    header: Text("AI 摘要（可选）"),
                    footer: Text("配置 OpenAI 兼容 API 后，就诊录音会自动生成更精准的结构化摘要。不配置则使用本地分析。")
                ) {
                    TextField("API 地址 (如 https://api.openai.com/v1)", text: $settings.llmBaseURL)
                        .font(AppTheme.captionFont)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("API Key", text: $settings.llmApiKey)
                        .font(AppTheme.captionFont)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("模型名称", text: $settings.llmModel)
                        .font(AppTheme.captionFont)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                // MARK: 订阅
                Section(header: Text("OwlAide Pro")) {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(AppTheme.orange)
                            Text("管理订阅")
                                .font(AppTheme.bodyFont)
                            Spacer()
                            if SubscriptionManager.shared.isPurchased {
                                Text("已解锁")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.teal)
                            }
                        }
                    }
                }

                // MARK: 关于
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.gray)
                    }
                    .font(AppTheme.bodyFont)

                    Text("OwlAide 是一款专注老年人就诊辅助的 App。\n所有数据通过 iCloud 加密同步，不经过第三方服务器。")
                        .font(AppTheme.captionFont)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .font(AppTheme.buttonFont)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
