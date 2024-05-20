import Foundation
import XCTest
@testable import TracingRequester

final class TracingRequesterTests: XCTestCase {
    private var transport: TransportMock!
    private var subject: Requester!
    
    override func setUp() async throws {
        try await super.setUp()
        transport = TransportMock()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        transport = nil
        subject = nil
    }
        
    func testLowLoad() async throws {
        // given
        // standard requester and low load
        let numberOfRequests: UInt = 3
        subject = Requester(transport: transport, maxConcurrent: numberOfRequests * 2)
        
        // when
        // number of requests is less then maximum concurrent capacity
        transport.sendBytesDataVoidClosure = { _ in
            try await Task.sleep(for: .milliseconds(100))
        }
                
        async let requestsFinished: Void = withThrowingTaskGroup(of: Void.self) { [subject] group in
            for _ in 0..<numberOfRequests {
                group.addTask {
                    try await subject!.send(0)
                }
            }
        }
            
        // then
        let expectations: [XCTestExpectation] = [
            XCTestExpectation(
                description: "Number of occupied queues should equal to number of requests"
            ),
            XCTestExpectation(
                description: "Each queue should have one sent and one succeeded request"
            )
        ]
        
        await requestsFinished
        let traceInfo = await subject.traceInfo
        
        XCTAssert(traceInfo.count == numberOfRequests)
        expectations[0].fulfill()
        
        XCTAssert(traceInfo.filter { $0.requestsCount == 1 }.count == numberOfRequests)
        XCTAssert(traceInfo.filter { $0.succeededRequestsCount == 1 }.count == numberOfRequests)
        expectations[1].fulfill()
        
        await fulfillment(of: expectations, timeout: 5.0)
    }
}
