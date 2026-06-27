//
//  AudioVisualizerTestApp.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 19/06/26.
//

import SwiftUI
import SwiftData

@main
struct AudioVisualizerTestApp: App {

    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(for: RecordingMeta.self)
        }
    }
}
