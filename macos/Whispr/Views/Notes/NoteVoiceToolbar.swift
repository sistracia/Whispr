import SwiftUI
import ScreenCaptureKit

struct NoteVoiceToolbar: ToolbarContent {
    @EnvironmentObject var modelData: ModelData
    
    var note: Note?
    var speechRecognizer: SpeechRecognizer
    var processController: AudioProcessController
    
    @Binding var processRecorder: ProcessTapRecorder
    @Binding var appRecorder: ProcessTapRecorder
    @ObservedObject var micRecorder: MicRecorder
    
    @State private var locale: Locale = Locale(identifier: "en-US")
    
    var placement: ToolbarItemPlacement
    
    var noteIndex: Int? {
        guard let note = note,
              let noteIndex = modelData.notes.firstIndex(where: { $0.createdAtInt == note.createdAtInt })
        else { return nil }
        
        return noteIndex
    }
    
    var isProcessStreaming: Bool {
        processRecorder.state == .streaming
    }
    
    var isAppStreaming: Bool {
        appRecorder.state == .streaming
    }
    
    var isMicStreaming: Bool {
        micRecorder.state == .streaming
    }
    
    var isStreaming: Bool {
        isProcessStreaming || isAppStreaming || isMicStreaming
    }
    
    var body: some ToolbarContent {
        if let noteIndex = noteIndex {
            let processRecording = Binding(get: { isProcessStreaming },
                                           set: { toggleProcessRecording($0, selectedNoteIndex: noteIndex) })
            
            let appRecording = Binding(get: { isAppStreaming },
                                       set: { toggleAppRecording($0, selectedNoteIndex: noteIndex) })
            
            let micRecording = Binding(get: { isMicStreaming },
                                       set: { toggleMicRecording($0, selectedNoteIndex: noteIndex) })
            
            ToolbarItemGroup(placement: placement) {
                Menu {
                    Picker("Language", selection: $locale) {
                        ForEach(speechRecognizer.supportLocales.map { $0 }, id: \.self) { supportedLocale in
                            Text(supportedLocale.identifier)
                                .tag(supportedLocale)
                        }
                    }
                    .pickerStyle(.inline)
                    .disabled(isStreaming)
                } label: {
                    Label("Language", systemImage: "globe")
                }
                Menu {
                    Toggle("Record Process", isOn: processRecording)
                        .disabled(processRecorder.process == nil)
                    
                    Picker("Select Process", selection: $processRecorder.process) {
                        ForEach(processController.processAudios, id: \.self) { process in
                            Text(process.name)
                                .tag(process)
                        }
                    }
                    .pickerStyle(.inline)
                    .disabled(isProcessStreaming)
                } label: {
                    Label("Process Recorder", systemImage: isProcessStreaming ? "laptopcomputer.slash" : "laptopcomputer")
                }
                
                Menu {
                    Toggle("Record Application", isOn: appRecording)
                        .disabled(appRecorder.process == nil)
                    
                    Picker("Select Application", selection: $appRecorder.process) {
                        ForEach(processController.appAudios, id: \.self) { process in
                            Text(process.name)
                                .tag(process)
                        }
                    }
                    .pickerStyle(.inline)
                    .disabled(isAppStreaming)
                } label: {
                    Label("Application Recorder", systemImage: isAppStreaming ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle")
                }
                
                Menu {
                    Toggle("Record Microphone", isOn: micRecording)
                        .disabled(micRecorder.captureDevice == nil)
                    
                    Picker("Select Microphone", selection: $micRecorder.captureDevice) {
                        ForEach(micRecorder.captureDevices, id: \.self) { captureDevice in
                            Text(captureDevice.localizedName)
                                .tag(captureDevice)
                        }
                    }
                    .pickerStyle(.inline)
                    .disabled(isMicStreaming)
                } label: {
                    Label("Microphone", systemImage: isMicStreaming ? "microphone.slash" : "microphone" )
                }
            }
        }
    }
    
    private func toggleProcessRecording(_ isRecording: Bool, selectedNoteIndex: Int) {
        do {
            if isRecording {
                try processRecorder.startStream(locale: locale) { transcription, error in
                    if error != nil {
                        return
                    }
                    modelData.writeNote(transcription, at: selectedNoteIndex)
                }
            } else {
                processRecorder.stopStream()
            }
        } catch {
            
        }
    }
    
    private func toggleAppRecording(_ isRecording: Bool, selectedNoteIndex: Int) {
        do {
            if isRecording {
                try appRecorder.startStream(locale: locale) { transcription, error in
                    if error != nil {
                        return
                    }
                    modelData.writeNote(transcription, at: selectedNoteIndex)
                }
            } else {
                appRecorder.stopStream()
            }
        } catch {
            
        }
    }
    
    private func toggleMicRecording(_ isRecording: Bool, selectedNoteIndex: Int) {
        Task {
            if isRecording {
                await micRecorder.startStream(locale: locale) { transcription, error in
                    if error != nil {
                        return
                    }
                    modelData.writeNote(transcription, at: selectedNoteIndex)
                }
            } else {
                micRecorder.stopStream()
            }
        }
    }
}
