import Foundation
@testable import TracingRequester

actor TransportMock: Transport {
    var sendBytesDataVoidThrowableError: (any Error)?
    var sendBytesDataVoidCallsCount = 0
    var sendBytesDataVoidCalled: Bool {
        return sendBytesDataVoidCallsCount > 0
    }
    var sendBytesDataVoidReceivedBytes: (Data)?
    var sendBytesDataVoidReceivedInvocations: [(Data)] = []
    var sendBytesDataVoidClosure: ((Data) async throws -> Void)?

    func setBytesDataVoidClosure(_ closure: @escaping (Data) async throws -> Void) {
        sendBytesDataVoidClosure = closure
    }
    
    func send(bytes: Data) async throws {
        sendBytesDataVoidCallsCount += 1
        sendBytesDataVoidReceivedBytes = bytes
        sendBytesDataVoidReceivedInvocations.append(bytes)
        if let error = sendBytesDataVoidThrowableError {
            throw error
        }
        try await sendBytesDataVoidClosure?(bytes)
    }
}
