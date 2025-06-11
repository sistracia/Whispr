import SwiftUI

let kAppSubsystem = "com.sistracia.Whispr"
let kAudioStreamingQueue = "\(kAppSubsystem).AudioStreamingQueue"
let kProcessTapRecorder = "\(kAppSubsystem).ProcessTapRecorder"

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
