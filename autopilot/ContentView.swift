//
//  ContentView.swift
//  autopilot
//
//  Created by Faisal Sayed on 12/23/24.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import AVFoundation
import CoreML
import Speech
import ScreenCaptureKit

#if os(macOS)
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.state = .active
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#endif

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    
    var body: some View {
        ZStack {
            VisualEffectBackground()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image(systemName: "microphone")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                
                Button(audioRecorder.isRecording ? "Stop listening" : "Listen") {
                    if audioRecorder.isRecording {
                        audioRecorder.stopRecording()
                    } else {
                        audioRecorder.startRecording()
                    }
                }
                
                Button("Take Screenshot") {
                    #if os(macOS)
                    ScreenshotManager.takeScreenshot()
                    #endif
                }
                .padding()
                
                Text(audioRecorder.audioTranscription)
                    .padding()
            }
            .padding()
            .frame(minWidth: 300)
        }
    }
}

#Preview {
    ContentView()
}
