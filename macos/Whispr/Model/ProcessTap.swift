/*
 Ref:
 https://github.com/insidegui/AudioCap
 */

import AVFoundation
import AudioToolbox
import Combine
import OSLog
import SwiftUI

@Observable
final class ProcessTap {

    typealias InvalidationHandler = (ProcessTap) -> Void

    let process: AudioProcess
    let muteWhenRunning: Bool
    private let logger: Logger

    private(set) var errorMessage: String? = nil

    init(process: AudioProcess, muteWhenRunning: Bool = false) {
        self.process = process
        self.muteWhenRunning = muteWhenRunning
        self.logger = Logger(
            subsystem: kAppSubsystem,
            category: "\(String(describing: ProcessTap.self))(\(process.name))"
        )
    }

    @ObservationIgnored
    private var processTapID: AudioObjectID = .unknown
    @ObservationIgnored
    private var aggregateDeviceID = AudioObjectID.unknown
    @ObservationIgnored
    private var deviceProcID: AudioDeviceIOProcID?
    @ObservationIgnored
    private(set) var tapStreamDescription: AudioStreamBasicDescription?
    @ObservationIgnored
    private var invalidationHandler: InvalidationHandler?

    @ObservationIgnored
    private(set) var activated = false

    @MainActor
    func activate() {
        guard !activated else { return }
        activated = true

        logger.debug(#function)

        self.errorMessage = nil

        do {
            try prepare(for: process.objectID)
        } catch {
            logger.error("\(error, privacy: .public)")
            self.errorMessage = error.localizedDescription
        }
    }

    func invalidate() {
        guard activated else { return }
        defer { activated = false }

        logger.debug(#function)

        invalidationHandler?(self)
        self.invalidationHandler = nil

        if aggregateDeviceID.isValid {
            var err = AudioDeviceStop(aggregateDeviceID, deviceProcID)
            if err != noErr {
                logger.warning(
                    "Failed to stop aggregate device: \(err, privacy: .public)"
                )
            }

            if let deviceProcID {
                err = AudioDeviceDestroyIOProcID(
                    aggregateDeviceID,
                    deviceProcID
                )
                if err != noErr {
                    logger.warning(
                        "Failed to destroy device I/O proc: \(err, privacy: .public)"
                    )
                }
                self.deviceProcID = nil
            }

            err = AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            if err != noErr {
                logger.warning(
                    "Failed to destroy aggregate device: \(err, privacy: .public)"
                )
            }
            aggregateDeviceID = .unknown
        }

        if processTapID.isValid {
            let err = AudioHardwareDestroyProcessTap(processTapID)
            if err != noErr {
                logger.warning(
                    "Failed to destroy audio tap: \(err, privacy: .public)"
                )
            }
            self.processTapID = .unknown
        }
    }

    private func prepare(for objectID: AudioObjectID) throws {
        errorMessage = nil

        let tapDescription = CATapDescription(stereoMixdownOfProcesses: [
            objectID
        ])
        tapDescription.uuid = UUID()
        tapDescription.muteBehavior =
            muteWhenRunning ? .mutedWhenTapped : .unmuted
        tapDescription.isExclusive = true

        var tapID: AUAudioObjectID = .unknown
        var err = AudioHardwareCreateProcessTap(tapDescription, &tapID)

        guard err == noErr else {
            errorMessage = "Process tap creation failed with error \(err)"
            return
        }

        logger.debug("Created process tap #\(tapID, privacy: .public)")

        self.processTapID = tapID

        let systemOutputID = try AudioDeviceID.readDefaultSystemOutputDevice()

        let outputUID = try systemOutputID.readDeviceUID()

        let aggregateUID = UUID().uuidString

        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Tap-\(process.id)",
            kAudioAggregateDeviceUIDKey: aggregateUID,
            kAudioAggregateDeviceMainSubDeviceKey: outputUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceIsStackedKey: false,
            kAudioAggregateDeviceTapAutoStartKey: true,
            kAudioAggregateDeviceSubDeviceListKey: [
                [
                    kAudioSubDeviceUIDKey: outputUID
                ]
            ],
            kAudioAggregateDeviceTapListKey: [
                [
                    kAudioSubTapDriftCompensationKey: true,
                    kAudioSubTapUIDKey: tapDescription.uuid.uuidString,
                ]
            ],
        ]

        self.tapStreamDescription =
            try tapID.readAudioTapStreamBasicDescription()

        aggregateDeviceID = AudioObjectID.unknown
        err = AudioHardwareCreateAggregateDevice(
            description as CFDictionary,
            &aggregateDeviceID
        )
        guard err == noErr else {
            throw "Failed to create aggregate device: \(err)"
        }

        logger.debug(
            "Created aggregate device #\(self.aggregateDeviceID, privacy: .public)"
        )
    }

    func run(
        on queue: DispatchQueue,
        ioBlock: @escaping AudioDeviceIOBlock,
        invalidationHandler: @escaping InvalidationHandler
    ) throws {
        assert(activated, "\(#function) called with inactive tap!")
        assert(
            self.invalidationHandler == nil,
            "\(#function) called with tap already active!"
        )

        errorMessage = nil

        logger.debug("Run tap!")

        self.invalidationHandler = invalidationHandler

        var err = AudioDeviceCreateIOProcIDWithBlock(
            &deviceProcID,
            aggregateDeviceID,
            queue,
            ioBlock
        )
        guard err == noErr else {
            throw "Failed to create device I/O proc: \(err)"
        }

        err = AudioDeviceStart(aggregateDeviceID, deviceProcID)
        guard err == noErr else { throw "Failed to start audio device: \(err)" }
    }

    deinit { invalidate() }

}

@Observable
final class ProcessTapRecorder: AudioProcessStreamSource {

