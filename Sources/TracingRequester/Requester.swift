import Foundation

/// Network requests sender
actor Requester {
    private typealias Stream = AsyncStream<UInt>
    
    /// Request queues tracing information
    var traceInfo: [RequestQueueTraceInfo] { traceMap.values.map { $0 } }
    
    private var availableQueues: Set<UInt>
    private var traceMap: [UInt: RequestQueueTraceInfo] = [:]
    
    private let continuation: Stream.Continuation
    private let stream: Stream
    private let transport: any Transport
    private let maxConcurrent: UInt
    
    /// Designated initialiser
    /// - Parameters:
    ///   - transport: Network transport manager
    ///   - maxConcurrent: Maximum number of concurrent requests
    init(transport: any Transport, maxConcurrent: UInt) {
        self.transport = transport
        self.maxConcurrent = maxConcurrent
        self.availableQueues = Set(stride(from: 0, to: maxConcurrent, by: 1).map { $0 })
        let (stream, continuation) = Stream.makeStream()
        self.stream = stream
        self.continuation = continuation
    }
    
    /// Sends a request
    /// - Parameter request: Request entity
    func send<Request: Encodable>(_ request: Request) async throws {
        await waitIfNecessary()

        let queue = availableQueues.removeFirst()
        let bytes = try JSONEncoder().encode(request)
        
        do {
            try await transport.send(bytes: bytes)
            onSuccess(queue)
        } catch {
            onFailure(queue)
        }
        
        continuation.yield(queue)
    }
    
    private func waitIfNecessary() async {
        guard availableQueues.isEmpty else { return }
        
        for await queue in stream {
            if makeQueueAvailable(queue) {
                break
            }
        }
    }
    
    private func makeQueueAvailable(_ queue: UInt) -> Bool {
        if availableQueues.contains(queue) {
            return false
        } else {
            availableQueues.insert(queue)
            return true
        }
    }
    
    private func onSuccess(_ queue: UInt) {
        let traceInfo = traceMap[queue, default: RequestQueueTraceInfo(queueId: queue)]
        traceMap[queue] = RequestQueueTraceInfo(
            queueId: queue,
            requestsCount: traceInfo.requestsCount + 1,
            succeededRequestsCount: traceInfo.succeededRequestsCount + 1
        )
    }
    
    private func onFailure(_ queue: UInt) {
        let traceInfo = traceMap[queue, default: RequestQueueTraceInfo(queueId: queue)]
        traceMap[queue] = RequestQueueTraceInfo(
            queueId: queue,
            requestsCount: traceInfo.requestsCount + 1,
            succeededRequestsCount: traceInfo.succeededRequestsCount
        )
    }
}
