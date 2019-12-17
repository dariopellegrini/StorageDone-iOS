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
        if Database.log.file.config == nil {
            let tempFolder = NSTemporaryDirectory().appending("cbllog")
            Database.log.file.config = LogFileConfiguration(directory: tempFolder)
            Database.log.file.level = .error
        }
        
        self.name = name
        if let path = Bundle.main.path(forResource: name, ofType: "cblite2"),
            !Database.exists(withName: name) {
            do {
                try Database.copy(fromPath: path, toDatabase: name, withConfig: nil)
            } catch {
                fatalError("Could not load pre-built database")
            }
        }
        
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
        try database.inBatch {
            try elements.forEach {
                try insertOrUpdate(element: $0)
            }
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
        try database.inBatch {
            try elements.forEach {
                try insert(element: $0)
            }
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
    
    public func get<T: Decodable>(_ expression: ExpressionProtocol) throws -> [T] {
        let query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                .and(expression))
        
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
    
    public func get<T: Decodable>(_ expression: ExpressionProtocol, _ orderings: [OrderingProtocol]) throws -> [T] {
        let query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                .and(expression))
            .orderBy(orderings)
        
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
    
    // MARK: - Get with advanced queries
    public func get<T: Decodable>(using closure: (AdvancedQuery) -> ()) throws -> [T] {
        
        let advancedQuery = AdvancedQuery()
        closure(advancedQuery)
        
        var query: Query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(database))

        if let from = query as? From {
            if let expression = advancedQuery.expression {
                query = from.where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                    .and(expression))
            } else {
                query = from.where(Expression.property(type)
                    .equalTo(Expression.string(String(describing: T.self))))
            }
        }

        if let whereQuery = query as? Where,
            let orderings = advancedQuery.orderings {
            query = whereQuery.orderBy(orderings)
        }

        if let limit = advancedQuery.limit,
            let skip = advancedQuery.skip {
            if let whereQuery = query as? Where {
                query = whereQuery.limit(Expression.int(limit), offset: Expression.int(skip))
            } else if let orderQuery = query as? OrderBy {
                query = orderQuery.limit(Expression.int(limit), offset: Expression.int(skip))
            }
        } else if let limit = advancedQuery.limit {
            if let whereQuery = query as? Where {
                query = whereQuery.limit(Expression.int(limit))
            } else if let orderQuery = query as? OrderBy {
                query = orderQuery.limit(Expression.int(limit))
            }
        }
        
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
    
    public func get<T: Decodable>(_ options: QueryOption...) throws -> [T] {
        
        var expressionsArray = [ExpressionProtocol]()
        var orderingsArray = [OrderingProtocol]()
        var limitValue: Int? = nil
        var skipValue: Int? = nil
        options.forEach {
            switch $0 {
            case .expression(let expression):
                expressionsArray.append(expression)
            case .orderings(let orderings):
                orderingsArray.append(contentsOf: orderings)
            case .ordering(let ordering):
                orderingsArray.append(ordering)
            case .limit(let limit):
                limitValue = limit
            case .skip(let skip):
                skipValue = skip
            }
        }
        
        return try get {
            if (expressionsArray.count > 0) {
                $0.expression = and(expressions: expressionsArray)
            }
            
            if (orderingsArray.count > 0) {
                $0.orderings = orderingsArray
            }
            
            if let limit = limitValue {
                $0.limit = limit
                
                if let skip  = skipValue {
                    $0.skip = skip
                }
            }
        }
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
    
    public func delete<T>(_ elementType: T.Type, _ expression: ExpressionProtocol) throws {
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                .and(expression))
        
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
    
    // MARK: - Live
    public func live<T: Codable>(_ classType: T.Type, closure: @escaping ([T]) -> ()) throws -> LiveQuery {
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(Expression.property(type)
                .equalTo(Expression.string(String(describing: T.self))))
        
        let token = query.addChangeListener { (change) in
            guard let results = change.results else { return }
            var list = [T]()
            let decoder = JSONDecoder()
            for result in results {
                if let singleDictionary = result.toDictionary()[self.name],
                    let jsonData = try? JSONSerialization.data(withJSONObject: singleDictionary, options: .prettyPrinted) {
                    if let element = try? decoder.decode(T.self, from: jsonData) {
                        list.append(element)
                    }
                }
            }
            closure(list)
        }
        _ = try query.execute()
        
        return LiveQuery(query: query, token: token)
    }
    
    public func live<T: Codable>(_ closure: @escaping ([T]) -> ()) throws -> LiveQuery {
        return try live(T.self, closure: closure)
    }
    
    public func live<T: Codable>(_ classType: T.Type, expression: ExpressionProtocol, closure: @escaping ([T]) -> ()) throws -> LiveQuery {
        let query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
            .where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                .and(expression))
        
        let token = query.addChangeListener { (change) in
            guard let results = change.results else { return }
            var list = [T]()
            let decoder = JSONDecoder()
            for result in results {
                if let singleDictionary = result.toDictionary()[self.name],
                    let jsonData = try? JSONSerialization.data(withJSONObject: singleDictionary, options: .prettyPrinted) {
                    if let element = try? decoder.decode(T.self, from: jsonData) {
                        list.append(element)
                    }
                }
            }
            closure(list)
        }
        _ = try query.execute()
        
        return LiveQuery(query: query, token: token)
    }
    
    public func live<T: Codable>(_ expression: ExpressionProtocol, closure: @escaping ([T]) -> ()) throws -> LiveQuery {
        return try live(T.self, expression: expression, closure: closure)
    }
    
    // MARK: - Live with advanced queries
    public func live<T: Codable>(_ classType: T.Type, using: (AdvancedQuery) -> (), closure: @escaping ([T]) -> ()) throws -> LiveQuery {
        
        let advancedQuery = AdvancedQuery()
        using(advancedQuery)
        
        var query: Query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
        
        if let from = query as? From {
            if let expression = advancedQuery.expression {
                query = from.where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                    .and(expression))
            } else {
                query = from.where(Expression.property(type)
                    .equalTo(Expression.string(String(describing: T.self))))
            }
        }
        
        if let whereQuery = query as? Where,
            let orderings = advancedQuery.orderings {
            query = whereQuery.orderBy(orderings)
        }
        
        if let limit = advancedQuery.limit,
            let skip = advancedQuery.skip {
            if let whereQuery = query as? Where {
                query = whereQuery.limit(Expression.int(limit), offset: Expression.int(skip))
            } else if let orderQuery = query as? OrderBy {
                query = orderQuery.limit(Expression.int(limit), offset: Expression.int(skip))
            }
        } else if let limit = advancedQuery.limit{
            if let whereQuery = query as? Where {
                query = whereQuery.limit(Expression.int(limit))
            } else if let orderQuery = query as? OrderBy {
                query = orderQuery.limit(Expression.int(limit))
            }
        }
        
        let token = query.addChangeListener { (change) in
            guard let results = change.results else { return }
            var list = [T]()
            let decoder = JSONDecoder()
            for result in results {
                if let singleDictionary = result.toDictionary()[self.name],
                    let jsonData = try? JSONSerialization.data(withJSONObject: singleDictionary, options: .prettyPrinted) {
                    if let element = try? decoder.decode(T.self, from: jsonData) {
                        list.append(element)
                    }
                }
            }
            closure(list)
        }
        _ = try query.execute()
        
        return LiveQuery(query: query, token: token)
    }
    
    public func live<T: Codable>(_ using: (AdvancedQuery) -> (), closure: @escaping ([T]) -> ()) throws -> LiveQuery {
        return try live(T.self, using: using, closure: closure)
    }
    
    // MARK: - Fulltext
    public func fulltextIndex<T>(_ type: T.Type, values: String...) throws {
        try database.createIndex(IndexBuilder.fullTextIndex(items: values.map {
            FullTextIndexItem.property($0)
        }), withName: "\(String(describing: T.self))-index")
    }
    
    public func search<T: Decodable>(text: String) throws -> [T] {
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(database))
            .where(
                Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                .and(FullTextExpression.index("\(String(describing: T.self))-index").match("'\(text)'"))
        )
        
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
    
    public func search<T: Decodable>(text: String, using: (AdvancedQuery) -> ()) throws -> [T] {
        
        let advancedQuery = AdvancedQuery()
        using(advancedQuery)
        
        var query: Query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(database))
        
        if let from = query as? From {
            if let expression = advancedQuery.expression {
                query = from.where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                    .and(FullTextExpression.index("\(String(describing: T.self))-index").match("'\(text)'"))
                    .and(expression))
            } else {
                query = from.where(Expression.property(type)
                    .equalTo(Expression.string(String(describing: T.self)))
                    .and(FullTextExpression.index("\(String(describing: T.self))-index").match("'\(text)'"))
                )
            }
        }
        
        if let whereQuery = query as? Where,
            let orderings = advancedQuery.orderings {
            query = whereQuery.orderBy(orderings)
        }
        
        if let limit = advancedQuery.limit,
            let skip = advancedQuery.skip {
            if let whereQuery = query as? Where {
                query = whereQuery.limit(Expression.int(limit), offset: Expression.int(skip))
            } else if let orderQuery = query as? OrderBy {
                query = orderQuery.limit(Expression.int(limit), offset: Expression.int(skip))
            }
        } else if let limit = advancedQuery.limit{
            if let whereQuery = query as? Where {
                query = whereQuery.limit(Expression.int(limit))
            } else if let orderQuery = query as? OrderBy {
                query = orderQuery.limit(Expression.int(limit))
            }
        }
        
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

