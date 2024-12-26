import Foundation

#if os(macOS)
class ScreenshotManager {
    static func takeScreenshot() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        
        // Create a timestamp for the filename
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        // Save to Downloads folder
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let downloadsDirectory = homeDirectory.appendingPathComponent("Downloads")
        let filename = "screenshot-\(timestamp).png"
        let filepath = downloadsDirectory.appendingPathComponent(filename).path
        
        task.arguments = ["-x", filepath] // -x for no sound
        
        do {
            try task.run()
            print("Screenshot saved to: \(filepath)")
        } catch {
            print("Failed to take screenshot: \(error)")
        }
    }
}
#endif 