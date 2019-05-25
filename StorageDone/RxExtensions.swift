//
//  RxExtensions.swift
//  Unisono
//
//  Created by Dario Pellegrini on 10/05/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import Foundation
import MongoSwift
import RxSwift


public extension Database {
    var rx: RxWrapper<Database> {
        get { return RxWrapper(self) }
        set { }
    }
    
    func rxInsert<T: Encodable>(element: T) -> Observable<T> {
        return Observable.create {
            subscriber in
            do {
                try self.insert(element: element)
                subscriber.onNext(element)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func rxInsert<T: Encodable>(elements: [T]) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                try self.insert(elements: elements)
                subscriber.onNext(elements)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func rxInsertOrUpdate<T: Encodable>(element: T) -> Observable<T> {
        return Observable.create {
            subscriber in
            do {
                try self.insertOrUpdate(element: element)
                subscriber.onNext(element)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func rxInsertOrUpdate<T: Encodable>(elements: [T]) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                try self.insertOrUpdate(elements: elements)
                subscriber.onNext(elements)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func rxGet<T: Decodable>() -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.get() )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func rxget<T: Decodable>(query: Document) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.get(query: query) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func rxDelete<T: Decodable>(type: T.Type, filter: Document) -> Observable<Void> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.delete(type: type, filter: filter) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func rxDeleteAllAndInsert<T: Encodable>(elements: [T]) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                try self.delete(type: T.self, filter: [:])
                try self.insert(elements: elements)
                subscriber.onNext(elements)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
}

public extension RxWrapper where Base == Database {
    func insert<T: Encodable>(element: T) -> Observable<T> {
        return Observable.create {
            subscriber in
            do {
                try self.base.insert(element: element)
                subscriber.onNext(element)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func insert<T: Encodable>(elements: [T]) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                try self.base.insert(elements: elements)
                subscriber.onNext(elements)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func insertOrUpdate<T: Encodable>(element: T) -> Observable<T> {
        return Observable.create {
            subscriber in
            do {
                try self.base.insertOrUpdate(element: element)
                subscriber.onNext(element)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func insertOrUpdate<T: Encodable>(elements: [T]) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                try self.base.insertOrUpdate(elements: elements)
                subscriber.onNext(elements)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func get<T: Decodable>() -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.get() )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func get<T: Decodable>(query: Document) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.get(query: query) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func delete<T: Decodable>(type: T.Type, filter: Document) -> Observable<Void> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.delete(type: type, filter: filter) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func deleteAllAndInsert<T: Encodable>(elements: [T]) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                try self.base.delete(type: T.self, filter: [:])
                try self.base.insert(elements: elements)
                subscriber.onNext(elements)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
}

public struct RxWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}
