import SwiftData
import SwiftUI

@main
struct FinBudApp: App {
    private let container: ModelContainer
    @StateObject private var store: FinanceStore

    init() {
        do {
            let modelContainer = try ModelContainer(
                for: UserProfileEntity.self,
                AssetHoldingEntity.self,
                GoalEntity.self,
                TransactionEntity.self,
                AppStateEntity.self,
                SavingsCommitEntity.self
            )
            container = modelContainer
            _store = StateObject(wrappedValue: FinanceStore(container: modelContainer))
        } catch {
            fatalError("Unable to set up SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .modelContainer(container)
        }
    }
}


