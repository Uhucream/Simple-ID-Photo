---
paths: "**/*.swift"
---

## コーディングルール

- 前段に何がしかの処理がある return, 関数内の変数宣言, 前段の記述から意味合いが変わる処理には必ず空行を入れること

  ```swift
  // 良い例
  let a = 1
  
  a + 1
  
  // 悪い例
  let a = 1
  a + 1
  
  // 良い例
  func test() {
      let a = 1
  
      return a
  }
  
  // 悪い例
  func test() {
      let a = 1
      return a
  }

  // いい例
  var calendar: Calendar = .init(
      identifier: .gregorian
  )
  calendar.locale = .init(identifier: "ja_JP")

  let formatStyle: Date.FormatStyle = .init(
      locale: .init(identifier: "ja_JP"),
      calendar: calendar,
      timeZone: .autoupdatingCurrent
  )

  Date.now.formatted(formatStyle.year().month().day())

  // 悪い例
  var calendar: Calendar = .init(
      identifier: .gregorian
  )
  calendar.locale = .init(identifier: "ja_JP")
  let formatStyle: Date.FormatStyle = .init(
      locale: .init(identifier: "ja_JP"),
      calendar: calendar,
      timeZone: .autoupdatingCurrent
  )
  Date.now.formatted(formatStyle.year().month().day())
  ```
  
- 型注釈は省略せず書く

  ```swift
  // 良い例
  let a: Int = 1
  
  // 悪い例
  let a = 1
  ```
  
- .init は型が明確な行の時のみ使用する

  ```swift
  // 良い例
  let a: User = .init()
  
  // 悪い例
  a = .init()
  ```
  
  - ただし、static func, static var / let, enum の case の場合は型注釈を省略しても良い
    - 例:

      ```swift
      enum UserType {
          case admin
          case user
      }

      let userType: UserType = .admin

      self.userType = .user

      self.action = .hoge()
      

      struct User {
          let name: String
          let type: UserType
      }

      extension User {
          static let admin: User = .init(name: "admin", type: .admin)
          static let user: User = .init(name: "user", type: .user)
      }

      self.user = .admin
      ```

- Bool の変数名は is, has, can, should などの接頭辞をつけること。命令形での命名は避ける。sheet の表示/非表示のフラグは is~Presented のように命名すること。

  ```swift
  // 良い例
  let isEnabled: Bool = true
  let hasPermission: Bool = false
  let canEdit: Bool = true
  let shouldShowAlert: Bool = false
  
  // 悪い例
  let enabled: Bool = true
  let permission: Bool = false
  let edit: Bool = true
  let showAlert: Bool = false
  ```

- 変数名は省略しないこと。

```swift
// 良い例
let lengthBytes
let index

// 悪い例
let lenBytes
let idx
```

- 上記以外の命名規則については [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) に従うこと
- また、[Google Swift Style Guide](https://google.github.io/swift/) も参考にすること
