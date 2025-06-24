import SwiftUI

let kAppName = "Whispr"
let kAppSubsystem = "com.sistracia.\(kAppName)"
let kAudioStreamingQueue = "\(kAppSubsystem).AudioStreamingQueue"
let kProcessTapRecorder = "\(kAppSubsystem).ProcessTapRecorder"
let kWriteFileThrottle = "\(kAppSubsystem).Throttle"

@main
struct WhisprApp: App {
    @StateObject private var modelData = ModelData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
        }
    }
}
