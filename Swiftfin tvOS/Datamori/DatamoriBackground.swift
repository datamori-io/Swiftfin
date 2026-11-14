//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Ink page background with faint contour lines and a sparse data-network
/// overlay (white ~5% lines, a few red nodes). Drawn once with `Canvas`;
/// deterministic, so it never shifts between launches.
struct DatamoriBackground: View {

    @ContentBuilder
    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Datamori.ink))
            Self.drawContours(in: &context, size: size)
            Self.drawNetwork(in: &context, size: size)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    // MARK: - Contours

    /// Two loose "topographic" clusters of nested wobbly rings.
    private static func drawContours(in context: inout GraphicsContext, size: CGSize) {
        let unit = min(size.width, size.height)
        let clusters: [(center: CGPoint, rings: Int, phase: Double)] = [
            (CGPoint(x: size.width * 0.82, y: size.height * 0.22), 14, 0.0),
            (CGPoint(x: size.width * 0.12, y: size.height * 0.95), 11, 1.7),
        ]

        for cluster in clusters {
            for ring in 1 ... cluster.rings {
                let base = unit * 0.045 * Double(ring)
                var path = Path()
                let steps = 180
                for step in 0 ... steps {
                    let theta = Double(step) / Double(steps) * 2 * .pi
                    let wobble = 1
                        + 0.10 * sin(3 * theta + cluster.phase + Double(ring) * 0.35)
                        + 0.05 * sin(5 * theta - cluster.phase * 1.3 - Double(ring) * 0.2)
                    let radius = base * wobble
                    let point = CGPoint(
                        x: cluster.center.x + radius * cos(theta) * 1.35,
                        y: cluster.center.y + radius * sin(theta)
                    )
                    if step == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(.white.opacity(0.045)), lineWidth: 1.5)
            }
        }
    }

    // MARK: - Network

    /// Fixed node layout in unit coordinates, with the edges between them.
    private static let nodes: [CGPoint] = [
        CGPoint(x: 0.06, y: 0.30),
        CGPoint(x: 0.18, y: 0.18),
        CGPoint(x: 0.30, y: 0.34),
        CGPoint(x: 0.47, y: 0.12),
        CGPoint(x: 0.62, y: 0.28),
        CGPoint(x: 0.74, y: 0.10),
        CGPoint(x: 0.90, y: 0.40),
        CGPoint(x: 0.56, y: 0.62),
        CGPoint(x: 0.38, y: 0.78),
        CGPoint(x: 0.80, y: 0.80),
        CGPoint(x: 0.22, y: 0.60),
        CGPoint(x: 0.96, y: 0.66),
    ]

    private static let edges: [(Int, Int)] = [
        (0, 1),
        (1, 2),
        (2, 3),
        (3, 4),
        (4, 5),
        (4, 6),
        (4, 7),
        (7, 8),
        (7, 9),
        (9, 11),
        (6, 11),
        (2, 10),
        (10, 8),
    ]

    /// Indices of the few nodes drawn in the accent red.
    private static let redNodes: Set<Int> = [2, 7, 11]

    private static func drawNetwork(in context: inout GraphicsContext, size: CGSize) {
        func point(_ index: Int) -> CGPoint {
            CGPoint(x: nodes[index].x * size.width, y: nodes[index].y * size.height)
        }

        var lines = Path()
        for (from, to) in edges {
            lines.move(to: point(from))
            lines.addLine(to: point(to))
        }
        context.stroke(lines, with: .color(.white.opacity(0.05)), lineWidth: 1.5)

        for index in nodes.indices {
            let isRed = redNodes.contains(index)
            let radius: CGFloat = isRed ? 6 : 4
            let center = point(index)
            let dot = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.fill(dot, with: .color(isRed ? Datamori.red.opacity(0.55) : .white.opacity(0.08)))
        }
    }
}
