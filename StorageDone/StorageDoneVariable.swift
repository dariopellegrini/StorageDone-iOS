//
//  File.swift
//  
//
//  Created by Dario Pellegrini on 14/12/22.
//

import Foundation
import RxSwift

public struct StorageDoneVariable<T: Codable> {
    private let database: StorageDoneDatabase
    
    init(database: StorageDoneDatabase) {
        self.database = database
    }
    
    public var elements: [T] {
        get {
            do {
                return try database.get()
            } catch let e {
                dump("Error in elements \(e)")
                return []
            }
        }
    }
    
    @available(iOS 15, *)
    public var asyncElements: [T] {
        get async {
            do {
                return try await database.async.get()
            } catch let e {
                dump("Error in asyncElements \(e)")
                return []
            }
        }
    }
    
    @available(iOS 15, *)
    public var asyncStream: AsyncThrowingStream<[T], Error> {
        database.async.live()
    }
    
    
    public var observable: Observable<[T]> {
        database.rx.live()
    }
    
    public func accept(elements: [T], delete: Bool = false) {
        do {
            if delete == true {
                try database.deleteAllAndInsert(elements: elements)
            } else {
                try database.insertOrUpdate(elements: elements)
            }
        } catch let e {
            dump("Error in \(#function) \(e)")
        }
    }
    
    @available(iOS 15, *)
    public func acceptAsync(elements: [T], delete: Bool = false) async throws {
        do {
            if delete == true {
                try await database.async.deleteAllAndInsert(elements: elements)
            } else {
                try await database.async.insertOrUpdate(elements: elements)
            }
        } catch let e {
            dump("Error in \(#function) \(e)")
        }
    }
    
    public func elements(_ advancedQuery: (AdvancedQuery) -> ()) -> [T] {
        do {
            return try database.get(using: advancedQuery)
        } catch let e {
            dump("Error in elements \(e)")
            return []
        }
    }
    
    @available(iOS 15, *)
    public func asyncElements(_ advancedQuery: @escaping (AdvancedQuery) -> ()) async -> [T] {
        do {
            return try await database.async.get(advancedQuery)
        } catch let e {
            dump("Error in elements \(e)")
            return []
        }
    }
    
    public func observable(_ advancedQuery: @escaping (AdvancedQuery) -> ()) -> Observable<[T]> {
        database.rx.live(advancedQuery)
    }
    
    @available(iOS 15, *)
    public func asyncStream(_ advancedQuery: @escaping (AdvancedQuery) -> ()) -> AsyncThrowingStream<[T], Error> {
        database.async.live(advancedQuery)
    }
    
    public func elements(_ queryOptions: [QueryOption]) -> [T] {
        do {
            return try database.get(queryOptions)
        } catch let e {
            dump("Error in elements \(e)")
            return []
        }
    }
    
    @available(iOS 15, *)
    public func asyncElements(_ queryOptions: [QueryOption]) async -> [T] {
        do {
            return try await database.async.get(queryOptions)
        } catch let e {
            dump("Error in elements \(e)")
            return []
        }
    }
    
    public func observable(_ queryOptions: [QueryOption]) -> Observable<[T]> {
        database.rx.live(queryOptions)
    }
    
    @available(iOS 15, *)
    public func asyncStream(_ queryOptions: [QueryOption]) -> AsyncThrowingStream<[T], Error> {
        database.async.live(queryOptions)
    }
    
    public func elements(_ queryOptions: QueryOption...) -> [T] {
        elements(queryOptions)
    }
    
    @available(iOS 15, *)
    public func asyncElements(_ queryOptions: QueryOption...) async -> [T] {
        await asyncElements(queryOptions)
    }
    
    public func observable(_ queryOptions: QueryOption...) -> Observable<[T]> {
        observable(queryOptions)
    }
    
    @available(iOS 15, *)
    public func asyncStream(_ queryOptions: QueryOption...) -> AsyncThrowingStream<[T], Error> {
        asyncStream(queryOptions)
    }
}

extension StorageDoneDatabase {
    public func variable<T: Codable>() -> StorageDoneVariable<T> {
        StorageDoneVariable(database: self)
    }
}
