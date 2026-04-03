import Combine
import Foundation

final class TransactionsViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case day
        case week
        case month

        var id: String { rawValue }
        var title: String {
            switch self {
            case .all:   return "All"
            case .day:   return "Daily"
            case .week:  return "Weekly"
            case .month: return "Monthly"
            }
        }
    }

    @Published var searchText = ""
    @Published var selectedFilter: Filter = .all
    @Published var selectedType: TransactionType?
    @Published var selectedCategory: FinanceCategory?
    @Published var selectedAccountType: MoneyAccountType?
    @Published var selectedTransaction: Transaction?
    @Published private(set) var visibleTransactions: [Transaction] = []

    let store: FinanceStore
    private var cancellables = Set<AnyCancellable>()

    init(store: FinanceStore) {
        self.store = store
        bind()
        reload()
    }

    var groupedTransactions: [(String, [Transaction])] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: visibleTransactions) { item -> String in
            switch selectedFilter {
            case .all:
                // Group by individual date
                return item.date.formatted(.long)
            case .day:
                // Today only
                if calendar.isDateInToday(item.date) {
                    return "Today"
                } else if calendar.isDateInYesterday(item.date) {
                    return "Yesterday"
                } else {
                    return item.date.formatted(.long)
                }
            case .week:
                // Group by week
                let weekOfYear = calendar.component(.weekOfYear, from: item.date)
                let year = calendar.component(.yearForWeekOfYear, from: item.date)
                let currentWeek = calendar.component(.weekOfYear, from: .now)
                let currentYear = calendar.component(.yearForWeekOfYear, from: .now)

                if weekOfYear == currentWeek && year == currentYear {
                    return "This Week"
                } else if weekOfYear == currentWeek - 1 && year == currentYear {
                    return "Last Week"
                } else {
                    // Show the Monday of that week
                    let comps = DateComponents(weekOfYear: weekOfYear, yearForWeekOfYear: year)
                    if let weekStart = calendar.date(from: comps) {
                        return "Week of \(weekStart.formatted(.dateTime.month(.abbreviated).day()))"
                    }
                    return "Week \(weekOfYear)"
                }
            case .month:
                // Group by month
                let month = calendar.component(.month, from: item.date)
                let year = calendar.component(.year, from: item.date)
                let currentMonth = calendar.component(.month, from: .now)
                let currentYear = calendar.component(.year, from: .now)

                if month == currentMonth && year == currentYear {
                    return "This Month"
                } else {
                    return item.date.formatted(.dateTime.month(.wide).year())
                }
            }
        }

        return grouped
            .map { key, value in (key, value.sorted { $0.date > $1.date }) }
            .sorted { lhs, rhs in
                guard let l = lhs.1.first?.date, let r = rhs.1.first?.date else { return false }
                return l > r
            }
    }

    func add(transaction: Transaction) {
        store.add(transaction: transaction)
    }

    func update(transaction: Transaction) {
        store.update(transaction: transaction)
    }

    func delete(at offsets: IndexSet, in transactions: [Transaction]) {
        offsets.compactMap { transactions[safe: $0] }.forEach { store.delete(transactionID: $0.id) }
    }

    private func bind() {
        // Group all filter publishers together
        let filters = Publishers.CombineLatest4(
            $searchText,
            $selectedFilter,
            $selectedType,
            $selectedCategory
        )

        store.$transactions
            .combineLatest(filters, $selectedAccountType)
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    func reload() {
        visibleTransactions = store.transactions.filter { transaction in
            // Search
            let matchesSearch = searchText.isEmpty ||
                transaction.note.localizedCaseInsensitiveContains(searchText) ||
                transaction.merchant.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.accountType.title.localizedCaseInsensitiveContains(searchText)

            // Type
            let matchesType = selectedType == nil || transaction.type == selectedType

            // Category
            let matchesCategory = selectedCategory == nil || transaction.category == selectedCategory

            // Account type
            let matchesAccountType = selectedAccountType == nil || transaction.accountType == selectedAccountType

            // No date filtering — filters only change grouping
            return matchesSearch && matchesType && matchesCategory && matchesAccountType
        }
        .sorted { $0.date > $1.date }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
