//
//  Operators.swift
//  Unisono
//
//  Created by Dario Pellegrini on 10/05/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import Foundation
import MongoSwift

prefix operator <-
prefix func <-<T: Decodable>(database: Database) -> [T] {
    return (try? database.get()) ?? []
}

infix operator <-
func <-<T: Decodable>(query: Document, database: Database) -> [T] {
    do {
        return try database.get(query: query)
    } catch let e {
        print("Database operator error: ", e)
        return []
    }
}

infix operator +=
func +=<T: Encodable>(database: Database, element: T) {
    do {
        try database.insertOrUpdate(element: element)
    } catch let e {
        print("Database operator error: ", e)
    }
}

func +=<T: Encodable>(database: Database, elements: [T]) {
    do {
        try database.insertOrUpdate(elements: elements)
    } catch let e {
        print("Database operator error: ", e)
    }
}

infix operator -=
func -=<T: Encodable>(database: Database, element: T) {
    do {
        try database.delete(element: element)
    } catch let e {
        print("Database operator error: ", e)
    }
}

func -=<T: Encodable>(database: Database, elements: [T]) {
    do {
        try database.delete(elements: elements)
    } catch let e {
        print("Database operator error: ", e)
    }
}
