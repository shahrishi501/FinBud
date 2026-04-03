import Charts
import SwiftUI

struct GoalsScreen: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Binding var colorScheme: ColorScheme?

    @State private var showingLogSheet  = false
    @State private var showingAddGoal   = false
    @State private var showingCompoundCalc = true

    var body: some View {
        ScreenContainer(
            title: "Goals",
            subtitle: "\(viewModel.savingsStreak) day saving streak",
            colorScheme: $colorScheme
        ) {
            savingsCommitCard
            investmentCard
            compoundingCalculatorCard
            goalsSection
        }
        .sheet(isPresented: $showingLogSheet) {
            LogSavingSheet(goals: viewModel.activeGoals) { amount, ids in
                viewModel.logSaving(amount: amount, goalIDs: ids)
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet { title, target in
                viewModel.addGoal(title: title, targetAmount: target)
            }
        }
    }

    private var savingsCommitCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                    Text("\(viewModel.savingsStreak) DAY SAVING STREAK")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.positive)
                }

                Text("Your Path to Financial Freedom")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("Every rupee you commit today compounds into tomorrow's freedom.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.secondaryText)

                // Commit grid
                CommitGridView(log: viewModel.savingsLog, days: 90)

                // Legend
                HStack {
                    Text("Less")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.mutedText)
                    ForEach([0.08, 0.25, 0.55, 0.85, 1.0], id: \.self) { opacity in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green.opacity(opacity))
                            .frame(width: 12, height: 12)
                    }
                    Text("More")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.mutedText)
                }

                Button {
                    showingLogSheet = true
                } label: {
                    Text("LOG TODAY'S SAVING")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.accent)
                        )
                }
            }
        }
    }

    private var investmentCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.investmentSplit.isEmpty {
                    Text("YOUR INVESTMENTS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.mutedText)

                    ForEach(viewModel.investmentSplit) { item in
                        HStack {
                            Circle()
                                .fill(item.tint.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: item.icon)
                                        .font(.system(size: 13))
                                        .foregroundStyle(item.tint)
                                )
                            Text(item.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(item.amount.inrCurrency)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }
                } else {
                    Text("No investments added yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
        }
    }

    // Compunding Calculator
    private var compoundingCalculatorCard: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showingCompoundCalc.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.green.opacity(0.18))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.green)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Compounding Calculator")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text("See your SIP/MF grow over time")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.mutedText)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.mutedText)
                            .rotationEffect(.degrees(showingCompoundCalc ? 180 : 0))
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)

                if showingCompoundCalc {
                    Divider().background(AppTheme.mutedText.opacity(0.15))
                    CompoundingCalculatorView()
                        .padding(16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingCompoundCalc)
    }

    @ViewBuilder
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Goals")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Button {
                    showingAddGoal = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New goal")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }

            if viewModel.activeGoals.isEmpty {
                GlassCard {
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.mutedText)
                        Text("No goals yet")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text("Tap \"New goal\" to create one — a PS5, a trip, anything.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.mutedText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                ForEach(viewModel.activeGoals) { goal in
                    GoalCard(goal: goal, onDelete: {
                        viewModel.deleteGoal(id: goal.id)
                    })
                }
            }
        }
    }
}

struct CommitGridView: View {
    let log: [Int: Double]
    let days: Int

    private let columns = 18
    private var rows: Int { Int(ceil(Double(days) / Double(columns))) }
    private func cellColor(for daysAgo: Int) -> Color {
        let amt = log[daysAgo] ?? 0
        guard amt > 0 else { return Color.primary.opacity(0.07) }
        switch amt {
        case ..<500:   return Color.green.opacity(0.30)
        case ..<2000:  return Color.green.opacity(0.55)
        case ..<5000:  return Color.green.opacity(0.80)
        default:       return Color.green
        }
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: columns),
            spacing: 3
        ) {
            ForEach((0..<days).reversed(), id: \.self) { daysAgo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(cellColor(for: daysAgo))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        daysAgo == 0 ?
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(AppTheme.primaryText.opacity(0.5), lineWidth: 1)
                        : nil
                    )
            }
        }
    }
}

private struct GoalCard: View {
    let goal: Goal
    let onDelete: () -> Void

    private var progress: Double {
        max(0, min(1, goal.currentAmount / max(goal.targetAmount, 1)))
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: goal.tintHex).opacity(0.18))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: goal.icon)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(hex: goal.tintHex))
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text("\(Int(progress * 100))% of \(goal.targetAmount.inrCurrency)")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.mutedText)
                        }
                    }
                    Spacer()
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.mutedText)
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.07))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: goal.tintHex))
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(goal.currentAmount.inrCurrency)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("Target \(goal.targetAmount.inrCurrency)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.mutedText)
                }

                if !goal.commitLog.isEmpty {
                    Text("COMMIT HISTORY")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.mutedText)

                    CommitGridView(log: goal.commitLog, days: 30)
                }
            }
        }
    }
}

