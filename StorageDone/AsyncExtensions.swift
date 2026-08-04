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

/// Every method here runs its database work on a global concurrent queue, never on the caller's
/// executor: CouchbaseLite calls are blocking, so they must stay off both the main thread and the
/// Swift Concurrency cooperative pool. Keep this invariant if the target ever moves to Swift 6 with
/// approachable concurrency — there, a plain `nonisolated` async method would start inheriting the
/// caller's isolation and run on the main actor, and these methods would need `@concurrent`.
@available(iOS 15, *)
public extension AsyncQueueWrapper where Base == StorageDoneDatabase {

    // MARK: - Insert
    func insert<T: Encodable>(element: T) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.insert(element: element)
        }
    }
    
    func insert<T: Encodable>(elements: [T]) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.insert(elements: elements)
        }
    }
    
    // MARK: - Insert or update
    func insertOrUpdate<T: Encodable & PrimaryKey>(element: T, useExistingValuesAsFallback: Bool = false) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.insertOrUpdate(element: element, useExistingValuesAsFallback: useExistingValuesAsFallback)
        }
    }
    
    func insertOrUpdate<T: Encodable & PrimaryKey>(elements: [T], useExistingValuesAsFallback: Bool = false) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.insertOrUpdate(elements: elements, useExistingValuesAsFallback: useExistingValuesAsFallback)
        }
    }
    
    // MARK: - Get
    func get<T: Codable>() async throws -> [T] {
        try await with(qos: priority.qosClass) {
            try self.base.get()
        }
    }
    
    func get<T: Codable>(_ advancedQuery: @escaping (AdvancedQuery) -> ()) async throws -> [T] {
        try await with(qos: priority.qosClass) {
            try self.base.get(using: advancedQuery)
        }
    }
    
    func get<T: Codable>(_ queryOptions: QueryOption...) async throws -> [T] {
        try await with(qos: priority.qosClass) {
            try self.base.get(queryOptions)
        }
    }
    
    func get<T: Codable>(_ queryOptions: [QueryOption]) async throws -> [T] {
        try await with(qos: priority.qosClass) {
            try self.base.get(queryOptions)
        }
    }
    
    // MARK: - Delete
    func delete<T: Codable>(_ type: T.Type) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.delete(type)
        }
    }
    
    func delete<T: Codable>(_ type: T.Type, expression: ExpressionProtocol) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.delete(type, expression)
        }
    }

    func delete<T: PrimaryKey>(element: T) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.delete(element: element)
        }
    }

    func delete<T: PrimaryKey>(elements: [T]) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.delete(elements: elements)
        }
    }

    func purgeDeletedDocuments() async throws {
        try await with(qos: priority.qosClass) {
            try self.base.purgeDeletedDocuments()
        }
    }

    // MARK: - Upsert
    func upsert<T: Encodable & PrimaryKey>(element: T) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.upsert(element: element)
        }
    }

    func upsert<T: Encodable & PrimaryKey>(elements: [T]) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.upsert(elements: elements)
        }
    }

    func deleteAllAndUpsert<T: Encodable & PrimaryKey>(element: T) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.deleteAllAndUpsert(element: element)
        }
    }

    func deleteAllAndUpsert<T: Encodable & PrimaryKey>(elements: [T]) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.deleteAllAndUpsert(elements: elements)
        }
    }

    // MARK: - Delete and insert
    func deleteAllAndInsert<T: Codable>(element: T) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.deleteAllAndInsert(element: element)
        }
    }
    
    func deleteAllAndInsert<T: Codable>(elements: [T]) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.deleteAllAndInsert(elements: elements)
        }
    }
    
    func deleteAndInsert<T: Codable>(elements: [T], expression: ExpressionProtocol) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.deleteAndInsert(elements: elements, expression: expression)
        }
    }
    
    func deleteAndInsertOrUpdate<T: Codable & PrimaryKey>(elements: [T], expression: ExpressionProtocol, useExistingValuesAsFallback: Bool = false) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.deleteAndInsertOrUpdate(elements: elements, expression: expression, useExistingValuesAsFallback: useExistingValuesAsFallback)
        }
    }

    func deleteAndInsertOrUpdate<T: Codable>(elements: [T], expression: ExpressionProtocol, useExistingValuesAsFallback: Bool = false) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.deleteAndInsertOrUpdate(elements: elements, expression: expression, useExistingValuesAsFallback: useExistingValuesAsFallback)
        }
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
        try await with(qos: priority.qosClass) {
            try self.base.batch(using: block)
        }
    }
    
    // MARK: - Files
    func save(data: Data, id: String) async throws {
        try await with(qos: priority.qosClass) {
            try self.base.save(data: data, id: id)
        }
    }
    
    func getData(id: String) async throws -> Data? {
        try await with(qos: priority.qosClass) {
            self.base.getData(id: id)
        }
    }
}

@available(iOS 15, *)
extension TaskPriority {
    /// `DispatchQoS.QoSClass` equivalent, used to run database work on the global concurrent
    /// queues instead of the cooperative pool. Compared by raw value because `TaskPriority`
    /// is a struct whose cases alias each other (`.high` == `.userInitiated`, `.low` == `.utility`).
    var qosClass: DispatchQoS.QoSClass {
        switch rawValue {
        case TaskPriority.high.rawValue: return .userInitiated
        case TaskPriority.medium.rawValue: return .default
        case TaskPriority.low.rawValue: return .utility
        case TaskPriority.background.rawValue: return .background
        default: return .default
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
