//
//  DatabaseCore.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 11/06/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation

public typealias CodablePrimaryKey = Codable & PrimaryKey

public struct StorageDoneDatabase {
    public let database: Database
    let name: String
    private let type = "StorageDoneType"
    
    public init(name: String = "StorageDone") {
        self.name = name
        if let path = Bundle.main.path(forResource: name, ofType: "cblite2"),
            !Database.exists(withName: name) {
            do {
                try Database.copy(fromPath: path, toDatabase: name, withConfig: nil)
            } catch {
                fatalError("Could not load pre-built database")
            }
        }
        
        // 2
        do {
            self.database = try Database(name: name)
        } catch {
            fatalError("Error opening database")
        }
    }
    
    // MARK: - Insert or upadate
    public func insertOrUpdate<T: Encodable>(element: T) throws {
        let dictionary = try element.asDictionary()
        
        var document = MutableDocument()
        if let element = element as? PrimaryKey,
            let primaryKeyValue = (Mirror(reflecting: element).children.filter {
                $0.label != nil && $0.label == element.primaryKey()
                }.first?.value) {
            document = MutableDocument(id: "\(primaryKeyValue)-\(String(describing: T.self))")
        }
        document.setData(dictionary)
        document.setString(String(describing: T.self), forKey: type)
        
        try database.saveDocument(document)
    }
    
    public func insertOrUpdate<T: Encodable>(elements: [T]) throws {
        try elements.forEach {
            try insertOrUpdate(element: $0)
        }
    }
    
    // MARK: - Insert
    public func insert<T: Encodable>(element: T) throws {
        let dictionary = try element.asDictionary()
        
        let document = MutableDocument()
        document.setData(dictionary)
        document.setString(String(describing: T.self), forKey: type)
        
        try database.saveDocument(document)
    }
    
    public func insert<T: Encodable>(elements: [T]) throws {
        try elements.forEach {
            try insert(element: $0)
        }
    }
    
    // MARK: - Get
    public func get<T: Decodable>() throws -> [T] {
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property(type)
                .equalTo(Expression.string(String(describing: T.self))))
        var list = [T]()
        let decoder = JSONDecoder()
        for result in try query.execute() {
            if let singleDictionary = result.toDictionary()[name],
                let jsonData = try? JSONSerialization.data(withJSONObject: singleDictionary, options: .prettyPrinted) {
                if let element = try? decoder.decode(T.self, from: jsonData) {
                    list.append(element)
                }
            }
        }
        return list
    }
    
    public func get<T: Decodable>(filter: [String:Any]) throws -> [T] {
        let whereExpression = filter.whereExpression(startingExpression: Expression.property(type).equalTo(Expression.string(String(describing: T.self))))
        
        let query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(whereExpression)
        
        var list = [T]()
        let decoder = JSONDecoder()
        for result in try query.execute() {
            if let singleDictionary = result.toDictionary()[name] {
                let jsonData = try JSONSerialization.data(withJSONObject: singleDictionary, options: .prettyPrinted)
                if let element = try? decoder.decode(T.self, from: jsonData) {
                    list.append(element)
                }
            }
        }
        return list
    }
    
    public func get<T: Decodable>(whereExpressions: [ExpressionProtocol]) throws -> [T] {
        var whereExpression = Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
        whereExpressions.forEach {
            whereExpression = whereExpression.and($0)
        }
        
        let query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(whereExpression)
        
        var list = [T]()
        let decoder = JSONDecoder()
        for result in try query.execute() {
            if let singleDictionary = result.toDictionary()[name] {
                let jsonData = try JSONSerialization.data(withJSONObject: singleDictionary, options: .prettyPrinted)
                if let element = try? decoder.decode(T.self, from: jsonData) {
                    list.append(element)
                }
            }
        }
        return list
    }
    
    public func get<T: Decodable>(whereExpression: ExpressionProtocol) throws -> [T] {
        let query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                .and(whereExpression))
        
        var list = [T]()
        let decoder = JSONDecoder()
        for result in try query.execute() {
            if let singleDictionary = result.toDictionary()[name] {
                let jsonData = try JSONSerialization.data(withJSONObject: singleDictionary, options: .prettyPrinted)
                if let element = try? decoder.decode(T.self, from: jsonData) {
                    list.append(element)
                }
            }
        }
        return list
    }
    
    // MARK: - Delete
    public func delete<T>(_ elementType: T.Type) throws{
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Expression.property(type)
                .equalTo(Expression.string(String(describing: T.self))))
        for result in try query.execute() {
            if let id = result.string(forKey: "id"),
                let doc = database.document(withID: id) {
                try database.deleteDocument(doc)
            }
        }
    }
    
    public func delete<T>(_ elementType: T.Type, filter: [String:Any]) throws {
        let whereExpression = filter.whereExpression(startingExpression: Expression.property(type).equalTo(Expression.string(String(describing: T.self))))
        
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(whereExpression)
        for result in try query.execute() {
            if let id = result.string(forKey: "id"),
                let doc = database.document(withID: id) {
                try database.deleteDocument(doc)
            }
        }
    }
    
    public func delete<T>(_ elementType: T.Type, whereExpressions: [ExpressionProtocol]) throws {
        var whereExpression = Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
        whereExpressions.forEach {
            whereExpression = whereExpression.and($0)
        }
        
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(whereExpression)
        
        for result in try query.execute() {
            if let id = result.string(forKey: "id"),
                let doc = database.document(withID: id) {
                try database.deleteDocument(doc)
            }
        }
    }
    
    public func delete<T>(_ elementType: T.Type, whereExpression: ExpressionProtocol) throws {
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                .and(whereExpression))
        
        for result in try query.execute() {
            if let id = result.string(forKey: "id"),
                let doc = database.document(withID: id) {
                try database.deleteDocument(doc)
            }
        }
    }
    
    public func delete<T: PrimaryKey>(element: T) throws {
        if let primaryKeyValue = (Mirror(reflecting: element).children.filter {
            $0.label != nil && $0.label == element.primaryKey()
            }.first?.value),
            let document = database.document(withID: "\(primaryKeyValue)-\(String(describing: T.self))") {
            if String(describing: T.self) == document.string(forKey: type) {
                try database.deleteDocument(document)
            }
        }
    }
    
    public func delete<T: PrimaryKey>(elements: [T]) throws {
        try elements.forEach {
            try delete(element: $0)
        }
    }
}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}
