//
//  File.swift
//  
//
//  Created by Dario Pellegrini on 09/11/23.
//

import Combine
import Foundation


@available(iOS 15.0, *)
@propertyWrapper
struct StorageDonePublished<T: Codable> {
    
    private let appStorageDoneObject: AppStorageDoneObject<T>
    
    public init(wrappedValue: [T], databaseName: String, options: [QueryOption]? = nil) {
        appStorageDoneObject = AppStorageDoneObject(databaseName: databaseName)
    }
    
    public init(wrappedValue: [T], database: StorageDoneDatabase, options: [QueryOption]?) {
        appStorageDoneObject = AppStorageDoneObject(database: database)
    }
    
    public var wrappedValue: [T] {
        get { appStorageDoneObject.state }
        mutating set {
            appStorageDoneObject.save(newValue)
        }
    }
    
    var projectedValue: Published<[T]>.Publisher {
        appStorageDoneObject.$state
    }
}

@available(iOS 15.0, *)
@propertyWrapper
struct StorageDoneOnePublished<T: Codable> {
    
    private let appStorageDoneObject: PrimaryStorageDoneObject<T>
    private let id: String
    private let firstValue: T
    
    public init(wrappedValue: T, databaseName: String, id: String = "\(T.self)") {
        self.id = id
        appStorageDoneObject = PrimaryStorageDoneObject<T>(databaseName: databaseName, id: id, defaultValue: wrappedValue)
        self.firstValue = wrappedValue
    }
    
    public init(wrappedValue: T, database: StorageDoneDatabase, id: String = "\(T.self)") {
        self.id = id
        appStorageDoneObject = PrimaryStorageDoneObject<T>(database: database, defaultValue: wrappedValue, id: id)
        self.firstValue = wrappedValue
    }
    
    public var wrappedValue: T {
        get { appStorageDoneObject.state }
        mutating set {
            appStorageDoneObject.save(newValue)
        }
    }
    
    var projectedValue: Published<T>.Publisher {
        appStorageDoneObject.$state
    }
}

@available(iOS 15.0, *)
public class PrimaryStorageDoneObject<T: Codable>: ObservableObject {
    
    @Published var state: T
    private let database: StorageDoneDatabase
    
    private let id: String
    
    let publisher: StorageDonePublisher<PrimaryStorageDoneContainer<T>>
    
    private var cancellables: [AnyCancellable] = []
    
    init(databaseName: String, defaultValue: T, id: String) {
        database = StorageDoneDatabase(name: databaseName)
        publisher = database.publisher(PrimaryStorageDoneContainer<T>.self) {
            $0.expression = "id".equal(id)
        }
        self.id = id
        do {
            let elements: [PrimaryStorageDoneContainer<T>] = try database.get() {
                $0.expression = "id".equal(id)
            }
            self.state = elements.first?.element ?? defaultValue
        } catch {
            self.state = defaultValue
        }
        configure()
    }
    
    init(database: StorageDoneDatabase, defaultValue: T, id: String) {
        self.database = database
        publisher = database.publisher(PrimaryStorageDoneContainer<T>.self) {
            $0.expression = "id".equal(id)
        }
        self.id = id
        do {
            let elements: [PrimaryStorageDoneContainer<T>] = try database.get() {
                $0.expression = "id".equal(id)
            }
            self.state = elements.first?.element ?? defaultValue
        } catch {
            self.state = defaultValue
        }
        configure()
    }
    
    init(defaultValue: T, id: String, databaseClosure: () -> StorageDoneDatabase) {
        self.database = databaseClosure()
        publisher = database.publisher(PrimaryStorageDoneContainer<T>.self) {
            $0.expression = "id".equal(id)
        }
        self.id = id
        do {
            let elements: [PrimaryStorageDoneContainer<T>] = try database.get() {
                $0.expression = "id".equal(id)
            }
            self.state = elements.first?.element ?? defaultValue
        } catch {
            self.state = defaultValue
        }
        configure()
    }
    
    init(databaseName: String, id: String, defaultValue: T) {
        database = StorageDoneDatabase(name: databaseName)
        publisher = database.publisher(PrimaryStorageDoneContainer<T>.self) {
            $0.expression = "id".equal(id)
        }
        self.id = id
        do {
            let elements: [PrimaryStorageDoneContainer<T>] = try database.get() {
                $0.expression = "id".equal(id)
            }
            self.state = elements.first?.element ?? defaultValue
        } catch {
            self.state = defaultValue
        }
        configure()
    }
    
    func configure() {
        publisher
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .sink { [weak self] in
            guard let self else { return }
                if let s = $0.last {
                    self.state = s.element
                }
        }.store(in: &cancellables)
    }
    
    func save(_ value: T) {
        Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                await MainActor.run {
                    self.state = value
                }
                try await self.database.async.insertOrUpdate(element: PrimaryStorageDoneContainer(id: id, element: value))
            } catch let e {
                print(e)
            }
        }
    }
}

