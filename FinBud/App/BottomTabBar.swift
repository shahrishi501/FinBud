import SwiftUI

enum AppTab: String, CaseIterable {
    case home
    case transactions
    case goals
    case profile

    var title: String {
        switch self {
        case .home: "Home"
        case .transactions: "Ledger"
        case .goals: "Goals"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .transactions: "list.bullet.rectangle.portrait"
        case .goals: "target"
        case .profile: "person.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: "house.fill"
        case .transactions: "list.bullet.rectangle.portrait.fill"
        case .goals: "target"
        case .profile: "person.circle.fill"
        }
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: AppTab
    let onAddTransaction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                                .font(.system(size: 20, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(selectedTab == tab ? AppTheme.accent : AppTheme.mutedText)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(AppTheme.stroke, lineWidth: 1)
                    )
            )

            Button(action: onAddTransaction) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(AppTheme.accent))
                    .overlay(Circle().stroke(AppTheme.stroke, lineWidth: 1))
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, y: 6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
