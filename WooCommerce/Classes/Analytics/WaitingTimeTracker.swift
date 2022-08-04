import Foundation
import Combine

class WaitingTimeTracker {
    private let waitingTimeout: TimeInterval

    @Published private(set) var currentState: State = .idle

    private var waitingTimer: Timer? = nil
    private var subscriptions: Set<AnyCancellable> = []

    init(waitingTimeout: TimeInterval = 30000) {
        self.waitingTimeout = waitingTimeout
        configureCurrentState()
    }

    private func configureCurrentState() {
        $currentState
            .removeDuplicates()
            .sink { [weak self] state in
                switch state {
                case .done(let waitingEndedTime):
                    self?.sendWaitingTimeToTracks(
                            waitingEndedTime: waitingEndedTime
                    )
                    self?.resetTrackerState()
                case .waiting:
                    self?.startWaitingTimer()
                case .idle:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    func onWaitingStarted(analyticsStat: WooAnalyticsStat) {
        currentState = .waiting(NSDate().timeIntervalSince1970, analyticsStat)
    }

    func onWaitingEnded() {
        guard case .waiting = currentState else {
            return
        }

        currentState = .done(NSDate().timeIntervalSince1970)
    }

    private func sendWaitingTimeToTracks(waitingEndedTime: TimeInterval) {
        guard case .waiting(let waitingStartedTime, let analyticsStat) = currentState else {
            return
        }

        let elapsedTime = waitingEndedTime - waitingStartedTime
        ServiceLocator.analytics.track(analyticsStat, withProperties: [
            "waiting_time": elapsedTime
        ])
    }

    private func startWaitingTimer() {
        waitingTimer = Timer.scheduledTimer(
                withTimeInterval: waitingTimeout,
                repeats: false) { [weak self] timer in
                    self?.resetTrackerState()
        }
    }

    private func resetTrackerState() {
        waitingTimer?.invalidate()
        waitingTimer = nil
        currentState = .idle
    }

    enum State: Equatable {
        case idle
        case waiting(TimeInterval, WooAnalyticsStat)
        case done(TimeInterval)
    }
}
