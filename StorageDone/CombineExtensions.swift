//
//  CombineExtensions.swift
//  StorageDone
//
//  Created by Dario Pellegrini on 23/03/23.
//  Copyright © 2023 Dario Pellegrini. All rights reserved.
//
import Combine
import CouchbaseLiteSwift
import Foundation

extension StorageDoneDatabase {
    
    @available(iOS 14.0, *)
    public func publisher<T: Codable>(_ type: T.Type, dispatchQueue: DispatchQueue? = DispatchQueue.global(qos: .utility)) -> StorageDonePublisher<T> {
        StorageDonePublisher(storageDoneDatabase: self, dispatchQueue: dispatchQueue)
    }
    
    @available(iOS 14.0, *)
    public func publisher<T: Codable>(_ type: T.Type, _ expressionProtocol: ExpressionProtocol, dispatchQueue: DispatchQueue? = DispatchQueue.global(qos: .utility)) -> StorageDonePublisher<T> {
        StorageDonePublisher(storageDoneDatabase: self, expressionProtocol: expressionProtocol, dispatchQueue: dispatchQueue)
    }
    
    @available(iOS 14.0, *)
    public func publisher<T: Codable>(_ type: T.Type, dispatchQueue: DispatchQueue? = DispatchQueue.global(qos: .utility), using: @escaping (AdvancedQuery) -> ()) -> StorageDonePublisher<T> {
        StorageDonePublisher(storageDoneDatabase: self, dispatchQueue: dispatchQueue, advancedQueryClosure: using)
    }
}

@available(iOS 14, *)
public struct StorageDonePublisher<T: Codable>: Publisher {
    // Declaring that our publisher doesn't emit any values,
    // and that it can never fail:
    public typealias Output = [T]
    public typealias Failure = Never
    
    let storageDoneDatabase: StorageDoneDatabase
    
    let expressionProtocol: ExpressionProtocol?
    let advancedQueryClosure: ((AdvancedQuery) -> ())?
    let dispatchQueue: DispatchQueue?
    
    init(storageDoneDatabase: StorageDoneDatabase, dispatchQueue: DispatchQueue? = nil) {
        self.storageDoneDatabase = storageDoneDatabase
        self.expressionProtocol = nil
        self.advancedQueryClosure = nil
        self.dispatchQueue = dispatchQueue
    }
    
    init(storageDoneDatabase: StorageDoneDatabase, expressionProtocol: ExpressionProtocol, dispatchQueue: DispatchQueue? = nil) {
        self.storageDoneDatabase = storageDoneDatabase
        self.expressionProtocol = expressionProtocol
        self.advancedQueryClosure = nil
        self.dispatchQueue = dispatchQueue
    }
    
    init(storageDoneDatabase: StorageDoneDatabase, dispatchQueue: DispatchQueue? = nil, advancedQueryClosure: @escaping (AdvancedQuery) -> ()) {
        self.storageDoneDatabase = storageDoneDatabase
        self.expressionProtocol = nil
        self.advancedQueryClosure = advancedQueryClosure
        self.dispatchQueue = dispatchQueue
    }
    
    // Combine will call this method on our publisher whenever
    // a new object started observing it. Within this method,
    // we'll need to create a subscription instance and
    // attach it to the new subscriber:
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        
        // Creating our custom subscription instance:
        let subscription = StorageDoneSubscription<S, T>(storageDoneDatabase: storageDoneDatabase)
        subscription.target = subscriber
        
        // Attaching our subscription to the subscriber:
        subscriber.receive(subscription: subscription)
        
        if let expressionProtocol {
            subscription.liveQuery = try? storageDoneDatabase.live(expressionProtocol, dispatchQueue: dispatchQueue) {
                subscription.trigger(elements: $0)
            }
        } else if let advancedQueryClosure {
            subscription.liveQuery = try? storageDoneDatabase.live(advancedQueryClosure, dispatchQueue: dispatchQueue) {
                subscription.trigger(elements: $0)
            }
        } else {
            subscription.liveQuery = try? storageDoneDatabase.live(dispatchQueue: dispatchQueue) {
                subscription.trigger(elements: $0)
            }
        }
    }
}

@available(iOS 14.0, *)
public class StorageDoneSubscription<Target: Subscriber, C: Codable>: Subscription
where Target.Input == [C] {
    
    let storageDoneDatabase: StorageDoneDatabase
    var liveQuery: LiveQuery? = nil
    
    var target: Target?
    
    init(storageDoneDatabase: StorageDoneDatabase) {
        self.storageDoneDatabase = storageDoneDatabase
    }
    
    // This subscription doesn't respond to demand, since it'll
    // simply emit events according to its underlying UIControl
    // instance, but we still have to implement this method
    // in order to conform to the Subscription protocol:
    public func request(_ demand: Subscribers.Demand) {}
    
    public func cancel() {
        // When our subscription was cancelled, we'll release
        // the reference to our target to prevent any
        // additional events from being sent to it:
        target = nil
        liveQuery?.cancel()
    }
    
    func trigger(elements: [C]) {
        // Whenever an event was triggered by the underlying
        // UIControl instance, we'll simply pass Void to our
        // target to emit that event:
        _ = target?.receive(elements)
    }
}

