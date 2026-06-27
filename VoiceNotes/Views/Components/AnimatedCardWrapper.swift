//
//  AnimatedCardWrapper.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 25/06/26.
//

import SwiftUI

/// A thin wrapper that plays a staggered entrance animation
/// when a RecordingCard appears in the list.
///
/// Keeping this separate from RecordingCard is intentional —
/// RecordingCard already owns its delete animation (opacity + frame collapse).
/// Merging both into one view would create modifier stacking conflicts.
/// This wrapper adds its own isolated opacity/offset layer on top.
struct AnimatedCardWrapper<Content: View>: View {

    // The position of this card in the list (0, 1, 2 ...)
    // Used to calculate the stagger delay.
    let index: Int

    // The actual RecordingCard — passed in as a closure
    // @ViewBuilder lets us use if/else or multiple views inside
    @ViewBuilder let content: () -> Content

    // Drives the entrance animation.
    // Starts false (invisible), flips to true on appear.
    @State private var isVisible = false

    var body: some View {
        content()
            // Fade in from 0 → 1
            .opacity(isVisible ? 1 : 0)
            // Slide up from 18pt below → natural position
            .offset(y: isVisible ? 0 : 18)
            .onAppear {
                withAnimation(
                    // spring gives it the physical, elastic feel
                    // response: how fast it moves (lower = snappier)
                    // dampingFraction: how much it bounces (lower = more bounce)
                    .spring(response: 0.28, dampingFraction: 0.90)
                    // Each card waits a little longer than the previous one.
                    // min(index, 10) caps the delay so card 15, 20 etc
                    // don't have a visible 1-second wait.
                    .delay(Double(min(index, 10)) * 0.055)
                ) {
                    isVisible = true
                }
            }
    }
}
