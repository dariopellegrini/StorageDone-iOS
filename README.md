# StorageDone
Swift library to make easy use local document-oriented databases in iOS apps.

### Disclaimer
This library is in development, therefore should not be used in a production context for the moment. Thank you.

### Installation
To install StorageDone add this line to your Podfile

```
pod 'StorageDone', :git => 'https://github.com/dariopellegrini/StorageDone.git'
```

### Usage
StorageDone lets you save Codable models in a local database very easily.

First create a model
```swift
struct Teacher: Codable {
    let id: String
    let name: String?
    let surname: String?
    let age: Int?
    let cv: String?
}
```

Then create a `Database` object and save an instance of a Codable model in it
```swift
let teacher = Teacher(id: "id1", name: "Sarah", surname: "Jones", age: 29, cv: "https://my.cv.com/sarah_jones")
let database = Database(name: "teachers")

try? database.insert(element: teacher)
```

Reading database content will retrieve an array of the decleared model
```swift
do {
    let savedTeachers: [Teacher] = try database.get()
} catch let e {
    print(e)
}
```

Other methods allow filtering and deletion.

### Primary key
A model can implement `PrimaryKey` protocol, in order to have an attribute set as database primary key
```swift
struct Teacher: Codable, PrimaryKey {
    let id: String
    let name: String?
    let surname: String?
    let age: Int?
    let cv: String?
    
    func primaryKey() -> String {
        return "id"
    }
}
```

Primary keys come in combination with update or insert methods
```swift
let teachers = [Teacher(id: "id1", name: "Sarah", surname: "Jones", age: 29, cv: "https://my.cv.com/sarah_jones"),
                Teacher(id: "id2", name: "Silvia", surname: "Jackson", age: 29, cv: "https://my.cv.com/silvia_jackson"),
                Teacher(id: "id3", name: "John", surname: "Jacobs", age: 30, cv: "https://my.cv.com/john_jackobs")]

try? database.insertOrUpdate(elements: teachers)
```

### Operators
Database objects can use different custom operators, which wrap try-catch logic and give a more compact way to access database
```swift
// Insert or update
database ++= teachers

// Read
let teachers: [Teacher] = <-database

// Filter
let filteredTeachers: [Teacher] = ["id":"id1"] <- database


## Author

Dario Pellegrini, pellegrini.dario.1303@gmail.com

## License

StorageDone is available under the MIT license. See the LICENSE file for more info.
