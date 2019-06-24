//
//  Queries.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 24/06/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation

extension String {
    public func equal(_ element: Any) -> ExpressionProtocol {
        return self *== element
    }
    public func notEqual(_ element: Any) -> ExpressionProtocol {
        return self *!= element
    }
    public func greaterThan<T: Numeric>(_ element: T) -> ExpressionProtocol {
        return self *> element
    }
    public func greaterThanOrEqual<T: Numeric>(_ element: T) -> ExpressionProtocol {
        return self *>= element
    }
    public func lessThan<T: Numeric>(_ element: T) -> ExpressionProtocol {
        return self *< element
    }
    public func lessThanOrEqual<T: Numeric>(_ element: T) -> ExpressionProtocol {
        return self *<= element
    }
    public func inside(_ elements: [Any]) -> ExpressionProtocol {
        return self |> elements
    }
    public func contains(_ element: Any) -> ExpressionProtocol {
        return self |< element
    }
    public func like(_ element: Any) -> ExpressionProtocol {
        return self **= element
    }
    public func regex(_ element: Any) -> ExpressionProtocol {
        return self /== element
    }
    public var isNil: ExpressionProtocol {
        return *?self
    }
    public var isNotNil: ExpressionProtocol {
        return *!self
    }
    public func greaterThan(_ date: Date) -> ExpressionProtocol {
        return self *> date.timeIntervalSinceReferenceDate
    }
    public func greaterThanOrEqual(_ date: Date) -> ExpressionProtocol {
        return self *>= date.timeIntervalSinceReferenceDate
    }
    public func lessThan(_ date: Date) -> ExpressionProtocol {
        return self *< date.timeIntervalSinceReferenceDate
    }
    public func lessThanOrEqual(_ date: Date) -> ExpressionProtocol {
        return self *<= date.timeIntervalSinceReferenceDate
    }
    public func between(_ dates: (Date, Date)) -> ExpressionProtocol {
        return self <=&&<= dates
    }
}

infix operator *==
public func *==(key: String, element: Any) -> ExpressionProtocol {
    switch (element) {
    case let value as Int:
        return Expression.property(key).equalTo(Expression.int(value))
    case let value as String:
        return Expression.property(key).equalTo(Expression.string(value))
    case let value as Bool:
        return Expression.property(key).equalTo(Expression.boolean(value))
    case let value as Float:
        return Expression.property(key).equalTo(Expression.float(value))
    case let value as Double:
        return Expression.property(key).equalTo(Expression.double(value))
    case let date as Date:
        return Expression.property(key).equalTo(Expression.double(date.timeIntervalSinceReferenceDate))
    case let value as Codable:
        if let dictionary = try? value.asDictionary() {
            let expressions = dictionary.map {
                k, v in
                "\(key).\(k)" *== v
                }.compactMap { $0 }
            return and(expressions: expressions)
        }
    default:
        break;
    }
    return Expression.property(key)
}

infix operator *!=
public func *!=(key: String, element: Any) -> ExpressionProtocol {
    switch (element) {
    case let value as Int:
        return Expression.property(key).notEqualTo(Expression.int(value))
    case let value as String:
        return Expression.property(key).notEqualTo(Expression.string(value))
    case let value as Bool:
        return Expression.property(key).notEqualTo(Expression.boolean(value))
    case let value as Float:
        return Expression.property(key).notEqualTo(Expression.float(value))
    case let value as Double:
        return Expression.property(key).notEqualTo(Expression.double(value))
    case let value as Date:
        return Expression.property(key).notEqualTo(Expression.date(value))
    case let value as Codable:
        if let dictionary = try? value.asDictionary() {
            let expressions = dictionary.map {
                k, v in
                "\(key).\(k)" *!= v
                }.compactMap { $0 }
            return and(expressions: expressions)
        }
    default:
        break;
    }
    return Expression.property(key)
}

infix operator *>=
public func *>=<T: Numeric>(key: String, element: T) -> ExpressionProtocol {
    return Expression.property(key).greaterThanOrEqualTo(Expression.value(element))
}

infix operator *>
public func *><T: Numeric>(key: String, element: T) -> ExpressionProtocol {
    return Expression.property(key).greaterThan(Expression.value(element))
}

infix operator *<=
public func *<=<T: Numeric>(key: String, element: T) -> ExpressionProtocol {
    return Expression.property(key).lessThanOrEqualTo(Expression.value(element))
}

infix operator *<
public func *<<T: Numeric>(key: String, element: T) -> ExpressionProtocol {
    return Expression.property(key).lessThan(Expression.value(element))
}

// Dates
public func *>=(key: String, date: Date) -> ExpressionProtocol {
    return Expression.property(key).greaterThanOrEqualTo(Expression.double(date.timeIntervalSinceReferenceDate))
}

public func *>(key: String, date: Date) -> ExpressionProtocol {
    return Expression.property(key).greaterThan(Expression.double(date.timeIntervalSinceReferenceDate))
}

public func *<=(key: String, date: Date) -> ExpressionProtocol {
    return Expression.property(key).lessThanOrEqualTo(Expression.double(date.timeIntervalSinceReferenceDate))
}

public func *<(key: String, date: Date) -> ExpressionProtocol {
    return Expression.property(key).lessThan(Expression.double(date.timeIntervalSinceReferenceDate))
}

// Dates bewtween
infix operator <=&&<=
public func <=&&<=(key: String, dates: (Date, Date)) -> ExpressionProtocol {
    return Expression.property(key).between(Expression.double(dates.0.timeIntervalSinceReferenceDate), and: Expression.double(dates.1.timeIntervalSinceReferenceDate))
}

// Element inside array
infix operator |>
public func |>(key: String, elements: [Any]) -> ExpressionProtocol {
    return Expression.property(key).in(elements.map {
        Expression.value($0)
    })
}

// Array contains element
infix operator |<
public func |<(key: String, element: Any) -> ExpressionProtocol {
    return ArrayFunction.contains(Expression.property(key), value: Expression.value(element))
}

// Like operator
infix operator **=
public func **=(key: String, element: Any) -> ExpressionProtocol {
    return Expression.property(key).like((Expression.value(element)))
}

// Regex
infix operator /==
public func /==(key: String, element: Any) -> ExpressionProtocol {
    return Expression.property(key).regex(Expression.value(element))
}

// Is nil
prefix operator *?
public prefix func *?(key: String) -> ExpressionProtocol {
    return Expression.property(key).isNullOrMissing()
}

// Is not nil
prefix operator *!
public prefix func *!(key: String) -> ExpressionProtocol {
    return Expression.property(key).notNullOrMissing()
}

public func and(_ expressions: ExpressionProtocol...) -> ExpressionProtocol {
    var expression = expressions[0]
    if (expressions.count > 1) {
        expressions[1..<expressions.count].forEach {
            expression = expression.and($0)
        }
    }
    return expression
}

public func or(_ expressions: ExpressionProtocol...) -> ExpressionProtocol {
    var expression = expressions[0]
    if (expressions.count > 1) {
        expressions[1..<expressions.count].forEach {
            expression = expression.or($0)
        }
    }
    return expression
}

func and(expressions: [ExpressionProtocol]) -> ExpressionProtocol {
    var expression = expressions[0]
    if (expressions.count > 1) {
        expressions[1..<expressions.count].forEach {
            expression = expression.and($0)
        }
    }
    return expression
}

func or(expressions: [ExpressionProtocol]) -> ExpressionProtocol {
    var expression = expressions[0]
    if (expressions.count > 1) {
        expressions[1..<expressions.count].forEach {
            expression = expression.or($0)
        }
    }
    return expression
}
