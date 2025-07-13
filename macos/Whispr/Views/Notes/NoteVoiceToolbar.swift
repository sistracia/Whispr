import SwiftUI

struct NoteVoiceToolbar: ToolbarContent {
    @EnvironmentObject var modelData: ModelData

    var note: Note?
    var processController: AudioProcessController

    @Binding var processRecorder: ProcessTapRecorder
    @Binding var appRecorder: ProcessTapRecorder
    @Binding var micRecorder: MicRecorder

    @State private var locale: Locale = Locale(identifier: "en-US")

    var placement: ToolbarItemPlacement

    var noteIndex: Int? {
        guard let note = note,
            let noteIndex = modelData.notes.firstIndex(where: {
                $0.createdAtInt == note.createdAtInt
            })
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
            let processRecording = Binding(
                get: { isProcessStreaming },
                set: {
                    toggleRecording(
                        isRecording: $0,
                        type: NoteType.process,
                        streamSource: processRecorder,
                        selectedNoteIndex: noteIndex
                    )
                }
            )

            let appRecording = Binding(
                get: { isAppStreaming },
                set: {
                    toggleRecording(
                        isRecording: $0,
                        type: NoteType.application,
                        streamSource: appRecorder,
                        selectedNoteIndex: noteIndex
                    )
                }
            )

            let micRecording = Binding(
                get: { isMicStreaming },
                set: {
                    toggleRecording(
                        isRecording: $0,
                        type: NoteType.microphone,
                        streamSource: micRecorder,
                        selectedNoteIndex: noteIndex
                    )
                }
            )

            ToolbarItemGroup(placement: placement) {
                Menu {
                    Picker("Language", selection: $locale) {
                        ForEach(SpeechRecognizer.supportedLocales, id: \.self) {
                            supportedLocale in
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

                    Picker(
                        "Select Process",
                        selection: $processRecorder.process
                    ) {
                        ForEach(processController.processAudios, id: \.self) {
                            process in
                            Text(process.name)
                                .tag(process)
                        }
                    }
                    .pickerStyle(.inline)
                    .disabled(isProcessStreaming)
                } label: {
                    Label(
                        "Process Recorder",
                        systemImage: isProcessStreaming
                            ? "laptopcomputer.slash" : "laptopcomputer"
                    )
                }

                Menu {
                    Toggle("Record Application", isOn: appRecording)
                        .disabled(appRecorder.process == nil)

                    Picker(
                        "Select Application",
                        selection: $appRecorder.process
                    ) {
                        ForEach(processController.appAudios, id: \.self) {
                            process in
                            Text(process.name)
                                .tag(process)
                        }
                    }
                    .pickerStyle(.inline)
                    .disabled(isAppStreaming)
                } label: {
                    Label(
                        "Application Recorder",
                        systemImage: isAppStreaming
                            ? "rectangle.on.rectangle.slash"
                            : "rectangle.on.rectangle"
                    )
                }

                Menu {
                    Toggle("Record Microphone", isOn: micRecording)
                        .disabled(micRecorder.captureDevice == nil)

                    Picker(
                        "Select Microphone",
                        selection: $micRecorder.captureDevice
                    ) {
                        ForEach(MicRecorder.captureDevices, id: \.self) {
                            captureDevice in
                            Text(captureDevice.localizedName)
                                .tag(captureDevice)
                        }
                    }
                    .pickerStyle(.inline)
                    .disabled(isMicStreaming)
                } label: {
                    Label(
                        "Microphone",
                        systemImage: isMicStreaming
                            ? "microphone.slash" : "microphone"
                    )
                }
            }
        }
    }

    private func toggleRecording(
        isRecording: Bool,
        type: NoteType,
        streamSource: StreamSource,
        selectedNoteIndex: Int
    ) {
        Task { @MainActor in
            if isRecording {
                let _ = await streamSource.startStream(locale: locale) {
                    transcription,
                    error in
                    if error != nil {
                        return
                    }
                    modelData.writeNote(transcription, type: type)
                }
            } else {
                await streamSource.stopStream()
                modelData.stopRecording(type: type)
            }
        }
    }
}
