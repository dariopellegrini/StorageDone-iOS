//
//  DatabaseCore.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 11/06/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import CouchbaseLiteSwift.Swift
import Foundation

public typealias CodablePrimaryKey = Codable & PrimaryKey

public struct StorageDoneDatabase {
    public let database: Database
    let name: String
    private let type = "StorageDoneType"
    
    let encoder: JSONEncoder
    let decoder: JSONDecoder
    
    let defaultCollection: Collection
    
    public init(name: String = "StorageDone", encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
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
            self.encoder = encoder
            self.decoder = decoder
            self.database = try Database(name: name)
            self.defaultCollection = try database.collection(name: "default\(name)") ?? (try database.createCollection(name: "default\(name)"))
            let index = IndexBuilder.valueIndex(items:
                ValueIndexItem.expression(Expression.property(type)))
            try defaultCollection.createIndex(index, name: "\(type)Index")
        } catch {
            fatalError("Error opening database")
        }
    }
    
    // MARK: - Collections
    func collection<T>(_ type: T.Type) -> Collection {
        do {
            return try database.collection(name: String(describing: T.self), scope: String(describing: T.self)) ?? (try database.createCollection(name: String(describing: T.self), scope: String(describing: T.self)))
        } catch let e {
            fatalError(e.localizedDescription)
        }
    }
    
    // MARK: - Insert or upadate
    public func insertOrUpdate<T: Encodable>(element: T, useExistingValuesAsFallback: Bool = false) throws {
        var dictionary = try element.asDictionary(encoder: encoder)
        
        var document = MutableDocument()
        if let element = element as? PrimaryKey,
            let primaryKeyValue = (Mirror(reflecting: element).children.filter {
                $0.label != nil && $0.label == element.primaryKey()
                }.first?.value) {
            document = MutableDocument(id: "\(primaryKeyValue)-\(String(describing: T.self))")
            if useExistingValuesAsFallback == true,
               let currentDictionary = try collection(T.self).document(id: document.id)?.toDictionary() {
                currentDictionary.forEach {
                    (key, value) in
                    if dictionary[key] == nil {
                        dictionary[key] = value
                    }
                }
            }
        }
        
        document.setData(dictionary)
        document.setString(String(describing: T.self), forKey: type)
        
        try collection(T.self).save(document: document)
    }
    
    public func insertOrUpdate<T: Encodable>(elements: [T], useExistingValuesAsFallback: Bool = false) throws {
        try database.inBatch {
            try elements.forEach {
                try insertOrUpdate(element: $0, useExistingValuesAsFallback: useExistingValuesAsFallback)
            }
        }
    }
    
    // MARK: - Insert
    public func insert<T: Encodable>(element: T) throws {
        let dictionary = try element.asDictionary(encoder: encoder)
        
        let document = MutableDocument()
        document.setData(dictionary)
        
        try collection(T.self).save(document: document)
    }
    
    public func insert<T: Encodable>(elements: [T]) throws {
        try database.inBatch {
            try elements.forEach {
                try insert(element: $0)
            }
        }
    }
    
    // MARK: - Upsert
    public func upsert<T: Encodable>(element: T) throws {
        try insertOrUpdate(element: element)
    }
    
    public func upsert<T: Encodable>(elements: [T]) throws {
        try insertOrUpdate(elements: elements)
    }
    
    // MARK: - Get
    public func get<T: Decodable>() throws -> [T] {
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection(T.self)))
        
        var list = [T]()
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
            .from(DataSource.collection(collection(T.self)))
            .where(expression)
        
        var list = [T]()
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
            .from(DataSource.collection(collection(T.self)))
            .where(expression)
            .orderBy(orderings)
        
        var list = [T]()
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
            .from(DataSource.collection(collection(T.self)))

        if let from = query as? From {
            if let expression = advancedQuery.expression {
                query = from.where(expression)
            } else {
                query = from
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
    
    public func get<T: Decodable>(_ options: [QueryOption]) throws -> [T] {
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
    
    public func get<T: Decodable>(_ options: QueryOption...) throws -> [T] {
        return try get(options)
    }
    
    // MARK: - Delete
    
    public func delete<T>(_ elementType: T.Type, batch: Bool = true) throws{
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection(T.self)))
        
        if batch == true {
            try database.inBatch {
                for result in try query.execute() {
                    if let id = result.string(forKey: "id") {
                        try collection(T.self).purge(id: id)
                    }
                }
            }
        } else {
            for result in try query.execute() {
                if let id = result.string(forKey: "id") {
                    try collection(T.self).purge(id: id)
                }
            }
        }
    }
    
    public func delete<T>(_ elementType: T.Type, filter: [String:Any], batch: Bool = true) throws {
        let whereExpression = filter.whereExpression(startingExpression: Expression.property(type).equalTo(Expression.string(String(describing: T.self))))
        
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection(T.self)))
            .where(whereExpression)
        
        if batch == true {
            try database.inBatch {
                for result in try query.execute() {
                    if let id = result.string(forKey: "id") {
                        try collection(T.self).purge(id: id)
                    }
                }
            }
        } else {
            for result in try query.execute() {
                if let id = result.string(forKey: "id") {
                    try collection(T.self).purge(id: id)
                }
            }
        }
    }
    
    public func delete<T>(_ elementType: T.Type, whereExpressions: [ExpressionProtocol], batch: Bool = true) throws {
        var whereExpression = Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
        whereExpressions.forEach {
            whereExpression = whereExpression.and($0)
        }
        
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection(T.self)))
            .where(whereExpression)
        
        if batch == true {
            try database.inBatch {
                for result in try query.execute() {
                    if let id = result.string(forKey: "id") {
                        try collection(T.self).purge(id: id)
                    }
                }
            }
        } else {
            for result in try query.execute() {
                if let id = result.string(forKey: "id") {
                    try collection(T.self).purge(id: id)
                }
            }
        }
    }
    
    public func delete<T>(_ elementType: T.Type, _ expression: ExpressionProtocol, batch: Bool = true) throws {
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection(T.self)))
            .where(Expression.property(type).equalTo(Expression.string(String(describing: T.self)))
                .and(expression))
        
        if batch == true {
            try database.inBatch {
                for result in try query.execute() {
                    if let id = result.string(forKey: "id") {
                        try collection(T.self).purge(id: id)
                    }
                }
            }
        } else {
            for result in try query.execute() {
                if let id = result.string(forKey: "id") {
                    try collection(T.self).purge(id: id)
                }
            }
        }
    }
    
    public func delete<T: PrimaryKey>(element: T) throws {
        if let primaryKeyValue = (Mirror(reflecting: element).children.filter {
            $0.label != nil && $0.label == element.primaryKey()
            }.first?.value),
           let document = try collection(T.self).document(id: "\(primaryKeyValue)-\(String(describing: T.self))") {
            if String(describing: T.self) == document.string(forKey: type) {
                try collection(T.self).purge(document: document)            }
        }
    }
    
    public func delete<T: PrimaryKey>(elements: [T]) throws {
        try database.inBatch {
            try elements.forEach {
                try delete(element: $0)
            }
        }
    }
    
    // MARK: - Delete and Insert
    
    public func deleteAllAndInsert<T: Encodable>(elements: [T]) throws {
        try database.inBatch {
            try delete(T.self, batch: false)
            // Insert
            try elements.forEach {
                try insert(element: $0)
            }
        }
    }
    
    public func deleteAllAndUpsert<T: Encodable>(elements: [T]) throws {
        try database.inBatch {
            try delete(T.self, batch: false)
            // Insert
            try elements.forEach {
                try insertOrUpdate(element: $0)
            }
        }
    }
    
    public func deleteAllAndInsert<T: Encodable>(element: T) throws {
        try database.inBatch {
            try delete(T.self, batch: false)
            // Insert
            try insert(element: element)
        }
    }
    
    public func deleteAllAndUpsert<T: Encodable>(element: T) throws {
        try database.inBatch {
            try delete(T.self, batch: false)
            // Insert
            try insertOrUpdate(element: element)
        }
    }
    
    public func purgeDeletedDocuments() throws {
        let query = QueryBuilder
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(defaultCollection))
            .where(Meta.isDeleted)
        
        do {
            try database.inBatch {
                for result in try query.execute() {
                    if let id = result.string(forKey: "id") {
                        try defaultCollection.purge(id: id)
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    // MARK: - Live
    public func live<T: Codable>(_ classType: T.Type, closure: @escaping ([T]) -> ()) throws -> LiveQuery {
        let collection = collection(T.self)
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection))
        
        let token = query.addChangeListener { (change) in
            guard let results = change.results else { return }
            var list = [T]()
            for result in results {
                if let singleDictionary = result.toDictionary()[collection.name],
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
            .from(DataSource.collection(collection(T.self)))
            .where(expression)
        
        let token = query.addChangeListener(withQueue: DispatchQueue.global(qos: .utility)) { (change) in
            guard let results = change.results else { return }
            var list = [T]()
            for result in results {
                if let singleDictionary = result.toDictionary()[String(describing: T.self)],
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
            .from(DataSource.collection(collection(T.self)))
        
        if let from = query as? From {
            if let expression = advancedQuery.expression {
                query = from.where(expression)
            } else {
                query = from
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
            for result in results {
                if let singleDictionary = result.toDictionary()[String(describing: T.self)],
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
    
    public func live<T: Codable>(_ options: [QueryOption], closure: @escaping ([T]) -> ()) throws -> LiveQuery {
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
        
        return try live({
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
        }, closure: closure)
    }
    
    public func live<T: Codable>(_ options: QueryOption..., closure: @escaping ([T]) -> ()) throws -> LiveQuery {
        return try live(options, closure: closure)
    }
    
    // MARK: - Fulltext
    public func fulltextIndex<T>(_ type: T.Type, values: String...) throws {
        try collection(T.self).createIndex(IndexBuilder.fullTextIndex(items: values.map {
            FullTextIndexItem.property($0)
        }), name: "\(String(describing: T.self))-index")
    }
    
    public func search<T: Decodable>(_ text: String) throws -> [T] {
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.collection(collection(T.self)))
            .where(
                FullTextFunction.match(Expression.fullTextIndex("\(String(describing: T.self))-index"), query: "'\(text)'")
            )
        
        var list = [T]()
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
    
    public func search<T: Decodable>(_ text: String, using: (AdvancedQuery) -> ()) throws -> [T] {
        
        let advancedQuery = AdvancedQuery()
        using(advancedQuery)
        
        var query: Query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection(T.self)))
        
        if let from = query as? From {
            if let expression = advancedQuery.expression {
                query = from.where(FullTextFunction.match(Expression.fullTextIndex("\(String(describing: T.self))-index"), query: "'\(text)'")
                    .and(expression))
            } else {
                query = from.where(
                    FullTextFunction.match(Expression.fullTextIndex("\(String(describing: T.self))-index"), query: "'\(text)'")
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
    
    public func search<T: Decodable>(text: String, options: [QueryOption]) throws -> [T] {
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
        
        return try search(text) {
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
    
    public func search<T: Decodable>(_ text: String, _ options: QueryOption...) throws -> [T] {
        return try search(text: text, options: options)
    }
    
    // MARK: - Files
    public func save(data: Data, id: String) throws {
        let mutableDocument = MutableDocument(id: id)
        mutableDocument.setBlob(Blob(contentType: "application/binary", data: data), forKey: "data")
        try defaultCollection.save(document: mutableDocument)
    }
    
    public func getData(id: String) -> Data? {
        if let document = try? defaultCollection.document(id: id) {
            return document.blob(forKey: "data")?.content
        }
        return nil
    }
    
    public func deleteData(id: String) throws {
        try defaultCollection.purge(id: id)
    }
}

extension Encodable {
    public func asDictionary(encoder: JSONEncoder) throws -> [String: Any] {
        var dataElements = [String:Blob]()
        Mirror(reflecting: self).children.filter { $0.value is Data }.forEach {
            if let data = $0.value as? Data,
               let label = $0.label {
                dataElements[label] = Blob(contentType: "application/binary", data: data)
            }
        }
        encoder.dataEncodingStrategy = .custom(customDataEncoder)
        let data = try encoder.encode(self)
        var dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        dataElements.forEach {
            if dictionary?[$0.key] != nil {
                dictionary?[$0.key] = $0.value
            }
        }
        guard let resultDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return resultDictionary
    }
}

func customDataEncoder(data: Data, encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode("")
}

