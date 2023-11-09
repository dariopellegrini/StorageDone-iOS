//
//  File.swift
//  
//
//  Created by Dario Pellegrini on 20/04/23.
//
import Combine
import Foundation
import SwiftUI

@available(iOS 15.0, *)
public class AppStorageDoneObject<T: Codable>: ObservableObject {
    
    @Published var state: [T] = []
    
    private let database: StorageDoneDatabase
    
    private let publisher: StorageDonePublisher<T>
    
    private var cancellables: [AnyCancellable] = []
    
    public init(databaseName: String) {
        database = StorageDoneDatabase(name: databaseName)
        publisher = database.publisher(T.self)
        
        configure()
    }
    
    public init(database: StorageDoneDatabase) {
        self.database = database
        publisher = database.publisher(T.self)
        
        configure()
    }
    
    public init(databaseClosure: () -> StorageDoneDatabase) {
        self.database = databaseClosure()
        publisher = database.publisher(T.self)
        
        configure()
    }
    
    func configure() {
        publisher.receive(on: RunLoop.main).sink { [weak self] in
            guard let self else { return }
            self.state = $0
        }.store(in: &cancellables)
    }
    
    func save(_ value: [T]) {
        Task {
            do {
                try await database.async.deleteAllAndInsert(elements: value)
            } catch let e {
                print(e)
            }
        }
    }
}

@available(iOS 15.0, *)
@propertyWrapper
public struct AppStorageDone<T: Codable>: DynamicProperty {
    @StateObject private var appStorageDoneObject: AppStorageDoneObject<T>
    
    public init(databaseName: String) {
        let object = AppStorageDoneObject<T>(databaseName: databaseName)
        _appStorageDoneObject = StateObject(wrappedValue: object)
    }
    
    public init(database: StorageDoneDatabase) {
        let object = AppStorageDoneObject<T>(database: database)
        _appStorageDoneObject = StateObject(wrappedValue: object)
    }
    
    public var wrappedValue: [T] {
        get { appStorageDoneObject.state }
        nonmutating set {
            appStorageDoneObject.save(newValue)
        }
    }
    
    public var projectedValue: Binding<[T]> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

@available(iOS 15.0, *)
@propertyWrapper
public struct AppStorageDoneValue<T: Codable>: DynamicProperty {
    @StateObject private var appStorageDoneObject: AppStorageDoneObject<PrimaryStorageDoneContainer<T>>
    
    let id: String
    
    let firstValue: T
    
    public init(wrappedValue: T, databaseName: String, id: String? = nil) {
        let object = AppStorageDoneObject<PrimaryStorageDoneContainer<T>>(databaseName: databaseName)
        _appStorageDoneObject = StateObject(wrappedValue: object)
        self.id = id ?? "\(T.self)"
        self.firstValue = wrappedValue
    }
    
    public init(wrappedValue: T, database: StorageDoneDatabase, id: String? = nil) {
        let object = AppStorageDoneObject<PrimaryStorageDoneContainer<T>>(database: database)
        self.id = id ?? "\(T.self)"
        self.firstValue = wrappedValue
        _appStorageDoneObject = StateObject(wrappedValue: object)
    }
    
    public var wrappedValue: T {
        get { appStorageDoneObject.state.first?.element ?? firstValue }
        nonmutating set {
            appStorageDoneObject.save([PrimaryStorageDoneContainer(id: id, element: newValue)])
        }
    }
    
    public var projectedValue: Binding<T> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

struct PrimaryStorageDoneContainer<T: Codable>: Codable, PrimaryKey {
    let id: String
    let element: T
    
    func primaryKey() -> String {
        return "id"
    }
}

