import SwiftUI
import Cocoa
import ApplicationServices

struct ApplicationInfo: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let subrole: String?
    let value: String?
    let frame: String?
    let position: String?
    let size: String?
    let children: [ApplicationInfo]
    let axElement: AXUIElement?
}

class AccessibilityManager: ObservableObject {
    @Published var applications: [ApplicationInfo] = []
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !trusted {
            print("Please grant accessibility permissions in System Settings > Privacy & Security > Accessibility")
        }
    }
    
    func openYouTubeInBrowser() {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        // List of common browser bundle identifiers
        let browserBundleIds = [
            "com.google.Chrome",
            "com.apple.Safari",
            "org.mozilla.firefox",
            "com.brave.Browser",
            "com.microsoft.edgemac"
        ]
        
        // Find the first running browser
        if let browser = runningApps.first(where: { app in
            guard let bundleId = app.bundleIdentifier else { return false }
            return browserBundleIds.contains(bundleId)
        }) {
            // Create accessibility element for the browser
            let axBrowser = AXUIElementCreateApplication(browser.processIdentifier)
            
            // Create URL object
            let urlString = "https://www.youtube.com"
            guard let url = URL(string: urlString) else { return }
            
            // First try to create a new tab/window using accessibility
            var windowsRef: CFTypeRef?
            AXUIElementCopyAttributeValue(axBrowser, kAXWindowsAttribute as CFString, &windowsRef)
            
            if let windows = windowsRef as? [AXUIElement], let frontWindow = windows.first {
                // Try to perform "New Tab" action
                var actionNames: CFArray?
                AXUIElementCopyActionNames(frontWindow, &actionNames)
                
                if let actions = actionNames as? [String],
                   actions.contains(kAXPressAction as String) {
                    AXUIElementPerformAction(frontWindow, kAXPressAction as CFString)
                }
            }
            
            // Open URL in browser
            workspace.open(url)
            
            // Activate the browser
            browser.activate(options: .activateIgnoringOtherApps)
        } else {
            // If no browser is running, just open URL in default browser
            workspace.open(URL(string: "https://www.youtube.com")!)
        }
    }
    
    private func getAttributeValue(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        if result == .success {
            if let stringValue = value as? String {
                return stringValue
            } else if let numberValue = value as? NSNumber {
                return numberValue.stringValue
            }
        }
        return nil
    }
    
    private func getElementFrame(_ element: AXUIElement) -> String? {
        if let position = getPosition(element),
           let size = getSize(element) {
            return "x=\(position.x) y=\(position.y) w=\(size.width) h=\(size.height)"
        }
        return nil
    }
    
    private func getPosition(_ element: AXUIElement) -> CGPoint? {
        var pointRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &pointRef)
        if result == .success, let pointValue = pointRef {
            var point = CGPoint.zero
            AXValueGetValue(pointValue as! AXValue, .cgPoint, &point)
            return point
        }
        return nil
    }
    
    private func getSize(_ element: AXUIElement) -> CGSize? {
        var sizeRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)
        if result == .success, let sizeValue = sizeRef {
            var size = CGSize.zero
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
            return size
        }
        return nil
    }
    
    private func getChildElements(_ element: AXUIElement) -> [AXUIElement] {
        var children: [AXUIElement] = []
        
        // Get all available attributes
        var attributeNames: CFArray?
        let result = AXUIElementCopyAttributeNames(element, &attributeNames)
        guard result == .success,
              let attributes = attributeNames as? [String] else {
            return children
        }
        
        // Look for attributes that might contain child elements
        let childAttributes = ["AXChildren", "AXRows", "AXColumns", "AXContents", "AXWindows"]
        
        for attribute in attributes where childAttributes.contains(attribute) {
            var childrenRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &childrenRef)
            if result == .success,
               let childArray = childrenRef as? [AXUIElement] {
                children.append(contentsOf: childArray)
            }
        }
        
        return children
    }
    
    private func createApplicationInfo(from element: AXUIElement, name: String? = nil) -> ApplicationInfo {
        let role = getAttributeValue(element, kAXRoleAttribute as String) ?? "unknown"
        let subrole = getAttributeValue(element, kAXSubroleAttribute as String)
        let value = getAttributeValue(element, kAXValueAttribute as String)
        let frame = getElementFrame(element)
        let position = getPosition(element).map { "x=\($0.x) y=\($0.y)" }
        let size = getSize(element).map { "w=\($0.width) h=\($0.height)" }
        
        let elementName = name ?? getAttributeValue(element, kAXTitleAttribute as String) ?? getAttributeValue(element, kAXDescriptionAttribute as String) ?? role
        
        var children: [ApplicationInfo] = []
        for childElement in getChildElements(element) {
            children.append(createApplicationInfo(from: childElement))
        }
        
        return ApplicationInfo(
            name: elementName,
            role: role,
            subrole: subrole,
            value: value,
            frame: frame,
            position: position,
            size: size,
            children: children,
            axElement: element
        )
    }
    
    func refreshApplications() {
        var applications: [ApplicationInfo] = []
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        for app in runningApps {
            if let bundleIdentifier = app.bundleIdentifier {
                let axApp = AXUIElementCreateApplication(app.processIdentifier)
                let appInfo = createApplicationInfo(from: axApp, name: app.localizedName ?? bundleIdentifier)
                applications.append(appInfo)
            }
        }
        
        DispatchQueue.main.async {
            self.applications = applications
        }
    }
    
    func sendWhatsAppMessage() {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        // Look for Chrome browser
        guard let chromeBrowser = runningApps.first(where: { app in
            return app.bundleIdentifier == "com.google.Chrome"
        }) else {
            print("Chrome browser not found")
            return
        }
        
        // Activate Chrome browser
        chromeBrowser.activate(options: .activateIgnoringOtherApps)
        print("Activated Chrome browser")
        
        // Wait for browser to activate
        Thread.sleep(forTimeInterval: 1.0)
        
        // Open new tab with Command+T
        KeyboardUtils.pressCommandKey(keyCode: 0x11) // 'T' key
        Thread.sleep(forTimeInterval: 0.5)
        
        // Command+L to focus address bar
        KeyboardUtils.pressCommandKey(keyCode: 0x25) // 'L' key
        Thread.sleep(forTimeInterval: 0.5)
        
        // Type WhatsApp Web URL
        KeyboardUtils.typeString("https://web.whatsapp.com")
        KeyboardUtils.pressEnter()
        
        // Wait longer for WhatsApp Web to load
        Thread.sleep(forTimeInterval: 8.0)
        
        // Press Command+/ to focus search
        KeyboardUtils.pressCommandKey(keyCode: 0x2C) // '/' key
        Thread.sleep(forTimeInterval: 1.5)
        
        // Type search text
        KeyboardUtils.typeString("my group")
        Thread.sleep(forTimeInterval: 1.5)
        
        // Press Enter to select first result
        KeyboardUtils.pressEnter()
        Thread.sleep(forTimeInterval: 1.5)
        
        // Type message
        KeyboardUtils.typeString("hello")
        
        // Press Enter to send
        KeyboardUtils.pressEnter()
    }
}
