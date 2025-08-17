import SwiftUI

struct NoteEditor: View {
    @EnvironmentObject var modelData: ModelData

    var note: Note?

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
                        state:
                            modelData
                            .processSpeech
                            .streamSource
                            .state,
                        audioLevelsProvider:
                            modelData
                            .processSpeech
                            .streamSource.audioLevelsProvider,
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
                        state:
                            modelData
                            .applicationSpeech
                            .streamSource
                            .state,
                        audioLevelsProvider:
                            modelData
                            .applicationSpeech
                            .streamSource
                            .audioLevelsProvider,
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
                        state:
                            modelData
                            .microphoneSpeech
                            .streamSource
                            .state,
                        audioLevelsProvider:
                            modelData
                            .microphoneSpeech
                            .streamSource
                            .audioLevelsProvider,
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
    let note = Note(
        contents: [
            .init(
                timestamp: Date.now,
                text: "Content 1"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 2"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 3"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 4"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 5"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 6"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 7"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 8"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 9"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 10"
            ),
        ],
        createdAt: Date(),
        fileURL: URL(string: "random")
    )

    let modelData = ModelData(notes: [note])

    return NoteEditor(
        note: note,
    )
    .frame(minWidth: 480, maxHeight: 180)
    .environmentObject(modelData)
}
