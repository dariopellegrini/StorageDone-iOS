//
//  File.swift
//  
//
//  Created by Dario Pellegrini on 30/09/22.
//

import Foundation

@available(iOS 15, *)
public extension StorageDoneDatabase {
    func async(_ queue: DispatchQueue) -> AsyncQueueWrapper<StorageDoneDatabase> {
        AsyncQueueWrapper(self, queue: queue)
    }
    
    var async: AsyncQueueWrapper<StorageDoneDatabase> {
        get { return AsyncQueueWrapper(self, queue: DispatchQueue.global(qos: .utility)) }
        set { }
    }
}

@available(iOS 15, *)
public struct AsyncQueueWrapper<Base> {
    public let base: Base
    public let queue: DispatchQueue
    public init(_ base: Base, queue: DispatchQueue) {
        self.base = base
        self.queue = queue
    }
}

@available(iOS 15, *)
public extension AsyncQueueWrapper where Base == StorageDoneDatabase {
    
    // MARK: - Insert
    func insert<T: Encodable>(element: T) async throws {
        try await with(queue: queue) {
            try self.base.insert(element: element)
        }
    }
    
    func insert<T: Encodable>(elements: [T]) async throws {
        try await with(queue: queue) {
            try self.base.insert(elements: elements)
        }
    }
    
    // MARK: - Insert or update
    func insertOrUpdate<T: Encodable>(element: T) async throws {
        try await with(queue: queue) {
            try self.base.insertOrUpdate(element: element)
        }
    }
    
    func insertOrUpdate<T: Encodable>(elements: [T]) async throws {
        try await with(queue: queue) {
            try self.base.insertOrUpdate(elements: elements)
        }
    }
    
    // MARK: - Get
    func get<T: Codable>() async throws -> [T] {
        try await with(queue: queue) {
            try self.base.get()
        }
    }
    
    func get<T: Codable>(_ advancedQuery: @escaping (AdvancedQuery) -> ()) async throws -> [T] {
        try await with(queue: queue) {
            try self.base.get(using: advancedQuery)
        }
    }
    
    func get<T: Codable>(_ queryOptions: QueryOption...) async throws -> [T] {
        try await with(queue: queue) {
            try self.base.get(queryOptions)
        }
    }
    
    // MARK: - Delete
    func delete<T: Codable>(_ type: T.Type) async throws {
        try await with(queue: queue) {
            try self.base.delete(type)
        }
    }

    // MARK: - Files
    func save(data: Data, id: String) async throws {
        try await with(queue: queue) {
            try self.base.save(data: data, id: id)
        }
    }
    
    func getData(id: String) async throws -> Data? {
        try await with(queue: queue) {
            self.base.getData(id: id)
        }
    }
}

@available(iOS 15, *)
func with<T>(qos: DispatchQoS.QoSClass, closure: @escaping () throws -> T) async throws -> T {
    return try await withCheckedThrowingContinuation({
        (continuation: CheckedContinuation<T, Error>) in
        DispatchQueue.global(qos: qos).async {
            do {
                continuation.resume(returning: try closure())
            } catch let e {
                continuation.resume(throwing: e)
            }
        }
    })
}

@available(iOS 15, *)
func with<T>(queue: DispatchQueue, closure: @escaping () throws -> T) async throws -> T {
    return try await withCheckedThrowingContinuation({
        (continuation: CheckedContinuation<T, Error>) in
        queue.async {
            do {
                continuation.resume(returning: try closure())
            } catch let e {
                continuation.resume(throwing: e)
            }
        }
    })
}
