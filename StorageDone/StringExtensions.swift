//
//  String+Ordering.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 24/08/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation

extension String {
    
    public var ascending: OrderingProtocol {
        return Ordering.property(self).ascending()
    }
    
    public var descending: OrderingProtocol {
        return Ordering.property(self).descending()
    }
}
