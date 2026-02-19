//
//  File.swift
//  
//
//  Created by Dario Pellegrini on 30/09/22.
//

import Foundation
import CouchbaseLiteSwift

@available(iOS 15, *)
public extension StorageDoneDatabase {
    func async(_ priority: TaskPriority) -> AsyncQueueWrapper<StorageDoneDatabase> {
        AsyncQueueWrapper(self, priority: priority)
    }
    
    var async: AsyncQueueWrapper<StorageDoneDatabase> {
        get { return AsyncQueueWrapper(self, priority: .medium) }
        set { }
    }
}

@available(iOS 15, *)
public struct AsyncQueueWrapper<Base> {
    public let base: Base
    public let priority: TaskPriority
    public init(_ base: Base, priority: TaskPriority) {
        self.base = base
        self.priority = priority
    }
}

@available(iOS 15, *)
public extension AsyncQueueWrapper where Base == StorageDoneDatabase {
    
    // MARK: - Insert
    func insert<T: Encodable>(element: T) async throws {
        try await Task(priority: priority) {
            try self.base.insert(element: element)
        }.value
    }
    
    func insert<T: Encodable>(elements: [T]) async throws {
        try await Task(priority: priority) {
            try self.base.insert(elements: elements)
        }.value
    }
    
    // MARK: - Insert or update
    func insertOrUpdate<T: Encodable & PrimaryKey>(element: T, useExistingValuesAsFallback: Bool = false) async throws {
        try await Task(priority: priority) {
            try self.base.insertOrUpdate(element: element, useExistingValuesAsFallback: useExistingValuesAsFallback)
        }.value
    }
    
    func insertOrUpdate<T: Encodable & PrimaryKey>(elements: [T], useExistingValuesAsFallback: Bool = false) async throws {
        try await Task(priority: priority) {
            try self.base.insertOrUpdate(elements: elements, useExistingValuesAsFallback: useExistingValuesAsFallback)
        }.value
    }
    
    // MARK: - Get
    func get<T: Codable>() async throws -> [T] {
        try await Task(priority: priority) {
            try self.base.get()
        }.value
    }
    
    func get<T: Codable>(_ advancedQuery: @escaping (AdvancedQuery) -> ()) async throws -> [T] {
        try await Task(priority: priority) {
            try self.base.get(using: advancedQuery)
        }.value
    }
    
    func get<T: Codable>(_ queryOptions: QueryOption...) async throws -> [T] {
        try await Task(priority: priority) {
            try self.base.get(queryOptions)
        }.value
    }
    
    func get<T: Codable>(_ queryOptions: [QueryOption]) async throws -> [T] {
        try await Task(priority: priority) {
            try self.base.get(queryOptions)
        }.value
    }
    
    // MARK: - Delete
    func delete<T: Codable>(_ type: T.Type) async throws {
        try await Task(priority: priority) {
            try self.base.delete(type)
        }.value
    }
    
    func delete<T: Codable>(_ type: T.Type, expression: ExpressionProtocol) async throws {
        try await Task(priority: priority) {
            try self.base.delete(type, expression)
        }.value
    }
    
    func deleteAllAndInsert<T: Codable>(element: T) async throws {
        try await Task(priority: priority) {
            try self.base.deleteAllAndInsert(element: element)
        }.value
    }
    
    func deleteAllAndInsert<T: Codable>(elements: [T]) async throws {
        try await Task(priority: priority) {
            try self.base.deleteAllAndInsert(elements: elements)
        }.value
    }
    
    func deleteAndInsert<T: Codable>(elements: [T], expression: ExpressionProtocol) async throws {
        try await Task(priority: priority) {
            try self.base.deleteAndInsert(elements: elements, expression: expression)
        }.value
    }
    
    func deleteAndInsertOrUpdate<T: Codable>(elements: [T], expression: ExpressionProtocol, useExistingValuesAsFallback: Bool = false) async throws {
        try await Task(priority: priority) {
            try self.base.deleteAndInsertOrUpdate(elements: elements, expression: expression, useExistingValuesAsFallback: useExistingValuesAsFallback)
        }.value
    }

    // MARK: - Live
    func live<T: Codable>() -> AsyncThrowingStream<[T], Error> {
        AsyncThrowingStream { continuation in
            do {
                let liveQuery = try self.base.live {
                    continuation.yield($0)
                }
                continuation.onTermination = { @Sendable status in
                    liveQuery.cancel()
                }
            } catch let e {
                continuation.finish(throwing: e)
            }
        }
    }
    
    func live<T: Codable>(_ queryOptions: [QueryOption]) -> AsyncThrowingStream<[T], Error> {
        AsyncThrowingStream { continuation in
            do {
                let liveQuery = try self.base.live(queryOptions) {
                    continuation.yield($0)
                }
                continuation.onTermination = { @Sendable status in
                    liveQuery.cancel()
                }
            } catch let e {
                continuation.finish(throwing: e)
            }
        }
    }
    
    func live<T: Codable>(_ queryOptions: QueryOption...) -> AsyncThrowingStream<[T], Error> {
        live(queryOptions)
    }
    
    func live<T: Codable>(_ advancedQuery: @escaping (AdvancedQuery) -> ()) -> AsyncThrowingStream<[T], Error> {
        AsyncThrowingStream { continuation in
            do {
                let liveQuery = try self.base.live(advancedQuery) {
                    continuation.yield($0)
                }
                continuation.onTermination = { @Sendable status in
                    liveQuery.cancel()
                }
            } catch let e {
                continuation.finish(throwing: e)
            }
        }
    }
    
    // MARK: - Batch
    func batch(_ block: @escaping () throws -> ()) async throws {
        try await Task(priority: priority) {
            try self.base.batch(using: block)
        }.value
    }
    
    // MARK: - Files
    func save(data: Data, id: String) async throws {
        try await Task(priority: priority) {
            try self.base.save(data: data, id: id)
        }.value
    }
    
    func getData(id: String) async throws -> Data? {
        await Task(priority: priority) {
            self.base.getData(id: id)
        }.value
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
