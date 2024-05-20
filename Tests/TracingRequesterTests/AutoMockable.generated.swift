// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif


@testable import TracingRequester






















class TransportMock: Transport {




    //MARK: - send

    var sendBytesDataVoidThrowableError: (any Error)?
    var sendBytesDataVoidCallsCount = 0
    var sendBytesDataVoidCalled: Bool {
        return sendBytesDataVoidCallsCount > 0
    }
    var sendBytesDataVoidReceivedBytes: (Data)?
    var sendBytesDataVoidReceivedInvocations: [(Data)] = []
    var sendBytesDataVoidClosure: ((Data) async throws -> Void)?

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
