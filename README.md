# FinBud

SwiftUI interview assignment built around a dark personal finance companion flow, using MVVM, SwiftData, Charts, and an on-device AI insights layer.

Included product flow:

1. Four-step onboarding
2. Home dashboard
3. Transaction tracking
4. Goal and challenge
5. Insights with AI fallback

Highlights:

- SwiftUI + Charts for visual analytics
- MVVM with screen-level view models
- SwiftData-backed persistence for profile, goals, holdings, transactions, and onboarding state
- Add, edit, delete, search, and filter transactions
- Asset allocation is kept separate from expenses for stocks, mutual funds, and SIPs
- Goal tracking and no-spend streak challenge
- Apple Foundation Models integration behind safe availability checks

Assumptions:

- Onboarding collects name, age, date of birth, occupation, money types, current asset allocation, goals, and starter transactions for the current month.
- UPI SMS or notification ingestion is not implemented yet because that would require additional permissions and a riskier interview setup.
- If Apple Intelligence or Foundation Models is unavailable on the device, the app falls back to deterministic finance suggestions.
