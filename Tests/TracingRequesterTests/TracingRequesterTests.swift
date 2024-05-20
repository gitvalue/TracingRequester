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
        
    func testNormalLoad() async throws {
        /* Given */
        
        // Standard requester and 50% load
        let numberOfRequests: UInt = 10
        subject = Requester(transport: transport, maxConcurrent: numberOfRequests * 2)
        
        /* When */
        
        // Number of requests is less than maximum concurrent capacity
        await transport.setBytesDataVoidClosure { _ in
            try await Task.sleep(for: .milliseconds(100))
        }
                
        async let requestsFinished: Void = withThrowingTaskGroup(of: Void.self) { [subject] group in
            for _ in 0..<numberOfRequests {
                group.addTask {
                    try await subject!.send(0)
                }
            }
        }
            
        /* Then */
        
        await requestsFinished
        let traceInfo = await subject.traceInfo
        
        // 1. Number of occupied queues should equal to number of requests
        XCTAssert(traceInfo.count == numberOfRequests)
        // 2. Each queue should have one sent and one succeeded request
        XCTAssert(traceInfo.filter { $0.requestsCount == 1 }.count == numberOfRequests)
        XCTAssert(traceInfo.filter { $0.succeededRequestsCount == 1 }.count == numberOfRequests)
    }
    
    func testOverload() async throws {
        /* Given */
        
        // Standard requester and overload
        let maxConcurrent: UInt = 10
        let overloadFactor: UInt = 2
        let numberOfRequests: UInt = maxConcurrent * overloadFactor
        subject = Requester(transport: transport, maxConcurrent: maxConcurrent)
        
        /* When */
        
        // Number of requests is greater than maximum concurrent capacity
        await transport.setBytesDataVoidClosure { _ in
            try await Task.sleep(for: .milliseconds(100))
        }
                
        async let requestsFinished: Void = withThrowingTaskGroup(of: Void.self) { [subject] group in
            for _ in 0..<numberOfRequests {
                group.addTask {
                    try await subject!.send(1)
                }
            }
        }
            
        /* Then */
        
        await requestsFinished
        let traceInfo = await subject.traceInfo
        
        // 1. Number of occupied queues should equal to maximum concurrent capacity
        XCTAssert(traceInfo.count == maxConcurrent)
        // 2. Overall number of sent requests should be correct
        XCTAssert(traceInfo.map { $0.requestsCount }.reduce(0, +) == numberOfRequests)
        // 3. Number of succeeded requests should equal to overall number of sent requests
        XCTAssert(traceInfo.map { $0.succeededRequestsCount }.reduce(0, +) == numberOfRequests)
        // 4. Every queue should serve 1 * `overloadFactor` requests
        XCTAssert(traceInfo.filter { $0.requestsCount == overloadFactor }.count == maxConcurrent)
    }
    
    func testPartialDataLoss() async throws {
        /* Given */
        
        // Standard requester and normal number of requests
        let numberOfRequests: UInt = 10
        subject = Requester(transport: transport, maxConcurrent: numberOfRequests * 2)
        
        /* When */
        
        // Every second request fails
        let toFail: (Int) -> (Bool) = { requestIndex in
            return requestIndex % 2 == 0
        }

        var requestIndex: Int = 0
        
        await transport.setBytesDataVoidClosure { _ in
            requestIndex += 1
            
            if toFail(requestIndex) {
                throw MockError.mock
            } else {
                try await Task.sleep(for: .milliseconds(100))
            }
        }
                
        async let requestsFinished: Void = withThrowingTaskGroup(of: Void.self) { [subject] group in
            for _ in 0..<numberOfRequests {
                group.addTask {
                    try await subject!.send(2)
                }
            }
        }
            
        /* Then */
        
        await requestsFinished
        let traceInfo = await subject.traceInfo
        
        // 1. Overall number of sent requests should be correct
        XCTAssert(traceInfo.map { $0.requestsCount }.reduce(0, +) == numberOfRequests)
        // 2. Number of succeeded requests should equal to half of the overall number of requests
        XCTAssert(traceInfo.map { $0.succeededRequestsCount }.reduce(0, +) == numberOfRequests / 2)
    }
    
    func testFullDataLoss() async throws {
        /* Given */
        
        // Standard requester and overload
        let maxConcurrent: UInt = 10
        let numberOfRequests: UInt = maxConcurrent * 2
        subject = Requester(transport: transport, maxConcurrent: maxConcurrent)
        
        /* When */
        
        // Every request fails
        await transport.setBytesDataVoidClosure { _ in
            try await Task.sleep(for: .milliseconds(100))
            throw MockError.mock
        }
                
        async let requestsFinished: Void = withThrowingTaskGroup(of: Void.self) { [subject] group in
            for _ in 0..<numberOfRequests {
                group.addTask {
                    try await subject!.send(3)
                }
            }
        }
            
        /* Then */
        
        await requestsFinished
        let traceInfo = await subject.traceInfo
        
        // 1. Overall number of sent requests should be correct
        XCTAssert(traceInfo.map { $0.requestsCount }.reduce(0, +) == numberOfRequests)
        // 2. Number of succeeded requests should equal to zero
        XCTAssert(traceInfo.map { $0.succeededRequestsCount }.reduce(0, +) == 0)
    }
    
    func testSerialRequester() async throws {
        /* Given */
        
        // Serial requester
        let maxConcurrent: UInt = 1
        let numberOfRequests: UInt = maxConcurrent * 10
        subject = Requester(transport: transport, maxConcurrent: maxConcurrent)
        
        /* When */
                  
        await transport.setBytesDataVoidClosure { _ in
            try await Task.sleep(for: .milliseconds(100))
        }
        
        // Every request is sent one after another
        async let result: [UInt] = withTaskGroup(of: UInt.self) { [subject] group in
            for i in 0..<numberOfRequests {
                group.addTask {
                    try? await subject!.send(3)
                    return i
                }
                
                try? await Task.sleep(for: .milliseconds(10))
            }
            
            return await group.map {
                $0
            }.reduce([]) { partialResult, element in
                return partialResult + [element]
            }
        }
            
        /* Then */
        
        let requestsIndices = await result
        // Requests should be served sequentially
        print(requestsIndices)
        XCTAssert(requestsIndices.sorted() == requestsIndices)
    }
}
