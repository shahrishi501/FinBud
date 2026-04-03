import Charts
import SwiftUI

enum SpendingPeriod: String, CaseIterable {
    case weekly  = "Weekly"
    case monthly = "Monthly"
    
    var subtitle: String {
        switch self {
        case .weekly:  return "Last 7 days"
        case .monthly: return "Last 30 days"
        }
    }
}

struct DashboardScreen: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var colorScheme: ColorScheme?
    @State private var spendingPeriod: SpendingPeriod = .weekly

    var body: some View {
        ScreenContainer(title: viewModel.profileName, subtitle: "Current balance overview", colorScheme: $colorScheme) {

            BalanceCard(
                balance:  viewModel.balance,
                income:   viewModel.income,
                expenses: viewModel.expenses,
                monthLabel: viewModel.selectedMonthLabel,
                availableMonths: viewModel.availableMonths,
                onMonthSelected: { month in
                    viewModel.selectedMonth = month
                }
            )

            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("\(spendingPeriod.rawValue) Spending")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        
                        Menu {
                            ForEach(SpendingPeriod.allCases, id: \.self) { period in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        spendingPeriod = period
                                    }
                                } label: {
                                    HStack {
                                        Text(period.rawValue)
                                        if period == spendingPeriod {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(spendingPeriod.subtitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.mutedText)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(AppTheme.mutedText)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(AppTheme.mutedText.opacity(0.25), lineWidth: 1)
                                    )
                            )
                        }
                    }

                    let trendData = spendingPeriod == .weekly
                        ? viewModel.weeklyTrend
                        : viewModel.monthlyTrend

                    Chart(trendData) { point in
                        AreaMark(
                            x: .value("Day", point.label),
                            y: .value("Spend", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.35), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        LineMark(
                            x: .value("Day", point.label),
                            y: .value("Spend", point.value)
                        )
                        .foregroundStyle(AppTheme.accentSoft)
                        .lineStyle(.init(lineWidth: 3, lineCap: .round))
                    }
                    .frame(height: 160)
                    .chartXAxis {
                        AxisMarks(values: trendData.map(\.label)) {
                            AxisValueLabel()
                                .foregroundStyle(AppTheme.mutedText)
                        }
                    }
                    .chartYAxis(.hidden)
                    .animation(.easeInOut(duration: 0.3), value: spendingPeriod)
                }
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Expense Breakdown")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text("\(viewModel.selectedMonthLabel) · by category")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.mutedText)
                        }
                        Spacer()
                        Image(systemName: "chart.pie")
                            .foregroundStyle(AppTheme.accentSoft)
                    }

                    if viewModel.categoryBreakdown.isEmpty {
                        EmptyStateView(
                            title: "No expenses yet",
                            message: "Add some transactions to see your spending by category."
                        )
                    } else {
                        HStack(spacing: 18) {
                            // Donut chart
                            Chart(viewModel.categoryBreakdown) { item in
                                SectorMark(
                                    angle: .value("Amount", item.amount),
                                    innerRadius: .ratio(0.62),
                                    angularInset: 2.5
                                )
                                .foregroundStyle(item.tint)
                            }
                            .frame(width: 130, height: 130)

                            // Legend
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(viewModel.categoryBreakdown.prefix(5)) { bucket in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(bucket.tint)
                                            .frame(width: 8, height: 8)
                                        Text(bucket.title)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.primaryText)
                                        Spacer()
                                        Text(bucket.amount.compactCurrency)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.mutedText)
                                    }
                                }

                                // Show overflow count if > 5 categories
                                if viewModel.categoryBreakdown.count > 5 {
                                    let otherTotal = viewModel.categoryBreakdown.dropFirst(5).reduce(0) { $0 + $1.amount }
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(AppTheme.mutedText.opacity(0.4))
                                            .frame(width: 8, height: 8)
                                        Text("+\(viewModel.categoryBreakdown.count - 5) more")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(AppTheme.mutedText)
                                        Spacer()
                                        Text(otherTotal.compactCurrency)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.mutedText)
                                    }
                                }
                            }
                        }

                        // Total bar at bottom
                        HStack {
                            Text("Total")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(viewModel.categoryBreakdown.reduce(0) { $0 + $1.amount }.inrCurrency)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.negative)
                        }
                        .padding(.top, 4)
                    }
                }
            }

