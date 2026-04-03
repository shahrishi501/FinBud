import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// AI insights feature, which gives insights on user's spending
struct AISummaryContext {
    let balance: Double
    let income: Double
    let expenses: Double
    let topCategory: String
    let weekDelta: Double
    let savingsRate: Double
}

final class AIInsightsService {
    func generateInsight(context: AISummaryContext) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel().isAvailable {
            do {
                let session = LanguageModelSession(instructions: """
                You are a concise personal finance coach.
                Use a supportive tone.
                Return 2 short sentences with one observation and one action.
                Mention rupees when helpful.
                """)

                let response = try await session.respond(to: """
                Current balance: \(context.balance.inrCurrency)
                Total income: \(context.income.inrCurrency)
                Total expenses: \(context.expenses.inrCurrency)
                Highest spending category: \(context.topCategory)
                Week-over-week expense delta: \(context.weekDelta.signedPercent)
                Savings rate: \(String(format: "%.0f%%", context.savingsRate))
                Give one personalized spending insight and one actionable suggestion.
                """)
                return response.content
            } catch {
                return fallbackInsight(context: context)
            }
        }
        #endif

        return fallbackInsight(context: context)
    }

    private func fallbackInsight(context: AISummaryContext) -> String {
        if context.weekDelta > 15 {
            return "Your spending accelerated this week, mainly in \(context.topCategory.lowercased()). Trim one discretionary purchase and move that amount into savings before the weekend."
        }

        if context.savingsRate >= 30 {
            return "Your cash flow is healthy and your savings rate is strong. Keep the same split next month and direct any freelance income into the goal with the lowest completion percentage."
        }

        return "You are maintaining a stable balance, but \(context.topCategory.lowercased()) is still your biggest leak. Try capping that category early in the week so the rest of the month feels easier."
    }
}
