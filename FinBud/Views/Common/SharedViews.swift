import Charts
import SwiftUI

struct ScreenContainer<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var colorScheme: ColorScheme?
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(.white))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(subtitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.mutedText)
                        }
                    }
                    Spacer()
                    Button {
                        if colorScheme == .dark { colorScheme = .light } else { colorScheme = .dark }
                    } label: {
                        Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(10)
                            .background(Circle().fill(AppTheme.card))
                    }
                }
                .padding(.top, 12)

                content
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }
}

struct GlassCard<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder var content: Content

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(AppTheme.stroke, lineWidth: 1)
                    )
            )
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.mutedText)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.14))
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isSelected ? .white : AppTheme.mutedText)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.card))
            )
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        GlassCard {
            VStack(alignment: .center, spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.accent)
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.mutedText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let tint: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.stroke, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
        }
    }
}
