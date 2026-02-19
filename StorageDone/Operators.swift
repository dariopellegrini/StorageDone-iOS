//
//  Operators.swift
//  Unisono
//
//  Created by Dario Pellegrini on 10/05/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation

prefix operator <-
public prefix func <-<T: Decodable>(database: StorageDoneDatabase) -> [T] {
    return (try? database.get()) ?? []
}

infix operator <-
public func <-<T: Decodable>(expressions: ExpressionProtocol, database: StorageDoneDatabase) -> [T] {
    do {
        return try database.get(expressions)
    } catch let e {
        print("DatabaseCore operator error: ", e)
        return []
    }
}

public func <-<T: Decodable>(closure: (AdvancedQuery) -> (), database: StorageDoneDatabase) -> [T] {
    do {
        return try database.get(using: closure)
    } catch let e {
        print("DatabaseCore operator error: ", e)
        return []
    }
}

infix operator ++=
public func ++=<T: Encodable & PrimaryKey>(database: StorageDoneDatabase, element: T) {
    do {
        try database.insertOrUpdate(element: element)
    } catch let e {
        print("DatabaseCore operator error: ", e)
    }
}

public func ++=<T: Encodable & PrimaryKey>(database: StorageDoneDatabase, elements: [T]) {
    do {
        try database.insertOrUpdate(elements: elements)
    } catch let e {
        print("DatabaseCore operator error: ", e)
    }
}

infix operator --=
public func --=<T: PrimaryKey>(database: StorageDoneDatabase, elements: [T]) {
    do {
        try database.delete(elements: elements)
    } catch let e {
        print("DatabaseCore operator error: ", e)
    }
}

public func --=<T>(database: StorageDoneDatabase, wrapper: (T.Type, ExpressionProtocol)) {
    do {
        try database.delete(T.self, wrapper.1)
    } catch let e {
        print("DatabaseCore operator error: ", e)
    }
}

