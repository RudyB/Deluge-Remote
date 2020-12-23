//
//  RepeatingTimer.swift
//  Deluge Remote
//
//

import Foundation

/// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
/// crashes that occur from calling resume multiple times on a timer that is
/// already resumed
class RepeatingTimer {

    let timeInterval: DispatchTimeInterval
    let timerLeeway: DispatchTimeInterval
    let timerFlags: DispatchSource.TimerFlags
    let queue: DispatchQueue?
    
    init(timeInterval: DispatchTimeInterval, leeway: DispatchTimeInterval = .nanoseconds(0), flags: DispatchSource.TimerFlags = [], queue: DispatchQueue? = nil) {
        self.timeInterval = timeInterval
        self.timerLeeway = leeway
        self.timerFlags = flags
        self.queue = queue
    }
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource(flags: timerFlags, queue: queue)
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval, leeway: self.timerLeeway)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }

    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
