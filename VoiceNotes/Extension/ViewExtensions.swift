//
//  ViewExtensions.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 24/06/26.
//

import SwiftUI

// MARK: - Glass Effect

extension View {

    /// Applies Liquid Glass on iOS 26+, falls back to ultraThinMaterial on earlier versions.
    /// Use for interactive elements (buttons, capsules) that don't need an explicit shape.
    @ViewBuilder
    func appGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive())
        } else {
            self.background(.ultraThinMaterial)
        }
    }

    /// Shape-aware variant — pass `.capsule` or `.circle` explicitly.
    /// Use when you need the glass to clip to a specific shape on iOS 17.
    @ViewBuilder
    func appGlass(_ shape: some Shape & InsettableShape) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
    
    
    func animatedVisibility(_ isVisible: Bool) -> some View {

        self
            .opacity(isVisible ? 1 : 0)
//            .scaleEffect(isVisible ? 1 : 0.9)
//            .allowsHitTesting(isVisible)
    }
}

// MARK: - Button Styles

/// Shrinks the button slightly on press — used across recording cards and filter chips.
struct ShrinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
