//
//  autopilotApp.swift
//  autopilot
//
//  Created by Faisal Sayed on 12/23/24.
//

import SwiftUI

@main
struct autopilotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 300, minHeight: 200)
                .background(.ultraThinMaterial)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 300, height: 400)
    }
}
