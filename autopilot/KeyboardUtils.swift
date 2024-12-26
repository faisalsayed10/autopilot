import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import AVFoundation
import CoreML
import Speech


extension Character {
    var keyCode: CGKeyCode? {
        let keyMap: [Character: CGKeyCode] = [
            "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05,
            "z": 0x06, "x": 0x07, "c": 0x08, "v": 0x09, "b": 0x0B, "q": 0x0C,
            "w": 0x0D, "e": 0x0E, "r": 0x0F, "y": 0x10, "t": 0x11, "1": 0x12,
            "2": 0x13, "3": 0x14, "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18,
            "9": 0x19, "7": 0x1A, "-": 0x1B, "8": 0x1C, "0": 0x1D, "]": 0x1E,
            "o": 0x1F, "u": 0x20, "[": 0x21, "i": 0x22, "p": 0x23, "l": 0x25,
            "j": 0x26, "'": 0x27, "k": 0x28, ";": 0x29, "\\": 0x2A, ",": 0x2B,
            "/": 0x2C, "n": 0x2D, "m": 0x2E, ".": 0x2F, " ": 0x31
        ]
        return keyMap[self.lowercased().first ?? self]
    }
}

struct KeyboardUtils {
    static func typeString(_ text: String, delay: TimeInterval = 0.05) {
        for char in text {
            if let keyCode = char.keyCode {
                let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
                keyDown?.post(tap: .cghidEventTap)
                
                let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
                keyUp?.post(tap: .cghidEventTap)
                
                Thread.sleep(forTimeInterval: delay)
            }
        }
    }
    
    static func pressKey(keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
    
    static func pressEnter() {
        pressKey(keyCode: 0x24)
    }
    
    static func pressCommandKey(keyCode: CGKeyCode) {
        pressKey(keyCode: keyCode, flags: .maskCommand)
    }
} 
