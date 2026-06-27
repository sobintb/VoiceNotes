//
//  WaveformView.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 21/06/26.
//

import SwiftUI

struct WaveformView: View {

    let level: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let baseline = size.height * 0.65
                let amplitude = max(CGFloat(level) * 40, 4)

                let thirdPath = wavePath(
                    size: size,
                    baseline: baseline,
                    amplitude: amplitude * 0.9,
                    phase: time * 1.7
                )

                context.fill(
                    thirdPath,
                    with: .linearGradient(
                        Gradient(colors: [.red.opacity(0.15), .pink.opacity(0.3)]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )

                let secondaryPath = wavePath(
                    size: size,
                    baseline: baseline,
                    amplitude: amplitude * 0.6,
                    phase: time * 1.2
                )

                context.fill(
                    secondaryPath,
                    with: .color(.red.opacity(0.20))
                )

                let mainPath = wavePath(
                    size: size,
                    baseline: baseline,
                    amplitude: amplitude,
                    phase: time * 2.0
                )

                context.fill(
                    mainPath,
                    with: .linearGradient(
                        Gradient(colors: [.pink.opacity(0.3), .red.opacity(0.15)]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
            }
        }
    }

    private func wavePath(
        size: CGSize,
        baseline: CGFloat,
        amplitude: CGFloat,
        phase: Double
    ) -> Path {
        var path = Path()
        var points: [CGPoint] = []

        for x in stride(from: CGFloat(0), through: size.width, by: 4) {
            let progress = Double(x / size.width)
            let y = baseline - CGFloat(sin(progress * .pi * 4 + phase)) * amplitude
            points.append(CGPoint(x: x, y: y))
        }

        guard let first = points.first else { return path }

        path.move(to: first)

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(
                x: (previous.x + current.x) / 2,
                y: (previous.y + current.y) / 2
            )
            path.addQuadCurve(to: midpoint, control: previous)
        }

        if let last = points.last {
            path.addLine(to: last)
        }

        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()

        return path
    }
}
