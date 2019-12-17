//
//  QueryOption.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 17/12/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation

public enum QueryOption {
    case expression(ExpressionProtocol)
    case orderings([OrderingProtocol])
    case ordering(OrderingProtocol)
    case limit(Int)
    case skip(Int)
}
