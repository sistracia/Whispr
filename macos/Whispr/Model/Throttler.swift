import Foundation

class Throttler {
    private var lastRun: Date = Date.distantPast
    private let queue: DispatchQueue
    private let interval: TimeInterval
    private let syncQueue: DispatchQueue

    init(_ label: String, interval: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.syncQueue = DispatchQueue(label: label)
        self.interval = interval
        self.queue = queue
    }

    func throttle(action: @escaping () -> Void) {
        syncQueue.sync {
            let now = Date()
            let timeSinceLastRun = now.timeIntervalSince(lastRun)

            if timeSinceLastRun >= interval {
                lastRun = now
                queue.async(execute: action)
            }
        }
    }
}

