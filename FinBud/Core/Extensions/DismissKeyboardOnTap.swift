//
//  DismissKeyboardOnTap.swift
//  FinBud
//
//  Created by Rishi Shah on 06/04/26.
//

import SwiftUI
import Combine

// Dismiss Keyboard to use on all forms
private struct DismissKeyboardOnTap: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture(perform: dismiss)
            .simultaneousGesture(TapGesture().onEnded { _ in dismiss() })
            .highPriorityGesture(TapGesture().onEnded { _ in dismiss() })
    }

    private func dismiss() {
        guard enabled else { return }
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

public extension View {
    func dismissKeyboardOnTap(_ enabled: Bool = true) -> some View {
        modifier(DismissKeyboardOnTap(enabled: enabled))
    }
}

public struct KeyboardDismissWrapper<Content: View>: View {
    private let enabled: Bool
    private let content: Content

    public init(enabled: Bool = true, @ViewBuilder content: () -> Content) {
        self.enabled = enabled
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { if enabled { dismiss() } }
            content
        }
    }

    private func dismiss() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

