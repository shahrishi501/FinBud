import SwiftUI

struct ContentView: View {
    @ObservedObject private var store: FinanceStore
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var transactionsViewModel: TransactionsViewModel
    @StateObject private var goalsViewModel: GoalsViewModel
    @StateObject private var insightsViewModel: InsightsViewModel
    @State private var selectedTab: AppTab = .home
    /// 0 = follow system (default on first launch), 1 = light, 2 = dark
    @AppStorage("userColorScheme") private var savedScheme: Int = 0
    @State private var showingQuickAdd = false

    private var appColorScheme: ColorScheme? {
        switch savedScheme {
        case 1: return .light
        case 2: return .dark
        default: return nil   // follows system
        }
    }

    private var colorSchemeBinding: Binding<ColorScheme?> {
        Binding(
            get: { appColorScheme },
            set: { newScheme in
                switch newScheme {
                case .light:  savedScheme = 1
                case .dark:   savedScheme = 2
                default:      savedScheme = 0
                }
            }
        )
    }

    init(store: FinanceStore) {
        self.store = store
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(store: store))
        _transactionsViewModel = StateObject(wrappedValue: TransactionsViewModel(store: store))
        _goalsViewModel = StateObject(wrappedValue: GoalsViewModel(store: store))
        _insightsViewModel = StateObject(wrappedValue: InsightsViewModel(store: store, aiService: AIInsightsService()))
    }

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                ZStack(alignment: .bottom) {
                    AppTheme.background.ignoresSafeArea()

                    currentScreen

                    BottomTabBar(selectedTab: $selectedTab) {
                        showingQuickAdd = true
                    }
                }
                .task {
                    await insightsViewModel.generateAIInsight()
                }
                .sheet(isPresented: $showingQuickAdd) {
                    TransactionEntrySheet(existingTransaction: nil) { transaction in
                        transactionsViewModel.add(transaction: transaction)
                    }
                    .presentationDetents([.large])
                }
            } else {
                OnboardingFlowView(store: store)
            }
        }
        .onChange(of: store.hasCompletedOnboarding) { _, completed in
            if completed { selectedTab = .home }
        }
        .dismissKeyboardOnTap()
        .preferredColorScheme(appColorScheme)
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .home:
            DashboardScreen(viewModel: dashboardViewModel, colorScheme: colorSchemeBinding)
        case .transactions:
            TransactionsScreen(viewModel: transactionsViewModel, colorScheme: colorSchemeBinding)
        case .goals:
            GoalsScreen(viewModel: goalsViewModel, colorScheme: colorSchemeBinding)
        case .profile:
            ProfileScreen(store: store, insightsViewModel: insightsViewModel, colorScheme: colorSchemeBinding)
        }
    }
}
