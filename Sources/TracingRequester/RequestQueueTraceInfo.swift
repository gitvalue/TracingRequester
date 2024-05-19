import Foundation

/// Requests queue trace info model
struct RequestQueueTraceInfo {
    /// Number of failed requests
    var failedRequestsCount: UInt { requestsCount - succeededRequestsCount }
    
    /// Queue identifier
    let queueId: UInt
    /// Overall number of sent requests
    let requestsCount: UInt
    /// Number of succeeded requests
    let succeededRequestsCount: UInt
}

// MARK: - Convenience

extension RequestQueueTraceInfo {
    init(queueId: UInt) {
        self.queueId = queueId
        self.succeededRequestsCount = 0
        self.requestsCount = 0
    }
}
