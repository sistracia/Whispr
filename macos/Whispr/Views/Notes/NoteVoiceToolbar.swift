import AVFoundation
import SwiftUI

struct NoteVoiceToolbar: ToolbarContent {
    @EnvironmentObject var modelData: ModelData

    var processController: AudioProcessController

    @State var processAudioProcess: AudioProcess? = nil
    @State var applicationAudioProcess: AudioProcess? = nil
    @State var captureDevice: AVCaptureDevice? = nil

    @State private var locale: Locale = Locale(identifier: "en-US")

    var placement: ToolbarItemPlacement

    var body: some ToolbarContent {
        let processRecording = Binding(
            get: { modelData.isProcessStreaming },
            set: { isRecording in
                guard let processAudioProcess = processAudioProcess
                else { return }
                toggleRecording(
                    isRecording: isRecording,
                    audioSource: .audioProcess(processAudioProcess),
                    speechProcessor: modelData.processSpeech
                )
            }
        )

        let appRecording = Binding(
            get: { modelData.isApplicationStreaming },
            set: { isRecording in
                guard let applicationAudioProcess = applicationAudioProcess
                else { return }
                toggleRecording(
                    isRecording: isRecording,
                    audioSource: .audioProcess(applicationAudioProcess),
                    speechProcessor: modelData.applicationSpeech
                )
            }
        )

        let micRecording = Binding(
            get: { modelData.isMicrophoneStreaming },
            set: { isRecording in
                guard let captureDevice = captureDevice
                else { return }
                toggleRecording(
                    isRecording: isRecording,
                    audioSource: .captureDevice(captureDevice),
                    speechProcessor: modelData.microphoneSpeech
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
                .disabled(modelData.isStreaming)
            } label: {
                Label("Language", systemImage: "globe")
            }

            Menu {
                Toggle("Record Process", isOn: processRecording)
                    .disabled(processAudioProcess == nil)

                Picker(
                    "Select Process",
                    selection: $processAudioProcess
                ) {
                    ForEach(processController.processAudios, id: \.self) {
                        process in
                        Text(process.name)
                            .tag(process)
                    }
                }
                .pickerStyle(.inline)
                .disabled(modelData.isProcessStreaming)
            } label: {
                Label(
                    "Process Recorder",
                    systemImage: modelData.isProcessStreaming
                        ? "laptopcomputer.slash" : "laptopcomputer"
                )
            }

            Menu {
                Toggle("Record Application", isOn: appRecording)
                    .disabled(applicationAudioProcess == nil)

                Picker(
                    "Select Application",
                    selection: $applicationAudioProcess
                ) {
                    ForEach(processController.appAudios, id: \.self) {
                        process in
                        Text(process.name)
                            .tag(process)
                    }
                }
                .pickerStyle(.inline)
                .disabled(modelData.isApplicationStreaming)
            } label: {
                Label(
                    "Application Recorder",
                    systemImage: modelData.isApplicationStreaming
                        ? "rectangle.on.rectangle.slash"
                        : "rectangle.on.rectangle"
                )
            }

            Menu {
                Toggle("Record Microphone", isOn: micRecording)
                    .disabled(captureDevice == nil)

                Picker(
                    "Select Microphone",
                    selection: $captureDevice
                ) {
                    ForEach(AVCaptureDevice.captureDevices, id: \.self) {
                        captureDevice in
                        Text(captureDevice.localizedName)
                            .tag(captureDevice)
                    }
                }
                .pickerStyle(.inline)
                .disabled(modelData.isMicrophoneStreaming)
            } label: {
                Label(
                    "Microphone",
                    systemImage: modelData.isMicrophoneStreaming
                        ? "microphone.slash" : "microphone"
                )
            }
        }
    }

    private func toggleRecording(
        isRecording: Bool,
        audioSource: AudioSourceType,
        speechProcessor: SpeechProcessor
    ) {
        Task {
            let _ = await modelData.toggleRecording(
                isRecording: isRecording,
                audioSource: audioSource,
                locale: locale,
                speechProcessor: speechProcessor
            )
        }
    }
}
