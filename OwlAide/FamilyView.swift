import SwiftUI

struct FamilyView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("家庭分享")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)

            ScrollView {
                VStack(spacing: 20) {
                    // 子女卡片
                    HStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.teal)

                        VStack(alignment: .leading) {
                            Text("大儿子").font(.system(size: 18, weight: .bold))
                            Text("已同步您的最近 3 条就诊记录").font(.system(size: 13)).foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "phone.fill")
                            .foregroundColor(AppTheme.teal)
                            .padding(10)
                            .background(AppTheme.tealLight)
                            .clipShape(Circle())
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)

                    Button(action: {}) {
                        Text("+ 邀请家人")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.teal)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.tealLight)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .background(AppTheme.background)
    }
}
