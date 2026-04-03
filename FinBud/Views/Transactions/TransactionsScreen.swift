import SwiftUI

struct TransactionsScreen: View {
    @ObservedObject var viewModel: TransactionsViewModel
    @Binding var colorScheme: ColorScheme?
    @State private var showingForm = false
    @State private var selectedTransactions: Set<UUID> = []
    @State private var isSelectionMode = false

    var body: some View {
        ScreenContainer(
            title: "Transactions",
            subtitle: "Track every money move",
            colorScheme: $colorScheme
        ) {
            searchBar

            filtersSection

            if isSelectionMode {
                actionBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            transactionListSection
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelectionMode)
        .onAppear { viewModel.reload() }
        .sheet(isPresented: $showingForm) {
            TransactionEntrySheet(
                existingTransaction: viewModel.selectedTransaction
            ) { transaction in
                if viewModel.selectedTransaction == nil {
                    viewModel.add(transaction: transaction)
                } else {
                    viewModel.update(transaction: transaction)
                }
                viewModel.selectedTransaction = nil
                viewModel.reload()
                exitSelectionMode()
            }
            .presentationDetents([.large])
        }
    }

    private func exitSelectionMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isSelectionMode = false
            selectedTransactions.removeAll()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.mutedText)

            TextField("Search merchant, note…", text: $viewModel.searchText)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.primaryText)

            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.elevatedCard)
        )
    }

    private var filtersSection: some View {
        VStack(spacing: 8) {

            // Row 1: Period filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionsViewModel.Filter.allCases) { filter in
                        ChipButton(
                            title: filter.title,
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedFilter = filter
                            }
                        }
                    }
                }
            }

            // Row 2: Type + Account mixed
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Type chips
                    ChipButton(
                        title: "All Types",
                        icon: "arrow.up.arrow.down",
                        isSelected: viewModel.selectedType == nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedType = nil
                            viewModel.reload()
                        }
                    }

                    ForEach(TransactionType.allCases) { type in
                        ChipButton(
                            title: type.title,
                            icon: type == .income ? "arrow.up" : "arrow.down",
                            isSelected: viewModel.selectedType == type,
                            selectedTint: type.tint
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedType = (viewModel.selectedType == type) ? nil : type
                                viewModel.reload()
                            }
                        }
                    }

                    // Divider dot
                    Circle()
                        .fill(AppTheme.mutedText.opacity(0.3))
                        .frame(width: 4, height: 4)

                    // Account type chips
                    ForEach(MoneyAccountType.allCases) { method in
                        ChipButton(
                            title: method.title,
                            icon: method.icon,
                            isSelected: viewModel.selectedAccountType == method,
                            selectedTint: AppTheme.accent
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedAccountType =
                                    (viewModel.selectedAccountType == method) ? nil : method
                                viewModel.reload()
                            }
                        }
                    }
                }
            }

        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Text("\(selectedTransactions.count) selected")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.mutedText)

            Spacer()

            Button {
                guard selectedTransactions.count == 1,
                      let id = selectedTransactions.first,
                      let tx = viewModel.store.transactions.first(where: { $0.id == id })
                else { return }
                viewModel.selectedTransaction = tx
                showingForm = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "pencil")
                    Text("Edit")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selectedTransactions.count == 1 ? AppTheme.accent : AppTheme.mutedText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(AppTheme.elevatedCard))
            }
            .disabled(selectedTransactions.count != 1)

            Button {
                selectedTransactions.forEach { viewModel.store.delete(transactionID: $0) }
                viewModel.reload()
                withAnimation { exitSelectionMode() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selectedTransactions.isEmpty ? AppTheme.mutedText : AppTheme.negative)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(AppTheme.elevatedCard))
            }
            .disabled(selectedTransactions.isEmpty)

            Button { exitSelectionMode() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.mutedText)
                    .padding(8)
                    .background(Circle().fill(AppTheme.elevatedCard))
            }
        }
    }

    private var transactionListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.groupedTransactions.isEmpty {
                EmptyStateView(
                    title: "No transactions found",
                    message: "Try adjusting your filters or add a new transaction."
                )
            } else {
                if !isSelectionMode {
                    HStack {
                        Spacer()
                        Label("Long press to select", systemImage: "hand.tap")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.mutedText)
                    }
                }

                ForEach(viewModel.groupedTransactions, id: \.0) { sectionTitle, transactions in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(sectionTitle.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.mutedText)
                            .tracking(1)

                        ForEach(transactions) { transaction in
                            TransactionRow(
                                transaction: transaction,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedTransactions.contains(transaction.id)
                            )
                            .onTapGesture {
                                guard isSelectionMode else { return }
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if selectedTransactions.contains(transaction.id) {
                                        selectedTransactions.remove(transaction.id)
                                    } else {
                                        selectedTransactions.insert(transaction.id)
                                    }
                                }
                            }
                            .onLongPressGesture(minimumDuration: 0.4) {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isSelectionMode = true
                                    selectedTransactions.insert(transaction.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct ChipButton: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var selectedTint: Color = AppTheme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.mutedText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? selectedTint : AppTheme.elevatedCard)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TransactionRow: View {
    let transaction: Transaction
    var isSelectionMode: Bool = false
    var isSelected: Bool = false

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.mutedText)
                        .transition(.scale.combined(with: .opacity))
                }

                Circle()
                    .fill(transaction.category.color.opacity(0.16))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: transaction.category.icon)
                            .font(.system(size: 15))
                            .foregroundStyle(transaction.category.color)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(transaction.merchant)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        AccountTypePill(type: transaction.accountType)
                    }
                    Text("\(transaction.category.title) • \(transaction.note)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.mutedText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 3) {
                        Image(systemName: transaction.type == .expense ? "arrow.down" : "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                        Text(transaction.amount.inrCurrency)
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(transaction.type.tint)

                    Text(transaction.date.formatted(.dayHeader))
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? AppTheme.accent : .clear, lineWidth: 1.5)
        )
    }
}
