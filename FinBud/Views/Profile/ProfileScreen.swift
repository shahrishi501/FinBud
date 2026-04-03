import SwiftUI

struct ProfileScreen: View {
    @ObservedObject var store: FinanceStore
    @ObservedObject var insightsViewModel: InsightsViewModel
    @Binding var colorScheme: ColorScheme?
    @State private var showingLogoutConfirm = false

    var body: some View {
        ScreenContainer(title: "Profile", subtitle: "Your financial identity", colorScheme: $colorScheme) {
            profileCard
            aiInsightCard
            logoutButton
        }
        .confirmationDialog("Log out & erase all data?", isPresented: $showingLogoutConfirm, titleVisibility: .visible) {
            Button("Log Out & Clear Data", role: .destructive) {
                store.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your profile, transactions, goals, and all other data will be permanently deleted.")
        }
    }

    private var profileCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.15))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Text(store.profile?.name.prefix(1).uppercased() ?? "?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.profile?.name ?? "—")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(store.profile?.occupation.title ?? "—")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.mutedText)
                    }
                }

                Rectangle()
                    .fill(AppTheme.stroke)
                    .frame(height: 1)

                VStack(spacing: 14) {
                    profileRow(
                        icon: "calendar",
                        label: "Age",
                        value: store.profile.map { "\($0.age) years old" } ?? "—"
                    )
                    profileRow(
                        icon: "gift",
                        label: "Birthday",
                        value: store.profile?.birthDate.formatted(date: .long, time: .omitted) ?? "—"
                    )
                    profileRow(
                        icon: "indianrupeesign.circle",
                        label: "Net Balance",
                        value: store.balance.inrCurrency
                    )
                    profileRow(
                        icon: "creditcard",
                        label: "Payment Methods",
                        value: store.paymentMethods.isEmpty
                            ? "None"
                            : store.paymentMethods.map(\.title).joined(separator: " · ")
                    )
                    profileRow(
                        icon: "arrow.up.arrow.down",
                        label: "Total Transactions",
                        value: "\(store.transactions.count)"
                    )
                    profileRow(
                        icon: "target",
                        label: "Active Goals",
                        value: "\(store.goals.filter { $0.kind == .savings }.count)"
                    )
                }
            }
        }
    }

    private func profileRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.mutedText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private var aiInsightCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI EXPENSE INSIGHT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.mutedText)
                        Text("Spending Analysis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    Spacer()
                    if insightsViewModel.isGenerating {
                        ProgressView().tint(AppTheme.accent)
                    } else {
                        Text("On-device")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.positive)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(AppTheme.positive.opacity(0.16)))
                    }
                }

                if store.transactions.count < 5 {
                    HStack(spacing: 14) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.accentSoft)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Not enough data yet")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text("Add at least 5 transactions to unlock AI-powered spending insights.")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.mutedText)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    Text(insightsViewModel.aiNarrative)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.primaryText)

                    Button {
                        Task { await insightsViewModel.generateAIInsight() }
                    } label: {
                        Text("REFRESH ANALYSIS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(AppTheme.accent))
                    }
                    .disabled(insightsViewModel.isGenerating)
                }
            }
        }
    }

    private var logoutButton: some View {
        Button {
            showingLogoutConfirm = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Log Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(AppTheme.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.negative.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppTheme.negative.opacity(0.30), lineWidth: 1)
                    )
            )
        }
    }
}
