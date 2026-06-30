import SwiftUI

// --- Base Component Library for Reuse Across Pages ---

// MARK: - Home Components
struct NextVisitCard: View {
    var onPrepare: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEXT VISIT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.teal)
                .tracking(0.5)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "July 3 (Thu) at 9:00 AM")).font(.system(size: 20, weight: .bold))
                Text(String(localized: "General Hospital · Cardiology")).font(.system(size: 14)).foregroundColor(AppTheme.textSub)
            }
            HStack(spacing: 8) {
                Button(action: onPrepare) {
                    Text("Prepare")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.teal)
                        .cornerRadius(10)
                }
                Button(action: {}) {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.teal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.tealLight)
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardWhite)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.tealLight, lineWidth: 1.5))
    }
}

struct QuickCard: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let title: String
    let desc: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(bgColor).frame(width: 36, height: 36)
                    Image(systemName: icon).foregroundColor(iconColor).font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textMain)
                    Text(desc).font(.system(size: 11)).foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppTheme.cardWhite)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "f0f0f0"), lineWidth: 1.5))
        }
    }
}

struct HistoryItem: View {
    let date: String
    let title: String
    let isActive: Bool
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(isActive ? AppTheme.teal : Color.gray.opacity(0.3)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(date).font(.system(size: 12)).foregroundColor(.gray)
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textMain)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 16)).foregroundColor(Color.gray.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.cardWhite)
        .cornerRadius(12)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isActive ? AppTheme.teal : Color.gray.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preparation Components
struct PrepStepCard<Content: View>: View {
    let number: Int
    let title: String
    let content: Content

    init(number: Int, title: String, @ViewBuilder content: () -> Content) {
        self.number = number
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.teal)
                    .cornerRadius(8)
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            content
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
    }
}

struct SymptomChip: View {
    let text: String
    var onDelete: () -> Void
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
            Button(action: onDelete) {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).opacity(0.6)
            }
        }
        .font(.system(size: 13)).foregroundColor(AppTheme.teal)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(AppTheme.tealLight).cornerRadius(20)
    }
}

struct MedicationRow: View {
    let name: String
    let dose: String
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(AppTheme.warmLight).frame(width: 32, height: 32)
                Text("💊").font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 14, weight: .medium))
                Text(dose).font(.system(size: 12)).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .overlay(Divider().opacity(0.2), alignment: .bottom)
    }
}

struct QuestionRow: View {
    let number: Int
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Text("\(number)").font(.system(size: 12, weight: .semibold)).foregroundColor(.gray)
                .frame(width: 22, height: 22).background(Color(hex: "f0f0f0")).cornerRadius(6)
            Text(text).font(.system(size: 14)).foregroundColor(AppTheme.textMain)
            Spacer()
        }
        .padding(.vertical, 8)
        .overlay(Divider().opacity(0.2), alignment: .bottom)
    }
}

// MARK: - Summary Components
struct SummaryCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let title: String
    let content: Content

    init(icon: String, iconColor: Color, bgColor: Color, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.bgColor = bgColor
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(bgColor)
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textMain)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
    }
}

struct SummaryBullet: View {
    let text: String
    let color: Color
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .padding(.top, 7)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "333333"))
                .lineSpacing(4)
        }
    }
}
