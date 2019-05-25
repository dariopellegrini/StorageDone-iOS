//
//  Database.swift
//  Unisono
//
//  Created by Dario Pellegrini on 10/05/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import Foundation
import StitchCore
import StitchLocalMongoDBService
import MongoMobile
import MongoSwift

public struct Database {
    private let database: MongoDatabase
    
    public init(name: String? = nil) {
        let appId = Bundle.main.bundleIdentifier ?? "StorageDone"
        let defaultAppClient = Stitch.defaultAppClient ?? (try! Stitch.initializeDefaultAppClient(
            withClientAppID: appId))
        let databaseName = (name ?? appId).replacingOccurrences(of: ".", with: "")
        self.database = try! defaultAppClient.serviceClient(fromFactory: mongoClientFactory).db(databaseName)
    }
    
    private let decoder = JSONDecoder.init()
    private let encoder = JSONEncoder.init()
    private let collectionSuffix = "Collection"
    
    public func insert<T: Encodable>(element: T) throws {
        
        let collectionName = String(describing: T.self).lowercased() + collectionSuffix
        let collection = database.collection(collectionName)
        let json = try encoder.encode(element)
        let document = try Document.init(fromJSON: json)
        try collection.insertOne(document)
    }
    
    public func insertOrUpdate<T: Encodable>(element: T) throws {
        let collectionName = String(describing: T.self).lowercased() + collectionSuffix
        let collection = database.collection(collectionName)
        
        var query = Document()
        if let element = element as? PrimaryKey,
            let primaryKeyValue = (Mirror(reflecting: element).children.filter {
            $0.label != nil && $0.label == element.primaryKey()
        }.first?.value as? String) {
            query[element.primaryKey()] = primaryKeyValue
        }
        
        if query.isEmpty == true {
            try insert(element: element)
        } else {
            let json = try encoder.encode(element)
            let document = try Document.init(fromJSON: json)
            try collection.updateMany(filter: query, update: ["$set":document], options: UpdateOptions(upsert: true))
        }
    }
    
    // Throws even if one has error
    public func insert<T: Encodable>(elements: [T]) throws {
        let collectionName = String(describing: T.self).lowercased() + collectionSuffix
        let collection = database.collection(collectionName)
        let documents = try elements.map {
            element in
            return try Document.init(fromJSON:
                try encoder.encode(element)
            )
        }
        try collection.insertMany(documents)
    }
    
    // Throws even if one has error
    public func insertOrUpdate<T: Encodable>(elements: [T]) throws {
        let collectionName = String(describing: T.self).lowercased() + collectionSuffix
        let collection = database.collection(collectionName)
        if T.self is PrimaryKey.Type {
            try elements.forEach {
                element in
                var query = Document()
                if let element = element as? PrimaryKey,
                    let primaryKeyValue = (Mirror(reflecting: element).children.filter {
                        $0.label != nil && $0.label == element.primaryKey()
                        }.first?.value as? String) {
                    query[element.primaryKey()] = primaryKeyValue
                }
                if query.isEmpty == true {
                    try insert(element: element)
                } else {
                    let json = try encoder.encode(element)
                    let document = try Document.init(fromJSON: json)
                    try collection.updateMany(filter: query, update: ["$set":document], options: UpdateOptions(upsert: true))
                }
            }
        } else {
            try insert(elements: elements)
        }
    }
    
    public func get<T: Decodable>() throws -> [T] {
        let collectionName = String(describing: T.self).lowercased() + collectionSuffix
        let collection = database.collection(collectionName)
        return try collection.find()
            .map { $0.extendedJSON }
            .map { $0.data(using: .utf8) }
            .filter { $0 != nil }
            .map {
                data in
                return try decoder.decode(T.self, from: data!)
        }
    }
    
    public func get<T: Decodable>(query: Document) throws -> [T] {
        let collectionName = String(describing: T.self).lowercased() + collectionSuffix
        let collection = database.collection(collectionName)
        return try collection.find(query)
            .map { $0.extendedJSON }
            .map { $0.data(using: .utf8) }
            .filter { $0 != nil }
            .map {
                data in
                return try decoder.decode(T.self, from: data!)
        }
    }
    
    public func delete<T>(type: T.Type, filter: Document) throws {
        let collectionName = String(describing: T.self).lowercased() + collectionSuffix
        let collection = database.collection(collectionName)
        try collection.deleteMany(filter)
    }
    
    public func delete<T: Encodable>(element: T) throws {
        let collectionName = String(describing: T.self).lowercased() + collectionSuffix
        let collection = database.collection(collectionName)
        let json = try encoder.encode(element)
        let filter = try Document.init(fromJSON: json)
        try collection.deleteOne(filter)
    }
    
    public func delete<T: Encodable>(elements: [T]) throws {
        try elements.forEach {
            try delete(element: $0)
        }
    }
}

