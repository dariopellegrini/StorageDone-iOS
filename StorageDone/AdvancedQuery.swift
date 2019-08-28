//
//  AdvancedQuery.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 28/08/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation

public class AdvancedQuery {

    public var expression: ExpressionProtocol? = nil
    public var orderings: [OrderingProtocol]? = nil
    public var limit: Int? = nil
    public var skip: Int? = nil
}
