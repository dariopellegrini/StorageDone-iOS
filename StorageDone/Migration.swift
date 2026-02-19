//
//  Migration.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 29/02/24.
//  Copyright © 2024 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation

extension StorageDoneDatabase {
    
    public func migrateToRelease<T: Codable>(classType: T.Type, deleteAfterMigration: Bool = false) {
        do {
            let query = QueryBuilder
                .select(SelectResult.all(),
                        SelectResult.expression(Meta.id))
                .from(DataSource.database(self.database))
                .where(Expression.property(self.type).equalTo(Expression.string(String(describing: T.self))))
            
            var list = [T]()
            var deleteIds: [String] = []
            for result in try query.execute() {
                if let singleDictionary = result.toDictionary()[name] {
                    if let id = result.string(forKey: "id") {
                        deleteIds.append(id)
                    }
                    let jsonData = try JSONSerialization.data(withJSONObject: singleDictionary, options: .prettyPrinted)
                    if let element = try? decoder.decode(T.self, from: jsonData) {
                        list.append(element)
                    }
                }
            }

            try self.insert(elements: list)
            
            if deleteAfterMigration == true {
                try self.database.inBatch {
                    for id in deleteIds {
                        try self.database.purgeDocument(withID: id)
                    }
                }
            }
        } catch {
            print(error)
        }
    }
}