//            GlassCard {
//                VStack(alignment: .leading, spacing: 18) {
//                    HStack {
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("Asset Allocation")
//                                .font(.system(size: 20, weight: .semibold))
//                                .foregroundStyle(AppTheme.primaryText)
//                            Text("Investments stored right inside your portfolio")
//                                .font(.system(size: 13))
//                                .foregroundStyle(AppTheme.mutedText)
//                        }
//                        Spacer()
//                        Image(systemName: "chart.pie")
//                            .foregroundStyle(AppTheme.accentSoft)
//                    }
//
//                    HStack(spacing: 18) {
//                        if viewModel.allocation.isEmpty {
//                            EmptyStateView(
//                                title: "No assets yet",
//                                message: "Your stock, MF, and SIP allocations from onboarding will appear here."
//                            )
//                        } else {
//                            Chart(viewModel.allocation) { item in
//                                SectorMark(
//                                    angle: .value("Amount", item.amount),
//                                    innerRadius: .ratio(0.64),
//                                    angularInset: 3
//                                )
//                                .foregroundStyle(item.tint)
//                            }
//                            .frame(width: 122, height: 122)
//
//                            VStack(alignment: .leading, spacing: 14) {
//                                ForEach(viewModel.allocation) { bucket in
//                                    HStack {
//                                        Circle()
//                                            .fill(bucket.tint)
//                                            .frame(width: 8, height: 8)
//                                        Text(bucket.title)
//                                            .foregroundStyle(AppTheme.primaryText)
//                                        Spacer()
//                                        Text(bucket.amount.compactCurrency)
//                                            .foregroundStyle(AppTheme.mutedText)
//                                    }
//                                    .font(.system(size: 13, weight: .medium))
//                                }
//                            }
//                        }
//                    }
//                }
//            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Goals")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                }
                if viewModel.portfolioCards.isEmpty {
                    EmptyStateView(
                        title: "No goals yet",
                        message: "Head to Goals to create your first savings target."
                    )
                } else {
                    ForEach(viewModel.portfolioCards) { goal in
                        PortfolioCard(goal: goal)
                    }
                }
            }
        }
    }
}

private struct BalanceCard: View {
    let balance: Double
    let income: Double
    let expenses: Double
    let monthLabel: String
    let availableMonths: [Date]
    let onMonthSelected: (Date) -> Void

    @State private var animate = false
    @State private var appear  = false

    var body: some View {
        ZStack(alignment: .bottom) {

            // Card
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(hex: "#130826"))

                // Mesh Gradient Header
                ZStack {
                    Circle()
                        .fill(Color(hex: "#7B2FF7").opacity(0.9))
                        .frame(width: 260)
                        .offset(x: animate ? -80 : -10, y: animate ? -60 : 40)
                        .blur(radius: 60)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)

                    Circle()
                        .fill(Color(hex: "#F107A3").opacity(0.85))
                        .frame(width: 220)
                        .offset(x: animate ? 90 : 0, y: animate ? 30 : -50)
                        .blur(radius: 55)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animate)

                    Circle()
                        .fill(Color(hex: "#FF8C42").opacity(0.8))
                        .frame(width: 200)
                        .offset(x: animate ? 60 : -40, y: animate ? 80 : 0)
                        .blur(radius: 50)
                        .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: animate)

                    Circle()
                        .fill(Color(hex: "#22D3EE").opacity(0.5))
                        .frame(width: 180)
                        .offset(x: animate ? -40 : 70, y: animate ? 60 : -30)
                        .blur(radius: 65)
                        .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)
                }

                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.12), .clear],
                            startPoint: .topLeading, endPoint: .center
                        )
                    )

                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)

                // Content
                VStack(alignment: .leading, spacing: 8) {

                    HStack {
                        Text("CURRENT BALANCE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.68))
                            .tracking(1.8)
                        Spacer()

                        Menu {
                            ForEach(availableMonths, id: \.self) { month in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        onMonthSelected(month)
                                    }
                                } label: {
                                    Text(month.formatted(.dateTime.month(.wide).year()))
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(monthLabel)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.9))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                                    )
                            )
                        }
                    }

                    HStack(alignment: .center, spacing: 6) {
                        Text(balance.inrCurrency)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 10, y: 5)
                    }
                    .scaleEffect(appear ? 1 : 0.85)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appear)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 44)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: Color(hex: "#7B2FF7").opacity(0.5), radius: 30, y: 15)

            // Income + Expense
            HStack(spacing: 14) {
                BalanceChip(
                    icon: "arrow.up",
                    label: "\(monthLabel) Income",
                    value: income.inrCurrency,
                    chipColor: Color(hex: "#34D399")
                )
                BalanceChip(
                    icon: "arrow.down",
                    label: "\(monthLabel) Expenses",
                    value: expenses.inrCurrency,
                    chipColor: Color(hex: "#FB7185")
                )
            }
            .padding(.horizontal, 20)
            .offset(y: 30)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 10)
            .animation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.2), value: appear)
        }
        .padding(.bottom, 30)
        .onAppear {
            appear = true
            animate = true
        }
    }
}

private struct BalanceChip: View {
    let icon:      String
    let label:     String
    let value:     String
    let chipColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(chipColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(0.6)
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(chipColor.opacity(0.13))
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(chipColor.opacity(0.38), lineWidth: 1.2)
            }
        }
        .shadow(color: chipColor.opacity(0.28), radius: 10, y: 4)
    }
}

private struct PortfolioCard: View {
    let goal: Goal

    private var tint: Color { Color(hex: goal.tintHex) }

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 48, height: 48)
                    .overlay(Image(systemName: goal.icon).foregroundStyle(tint))

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(goal.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.mutedText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(goal.currentAmount.inrCurrency)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Target \(goal.targetAmount.compactCurrency)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
        }
    }
}
