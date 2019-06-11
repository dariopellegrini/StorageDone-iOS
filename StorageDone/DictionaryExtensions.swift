//
//  DictionaryExtensions.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 11/06/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation

extension Dictionary where Key == String {
    func whereExpression(startingExpression: ExpressionProtocol) -> ExpressionProtocol {
        var whereExpression = startingExpression
        
        self.forEach {
            (arg) in
            let (key, element) = arg
            switch (element) {
            case let value as Int:
                whereExpression = whereExpression.and(Expression.property(key).equalTo(Expression.int(value)))
            case let value as String:
                whereExpression = whereExpression.and(Expression.property(key).equalTo(Expression.string(value)))
            case let value as Bool:
                whereExpression = whereExpression.and(Expression.property(key).equalTo(Expression.boolean(value)))
            case let value as Float:
                whereExpression = whereExpression.and(Expression.property(key).equalTo(Expression.float(value)))
            case let value as Double:
                whereExpression = whereExpression.and(Expression.property(key).equalTo(Expression.double(value)))
            case let value as Date:
                whereExpression = whereExpression.and(Expression.property(key).equalTo(Expression.date(value)))
            case let value as Codable:
                if let dictionary = try? value.asDictionary() {
                    whereExpression = whereExpression.and(Expression.property(key).equalTo(Expression.dictionary(dictionary)))
                }
            default:
                break
            }
        }
        return whereExpression
    }
}
