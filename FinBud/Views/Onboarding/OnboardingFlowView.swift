import SwiftUI

struct OnboardingFlowView: View {
    @ObservedObject var store: FinanceStore
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var skippedGoals = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 22) {
                            Text(viewModel.currentStep.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(viewModel.currentStep.subtitle)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.mutedText)

                            switch viewModel.currentStep {
                            case .profile:
                                profileStep
                            case .moneySetup:
                                moneySetupStep
                            case .goals:
                                goalsStep
                            case .starterTransactions:
                                starterTransactionsStep
                            }
                        }
                    }

                    controls
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .dismissKeyboardOnTap()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Welcome to FinBud")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 999)
                    .fill(AppTheme.elevatedCard)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999)
                            .fill(AppTheme.accent)
                            .frame(width: max(36, proxy.size.width * viewModel.progress))
                    }
            }
            .frame(height: 10)

            Text("Step \(viewModel.currentStep.rawValue + 1) of \(OnboardingViewModel.Step.allCases.count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.mutedText)
        }
    }

    private var profileStep: some View {
        VStack(spacing: 14) {
            OnboardingField(title: "Name", text: $viewModel.fullName, placeholder: "Enter your name")
            OnboardingField(title: "Age", text: $viewModel.ageText, placeholder: "Enter Age", keyboardType: .numberPad)

            VStack(alignment: .leading, spacing: 8) {
                Text("Date of birth")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedText)
                HStack {
                    Text(viewModel.birthDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    DatePicker("", selection: $viewModel.birthDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .blendMode(.normal)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.elevatedCard)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What describes you best?")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedText)
                HStack {
                    Text(viewModel.occupation.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Picker("Occupation", selection: $viewModel.occupation) {
                        ForEach(OccupationType.allCases) { occupation in
                            Text(occupation.title).tag(occupation)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.elevatedCard)
                )
            }
        }
    }

    private var moneySetupStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Which money types do you use?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedText)

                HStack(spacing: 10) {
                    ForEach(MoneyAccountType.allCases) { method in
                        Button {
                            viewModel.togglePaymentMethod(method)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: method.icon)
                                Text(method.title)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(viewModel.selectedPaymentMethods.contains(method) ? Color.white : AppTheme.mutedText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(viewModel.selectedPaymentMethods.contains(method) ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.elevatedCard))
                            )
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Preferred currency")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedText)
                Picker("Currency", selection: $viewModel.currencyCode) {
                    Text("INR (₹)").tag("INR")
                    Text("USD ($)").tag("USD")
                    Text("EUR (€)").tag("EUR")
                    Text("GBP (£)").tag("GBP")
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("How much is already blocked in assets?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedText)

                OnboardingField(title: "Stocks", text: $viewModel.stocksText, placeholder: "10000", keyboardType: .numberPad)
                OnboardingField(title: "Mutual Funds", text: $viewModel.mutualFundsText, placeholder: "5000", keyboardType: .numberPad)
                OnboardingField(title: "SIP", text: $viewModel.sipText, placeholder: "3000", keyboardType: .numberPad)

                Text("These will be tracked as asset allocation, not expenses.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Adding goals is optional. We can suggest ideas, or you can skip and add them anytime from the Goals tab.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.mutedText)

            ForEach(Array(viewModel.goalEntries.enumerated()), id: \.offset) { index, _ in
                OnboardingField(
                    title: "Goal \(index + 1)",
                    text: Binding(
                        get: { viewModel.goalEntries[index] },
                        set: { viewModel.goalEntries[index] = $0 }
                    ),
                    placeholder: index == 0 ? "Travel" : "PS5"
                )
            }

            Button {
                skippedGoals = true
                viewModel.next()
            } label: {
                Text("Skip goals for now")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.elevatedCard)
                    )
            }
        }
    }

    private var starterTransactionsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add transactions from \(viewModel.monthStart.formatted(.dayHeader)) to today.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.mutedText)

            ForEach($viewModel.starterTransactions) { $transaction in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Merchant", text: $transaction.merchant)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.elevatedCard))
                            .foregroundStyle(AppTheme.primaryText)

                        Button {
                            viewModel.removeStarterTransaction(id: transaction.id)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(AppTheme.negative)
                        }
                    }

                    HStack(spacing: 12) {
                        TextField("Amount", text: $transaction.amountText)
                            .keyboardType(.numberPad)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.elevatedCard))
                            .foregroundStyle(AppTheme.primaryText)

                        Picker("Type", selection: $transaction.type) {
                            ForEach(TransactionType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Picker("Category", selection: $transaction.category) {
                        ForEach(FinanceCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Money Type", selection: $transaction.accountType) {
                        ForEach(MoneyAccountType.allCases) { account in
                            Text(account.title).tag(account)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker(
                        "Date",
                        selection: $transaction.date,
                        in: viewModel.monthStart...Date(),
                        displayedComponents: .date
                    )

                    TextField("Notes", text: $transaction.note)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.elevatedCard))
                        .foregroundStyle(AppTheme.primaryText)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppTheme.card)
                )
            }

            Button {
                viewModel.addStarterTransaction()
            } label: {
                Label("Add another transaction", systemImage: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private var controls: some View {
        HStack {
            if viewModel.currentStep != .profile {
                Button {
                    viewModel.previous()
                } label: {
                    Text("Back")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.elevatedCard)
                        )
                }
            }

            Spacer()

            Button {
                if viewModel.currentStep == .starterTransactions {
                    store.completeOnboarding(
                        profile: viewModel.builtProfile,
                        paymentMethods: Array(viewModel.selectedPaymentMethods),
                        holdings: viewModel.builtHoldings,
                        goalTitles: skippedGoals ? [] : viewModel.goalEntries,
                        starterTransactions: viewModel.validatedTransactions,
                        currencyCode: viewModel.currencyCode
                    )
                } else {
                    if viewModel.currentStep == .goals {
                        skippedGoals = false
                    }
                    viewModel.next()
                }
            } label: {
                Text(viewModel.currentStep == .starterTransactions ? "Finish Setup" : "Continue")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(viewModel.canMoveForward ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.elevatedCard))
                    )
            }
            .disabled(!(viewModel.canMoveForward || viewModel.currentStep == .goals))
        }
    }
}

private struct OnboardingField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.mutedText)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.elevatedCard)
                )
                .foregroundStyle(AppTheme.primaryText)
        }
    }
}
