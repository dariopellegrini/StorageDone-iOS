//
//  LiveQuery.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 08/07/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift

public struct LiveQuery {
    
    
    let query: Query
    
    let token: ListenerToken
    
    public func cancel() {
        query.removeChangeListener(withToken: token)
    }
}
