import Foundation

/// Interface of the entity capable of transferring data through the network
/// sourcery: AutoMockable
protocol Transport: AnyObject {
    /// Sends binary data through the network asynchronously
    /// - Parameter bytes: Binary data
    func send(bytes: Data) async throws
}