    private let queue = DispatchQueue(
        label: kProcessTapRecorder,
        qos: .userInitiated
    )
    private let logger = Logger(
        subsystem: kAppSubsystem,
        category: "\(String(describing: ProcessTapRecorder.self))"
    )

    private(set) var state = StreamState.stopped

    private(set) var audioLevelsProvider = AudioLevelsProvider()
    private let powerMeter = PowerMeter()
    private var audioMeterCancellable: AnyCancellable?

    private var tap: ProcessTap? = nil

    private var resultHandler: ((AVAudioPCMBuffer) -> Void)? = nil

    private func startAudioMetering() {
        audioMeterCancellable = Timer.publish(
            every: 0.1,
            on: .main,
            in: .common
        ).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.audioLevelsProvider.audioLevels = self.powerMeter.levels
        }
    }

    @MainActor
    func startStream(
        audioProcess: AudioProcess,
        resultHandler: @escaping (AVAudioPCMBuffer) -> Void
    ) async -> Error? {
        logger.debug(#function)

        if self.state == .streaming {
            logger.warning(
                "\(#function, privacy: .public) while already recording"
            )
            return ""
        }

        let tap = ProcessTap(process: audioProcess)
        if !tap.activated {
            tap.activate()
        }

        guard var streamDescription = tap.tapStreamDescription else {
            return "Tap stream description not available."
        }

        guard let format = AVAudioFormat(streamDescription: &streamDescription)
        else {
            return "Failed to create AVAudioFormat."
        }

        logger.info("Using audio format: \(format, privacy: .public)")

        let isCaptureAllowed = self.requestCapture(tap: tap, format: format)
        if !isCaptureAllowed {
            return "Capture not allowed"
        }

        self.startAudioMetering()

        self.tap = tap
        self.state = .streaming
        self.resultHandler = resultHandler

        return nil
    }

    func requestCapture(tap: ProcessTap, format: AVAudioFormat) -> Bool {
        do {
            try tap.run(on: queue) {
                [weak self]
                inNow,
                inInputData,
                inInputTime,
                outOutputData,
                inOutputTime in
                guard let self else { return }
                guard
                    let buffer = AVAudioPCMBuffer(
                        pcmFormat: format,
                        bufferListNoCopy: inInputData,
                        deallocator: nil
                    )
                else {
                    return self.logger.error(
                        "\("Failed to create PCM buffer", privacy: .public)"
                    )
                }

                self.powerMeter.process(buffer: buffer)
                self.resultHandler?(buffer)
            } invalidationHandler: { [weak self] tap in
                guard let self else { return }
                handleInvalidation()
            }

            return true
        } catch {
            self.logger.error(
                "Failed to activate tap: \(error.localizedDescription)"
            )

            return false
        }
    }

    @MainActor
    func stopStream() {
        logger.debug(#function)

        if self.state == .stopped {
            return
        }

        self.state = .stopped
        self.audioLevelsProvider.audioLevels = AudioLevels.zero

        self.tap?.invalidate()
        self.tap = nil

        self.audioMeterCancellable?.cancel()
        self.audioMeterCancellable = nil

        self.resultHandler = nil
    }

    private func handleInvalidation() {
        if self.state == .stopped {
            return
        }

        logger.debug(#function)
    }

}
