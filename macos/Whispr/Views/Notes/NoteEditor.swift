import SwiftUI

struct NoteEditor: View {
    @EnvironmentObject var modelData: ModelData

    var note: Note?
    var processRecorder: ProcessTapRecorder
    var appRecorder: ProcessTapRecorder
    var micRecorder: MicRecorder

    var noteIndex: Int? {
        guard let note = note else { return nil }

        guard
            let noteIndex = modelData.notes.firstIndex(where: {
                $0.createdAtInt == note.createdAtInt
            })
        else { return nil }

        return noteIndex
    }

    var body: some View {
        if let noteIndex = noteIndex {
            VStack {
                HStack(spacing: 10) {
                    NoteVoiceMeter(
                        state: processRecorder.state,
                        audioLevelsProvider: processRecorder
                            .audioLevelsProvider,
                        label: {
                            Text("Process Sound Meter")
                        },
                        button: {
                            Label(
                                "Show Process Capture Error",
                                systemImage:
                                    "exclamationmark.triangle"
                            )
                            .labelStyle(.iconOnly)
                        },
                        popover: {
                            Text(
                                """
                                The process doesn't have an audio, or the permission is not granted.
                                 
                                To grant the permission, open System Settings, go to:
                                1. Privacy & Security > Screen & System Recording > System Audio Recording Only.
                                2. Privacy & Security > Speech Recognition.
                                """
                            )
                        }
                    )
                    NoteVoiceMeter(
                        state: appRecorder.state,
                        audioLevelsProvider: appRecorder.audioLevelsProvider,
                        label: {
                            Text("Application Sound Meter")
                        },
                        button: {
                            Label(
                                "Show Application Capture Error",
                                systemImage:
                                    "exclamationmark.triangle"
                            )
                            .labelStyle(.iconOnly)
                        },
                        popover: {
                            Text(
                                """
                                The application doesn't have an audio, or the permission is not granted.
                                 
                                To grant the permission, open System Settings, go to:
                                1. Privacy & Security > Screen & System Recording > System Audio Recording Only.
                                2. Privacy & Security > Speech Recognition.
                                """
                            )
                        }
                    )

                    NoteVoiceMeter(
                        state: micRecorder.state,
                        audioLevelsProvider: micRecorder.audioLevelsProvider,
                        label: {
                            Text("Microphone Meter")
                        },
                        button: {
                            Label(
                                "Show Microphone Capture Error",
                                systemImage:
                                    "exclamationmark.triangle"
                            )
                            .labelStyle(.iconOnly)
                        },
                        popover: {
                            Text(
                                """
                                The microphone doesn't capture the audio, or the permission is not granted.

                                To grant the permission, open System Settings, go to:
                                1. Privacy & Security > Microphone.
                                2. Privacy & Security > Speech Recognition.
                                """
                            )
                        }
                    )
                }
                .padding(3)
                NoteEditorContents(noteIndex: noteIndex)
            }
            .background(.background)
        } else {
            Text("Select or Create a Note")
        }
    }
}

#Preview {
    @Previewable @State var processRecorder = ProcessTapRecorder(
        speechRecognizer: SpeechRecognizer()
    )
    @Previewable @State var appRecorder = ProcessTapRecorder(
        speechRecognizer: SpeechRecognizer()
    )
    @Previewable @State var micRecorder = MicRecorder(
        speechRecognizer: SpeechRecognizer()
    )

    let note = Note(
        content: [
            .init(text: "Content 1"),
            .init(text: "Content 2"),
            .init(text: "Content 3"),
            .init(text: "Content 4"),
            .init(text: "Content 5"),
            .init(text: "Content 6"),
            .init(text: "Content 7"),
            .init(text: "Content 8"),
            .init(text: "Content 9"),
            .init(text: "Content 10"),
        ],
        createdAt: Date(),
        fileURL: URL(string: "random")
    )

    let modelData = ModelData(notes: [note])

    return NoteEditor(
        note: note,
        processRecorder: processRecorder,
        appRecorder: appRecorder,
        micRecorder: micRecorder,
    )
    .frame(minWidth: 480, maxHeight: 180)
    .environmentObject(modelData)
}
