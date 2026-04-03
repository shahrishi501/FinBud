import SwiftUI

struct TransactionEntrySheet: View {
    let existingTransaction: Transaction?
    let onSave: (Transaction) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var type: TransactionType = .expense
    @State private var category: FinanceCategory = .food
    @State private var accountType: MoneyAccountType = .upi
    @State private var date = Date()
    @State private var merchant = ""
    @State private var note = ""
    @State private var showValidation = false

    private var isEditing: Bool { existingTransaction != nil }
    private var amount: Double { Double(amountText) ?? 0 }
    private var isValid: Bool { amount > 0 }

    init(existingTransaction: Transaction? = nil, onSave: @escaping (Transaction) -> Void) {
        self.existingTransaction = existingTransaction
        self.onSave = onSave
        _amountText   = State(initialValue: existingTransaction.map { String(Int($0.amount)) } ?? "")
        _type         = State(initialValue: existingTransaction?.type ?? .expense)
        _category     = State(initialValue: existingTransaction?.category ?? .food)
        _accountType  = State(initialValue: existingTransaction?.accountType ?? .upi)
        _date         = State(initialValue: existingTransaction?.date ?? .now)
        _merchant     = State(initialValue: existingTransaction?.merchant ?? "")
        _note         = State(initialValue: existingTransaction?.note ?? "")
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {

                    // Header + Close
                    HStack {
                        Text(isEditing ? "Edit" : "Add Transaction")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.mutedText)
                                .padding(8)
                                .background(Circle().fill(AppTheme.elevatedCard))
                        }
                    }

                    // Amount + Type
                    GlassCard {
                        VStack(spacing: 14) {
                            // Type toggle
                            HStack(spacing: 10) {
                                ForEach(TransactionType.allCases) { txnType in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) { type = txnType }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: txnType == .income ? "arrow.up" : "arrow.down")
                                                .font(.system(size: 13, weight: .bold))
                                            Text(txnType.title)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundStyle(type == txnType ? .white : AppTheme.mutedText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(type == txnType
                                                      ? AnyShapeStyle(txnType.tint)
                                                      : AnyShapeStyle(AppTheme.elevatedCard))
                                        )
                                    }
                                }
                            }

                            // Amount
                            HStack(alignment: .center, spacing: 4) {
                                Text("₹")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.accent)
                                TextField("0", text: $amountText)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.primaryText)
                            }

                            if showValidation && amount <= 0 {
                                Text("Enter a valid amount")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.negative)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    
                    // Payment Method
                    HStack(spacing: 10) {
                        ForEach(MoneyAccountType.allCases) { method in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { accountType = method }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: method.icon)
                                        .font(.system(size: 18))
                                    Text(method.title)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundStyle(accountType == method ? .white : AppTheme.mutedText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(accountType == method
                                              ? AnyShapeStyle(AppTheme.accent)
                                              : AnyShapeStyle(AppTheme.elevatedCard))
                                )
                            }
                        }
                    }
                    
                    // Date + Merchant + Note
                    GlassCard {
                        VStack(spacing: 12) {
                            // Date row
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(AppTheme.accent)
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Spacer()
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }

                            Divider().overlay(AppTheme.elevatedCard)

                            // Merchant
                            TextField("Merchant (e.g. Swiggy)", text: $merchant)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.primaryText)

                            Divider().overlay(AppTheme.elevatedCard)

                            // Note
                            TextField("Note (optional)", text: $note)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }

                    // Category Grid
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CATEGORY")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.mutedText)
                                .tracking(1.5)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10) {
                                ForEach(FinanceCategory.allCases) { cat in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) { category = cat }
                                    } label: {
                                        VStack(spacing: 5) {
                                            Circle()
                                                .fill(category == cat ? cat.color.opacity(0.2) : AppTheme.elevatedCard)
                                                .frame(width: 42, height: 42)
                                                .overlay(
                                                    Image(systemName: cat.icon)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundStyle(category == cat ? cat.color : AppTheme.mutedText)
                                                )
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(category == cat ? cat.color : .clear, lineWidth: 1.5)
                                                )

                                            Text(cat.title)
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundStyle(category == cat ? AppTheme.primaryText : AppTheme.mutedText)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Save
                    Button {
                        showValidation = true
                        guard isValid else { return }

                        let transaction = Transaction(
                            id: existingTransaction?.id ?? UUID(),
                            amount: amount,
                            type: type,
                            category: category,
                            accountType: accountType,
                            date: date,
                            note: note.isEmpty ? "No note" : note,
                            merchant: merchant.isEmpty ? "Manual entry" : merchant.trimmingCharacters(in: .whitespaces)
                        )
                        onSave(transaction)
                        dismiss()
                    } label: {
                        Text(isEditing ? "Update" : "Add Transaction")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(AppTheme.accent)
                            )
                    }
                }
                .padding(20)
                .padding(.bottom, 30)
            }
        }
        .dismissKeyboardOnTap()
    }
}
