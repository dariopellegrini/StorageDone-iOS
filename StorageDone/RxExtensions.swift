//
//  RxExtensions.swift
//  Unisono
//
//  Created by Dario Pellegrini on 10/05/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import Foundation
import RxSwift


public extension StorageDoneDatabase {
    var rx: RxWrapper<StorageDoneDatabase> {
        get { return RxWrapper(self) }
        set { }
    }
}

public extension RxWrapper where Base == StorageDoneDatabase {
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
    
    func get<T: Decodable>(filter: [String:String]) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.get(filter: filter) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func delete<T: Decodable>(type: T.Type, filter: [String:String]? = nil) -> Observable<Void> {
        return Observable.create {
            subscriber in
            do {
                if let filter = filter {
                    subscriber.onNext( try self.base.delete(type, filter: filter) )
                } else {
                    subscriber.onNext(try self.base.delete(type))
                }
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
                try self.base.delete(T.self)
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