struct LogSavingSheet: View {
    let goals: [Goal]
    let onSave: (Double, [UUID]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var selectedGoalIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("How much did you save today?") {
                    HStack {
                        Text("₹")
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }

                if !goals.isEmpty {
                    Section("Apply toward goals (optional)") {
                        ForEach(goals) { goal in
                            Toggle(isOn: Binding(
                                get: { selectedGoalIDs.contains(goal.id) },
                                set: { on in
                                    if on { selectedGoalIDs.insert(goal.id) }
                                    else  { selectedGoalIDs.remove(goal.id) }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(goal.title)
                                        .font(.system(size: 15))
                                    Text("\(goal.currentAmount.inrCurrency) of \(goal.targetAmount.inrCurrency)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.mutedText)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log saving")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Commit") {
                        guard let amount = Double(amountText), amount > 0 else { return }
                        onSave(amount, Array(selectedGoalIDs))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled((Double(amountText) ?? 0) <= 0)
                }
            }
        }
    }
}

struct AddGoalSheet: View {
    let onSave: (String, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var targetText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name (e.g. PS5, Europe trip)", text: $title)
                }
                Section("Target amount") {
                    HStack {
                        Text("₹")
                        TextField("e.g. 40000", text: $targetText)
                            .keyboardType(.decimalPad)
                    }
                }
                Section {
                    Text("Once created, log your daily savings and optionally apply them toward this goal. The progress bar and commit grid update automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        guard let target = Double(targetText), target > 0,
                              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        onSave(title.trimmingCharacters(in: .whitespacesAndNewlines), target)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Double(targetText) ?? 0) <= 0)
                }
            }
        }
    }
}

private struct CompoundPoint: Identifiable {
    let id = UUID()
    let year: Int
    let invested: Double
    let compounded: Double
}

private struct CompoundingCalculatorView: View {
    @State private var monthlyAmount: Double = 5000
    @State private var annualRate: Double = 12
    @State private var years: Double = 10
    @State private var currentAge: Double = 25

    private var dataPoints: [CompoundPoint] {
        var points: [CompoundPoint] = []
        var compounded = 0.0
        let monthlyRate = annualRate / 100 / 12
        let totalYears = Int(years)
        for year in 0...totalYears {
            let months = Double(year * 12)
            let invested = monthlyAmount * months
            if monthlyRate == 0 {
                compounded = invested
            } else {
                compounded = monthlyAmount * ((pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate)
            }
            points.append(CompoundPoint(year: year, invested: invested, compounded: max(compounded, 0)))
        }
        return points
    }

    private var finalInvested: Double   { dataPoints.last?.invested ?? 0 }
    private var finalCompounded: Double { dataPoints.last?.compounded ?? 0 }
    private var wealthGained: Double    { finalCompounded - finalInvested }
    private var retirementAge: Int      { Int(currentAge) + Int(years) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 0) {
                summaryBlock(label: "You invest",    value: finalInvested.compactCurrency,   color: AppTheme.mutedText)
                Divider().frame(height: 40)
                summaryBlock(label: "Grows to",      value: finalCompounded.compactCurrency, color: .green)
                Divider().frame(height: 40)
                summaryBlock(label: "Wealth gained", value: wealthGained.compactCurrency,    color: AppTheme.accent)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.elevatedCard))

            Text("At age \(retirementAge), you could have \(finalCompounded.compactCurrency) — \(String(format: "%.1f", finalCompounded / max(finalInvested, 1)))x your money.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)

            Chart(dataPoints) { point in
                AreaMark(x: .value("Year", point.year), y: .value("Compounded", point.compounded))
                    .foregroundStyle(LinearGradient(colors: [Color.green.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Year", point.year), y: .value("Compounded", point.compounded))
                    .foregroundStyle(Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .symbol {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                LineMark(x: .value("Year", point.year), y: .value("Invested", point.invested))
                    .foregroundStyle(AppTheme.accent.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
            .frame(height: 200)
            .chartXAxis {
                // Milestone marks at 5-year intervals, plus year 0
                AxisMarks(values: Array(stride(from: 0, through: Int(years), by: Int(years) <= 10 ? 5 : 10))) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(AppTheme.mutedText.opacity(0.3))
                    AxisTick()
                    AxisValueLabel {
                        if let yr = value.as(Int.self) {
                            Text("yr \(yr)")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.mutedText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(AppTheme.mutedText.opacity(0.2))
                    AxisValueLabel {
                        if let amt = value.as(Double.self) {
                            Text(amt.compactCurrency)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.mutedText)
                        }
                    }
                }
            }
            .chartLegend(.hidden)
            .animation(.easeInOut(duration: 0.35), value: monthlyAmount)
            .animation(.easeInOut(duration: 0.35), value: annualRate)
            .animation(.easeInOut(duration: 0.35), value: years)

            HStack(spacing: 16) {
                legendDot(color: .green, label: "Compounded value")
                legendDot(color: AppTheme.accent.opacity(0.6), label: "Amount invested", dashed: true)
            }
            .font(.system(size: 12))

            VStack(spacing: 16) {
                sliderRow(label: "Monthly SIP",   value: $monthlyAmount, range: 500...100000, step: 500,  display: "₹\(Int(monthlyAmount).formatted())")
                sliderRow(label: "Annual Return", value: $annualRate,    range: 1...30,       step: 0.5,  display: "\(String(format: "%.1f", annualRate))%")
                sliderRow(label: "Duration",      value: $years,         range: 1...40,       step: 1,    display: "\(Int(years)) yrs")
                sliderRow(label: "Current Age",   value: $currentAge,    range: 18...55,      step: 1,    display: "\(Int(currentAge)) yrs")
            }
        }
    }

    private func summaryBlock(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 11)).foregroundStyle(AppTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
    }

    private func legendDot(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 6) {
            if dashed {
                Rectangle().fill(color).frame(width: 16, height: 1.5)
            } else {
                Circle().fill(color).frame(width: 8, height: 8)
            }
            Text(label).foregroundStyle(AppTheme.mutedText)
        }
    }

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, display: String) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Text(display).font(.system(size: 13, weight: .bold)).foregroundStyle(AppTheme.primaryText).monospacedDigit()
            }
            Slider(value: value, in: range, step: step).tint(AppTheme.accent)
        }
    }
}
