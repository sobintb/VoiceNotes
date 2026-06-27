//
//  ShareSheet.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 25/06/26.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
