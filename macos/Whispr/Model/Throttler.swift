import Foundation

class Throttler {
    private var lastRun: Date = Date.distantPast
    private var debounceTimer: Timer?
    private let queue: DispatchQueue
    private let interval: TimeInterval
    private let syncQueue: DispatchQueue
    
    init(_ label: String, interval: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.syncQueue = DispatchQueue(label: label)
        self.interval = interval
        self.queue = queue
    }
    
    func throttle(action: @escaping () -> Void) {
        debounceTimer?.invalidate()
        syncQueue.sync {
            let now = Date()
            let timeSinceLastRun = now.timeIntervalSince(lastRun)
            
            if timeSinceLastRun >= interval {
                lastRun = now
                queue.async(execute: action)
            } else {
                debounceTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] (timer) in
                    guard let self = self else { return }
                    self.queue.async(execute: action)
                }
            }
        }
    }
}

