//
//  RxExtensions.swift
//  Unisono
//
//  Created by Dario Pellegrini on 10/05/2019.
//  Copyright © 2019 Dario Pellegrini. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation
import RxSwift


public extension StorageDoneDatabase {
    var rx: RxWrapper<StorageDoneDatabase> {
        get { return RxWrapper(self) }
        set { }
    }
}

public extension RxWrapper where Base == StorageDoneDatabase {
    
    // MARK: - Insert
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
    
    // MARK: - Insert or update
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
    
    // MARK: - Read
    func get<T: Decodable>() -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                print("StorageDone \(Thread.isMainThread)")
                subscriber.onNext( try self.base.get() )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func get<T: Decodable>(_ expression: ExpressionProtocol) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.get(expression) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func get<T: Decodable>(using closure: @escaping (AdvancedQuery) -> ()) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.get(using: closure) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func get<T: Decodable>(_ options: QueryOption...) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.get(options) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func get<T: Decodable>(_ options: [QueryOption]) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.get(options) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    // MARK: - Delete
    func delete<T>(type: T.Type, filter: [String:String]? = nil) -> Observable<Void> {
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
    
    func deleteAllAndInsertOrUpdate<T: Encodable>(elements: [T]) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                try self.base.delete(T.self)
                try self.base.insertOrUpdate(elements: elements)
                subscriber.onNext(elements)
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
    
    func delete<T: PrimaryKey>(elements: [T]) -> Observable<Void> {
        return Observable.create {
            subscriber in
            do {
                try self.base.delete(elements: elements)
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func delete<T>(_ type: T.Type, _ expression: ExpressionProtocol) -> Observable<Void> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.delete(type, expression) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    // MARK: - Live
    func live<T: Codable>(_ type: T.Type) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            var liveQuery: LiveQuery? = nil
            do {
                liveQuery = try self.base.live(type) {
                    subscriber.onNext($0)
                }
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create {
                liveQuery?.cancel()
            }
        }
    }
    
    func live<T: Codable>() -> Observable<[T]> {
        return self.live(T.self)
    }
    
    func live<T: Codable>(_ type: T.Type, expression: ExpressionProtocol) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            var liveQuery: LiveQuery? = nil
            do {
                liveQuery = try self.base.live(type, expression: expression) {
                    subscriber.onNext($0)
                }
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create {
                liveQuery?.cancel()
            }
        }
    }
    
    func live<T: Codable>(_ expression: ExpressionProtocol) -> Observable<[T]> {
        return self.live(T.self, expression: expression)
    }
    
    func live<T: Codable>(_ type: T.Type, using: @escaping (AdvancedQuery) -> ()) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            var liveQuery: LiveQuery? = nil
            do {
                liveQuery = try self.base.live(type, using: using) {
                    subscriber.onNext($0)
                }
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create {
                liveQuery?.cancel()
            }
        }
    }
    
    func live<T: Codable>(_ using: @escaping (AdvancedQuery) -> ()) -> Observable<[T]> {
        return self.live(T.self, using: using)
    }
    
    func live<T: Codable>(_ type: T.Type, _ options: QueryOption...) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            var liveQuery: LiveQuery? = nil
            do {
                liveQuery = try self.base.live(options) {
                    subscriber.onNext($0)
                }
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create {
                liveQuery?.cancel()
            }
        }
    }
    
    // MARK: - Search
    func search<T: Decodable>(_ text: String) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.search(text) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func search<T: Decodable>(_ text: String, closure: @escaping (AdvancedQuery) -> ()) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.search(text, using: closure) )
            } catch let e {
                subscriber.onError(e)
            }
            return Disposables.create()
        }
    }
    
    func search<T: Decodable>(_ text: String, _ options: QueryOption...) -> Observable<[T]> {
        return Observable.create {
            subscriber in
            do {
                subscriber.onNext( try self.base.search(text: text, options: options) )
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
