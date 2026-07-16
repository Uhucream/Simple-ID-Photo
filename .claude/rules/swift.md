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

## API 設計ルール

Apple のフレームワークの API デザインを規範とする。迷ったら「Apple ならどう書くか」で決めること。Android Kotlin 的な書き方 (namespace object・ファクトリメソッド・巨大な型宣言本体) は禁止。

- namespace 用の enum に他の型の定数を寄せ集めない

  ```swift
  // 悪い例 (Kotlin の object 的な定数置き場。Apple の API にこの形は存在しない)
  enum JapanIDPhotoSizes {
      static let w24h30: FaceOccupancyIDPhotoSizeSpecification = ...
      static let w30h40: FaceOccupancyIDPhotoSizeSpecification = ...
  }

  // 良い例1: 固定の集合は String rawValue の enum にし、rawValue を永続化 ID に使う
  enum JapanIDPhotoSize: String {
      case w24xh30 = "jp.w24h30"
      case w30xh40 = "jp.w30h40"
  }

  // 良い例2: 自分自身の型の static として生やす (UTType.jpeg 方式)
  extension UTType {
      static let jpeg: UTType = ...
  }

  // 良い例3: プロトコルの既定インスタンスは where Self == に生やす (SwiftUI の ButtonStyle.bordered 方式)
  extension IDPhotoSizeSpecification where Self == OriginalSizeSpecification {
      static var original: OriginalSizeSpecification { .init() }
  }
  ```

- 型の変換は変換先の型の init (convenience init) として書く。`fromX()` / `parseToX()` / `toX()` のようなファクトリ・変換メソッドは作らない

  ```swift
  // 良い例
  extension CIColor {
      convenience init?(idPhotoBackgroundColor: IDPhotoBackgroundColor)
  }

  // 悪い例
  extension IDPhotoBackgroundColor {
      var ciColor: CIColor? { ... }          // 変換プロパティ
      static func fromStoredComponents(...)  // ファクトリメソッド
  }
  ```

- 型宣言本体は最小限にし、プロトコル準拠・ネスト型・ヘルパーは extension に分離すること
- 単位を持つ値には `Measurement` を使うこと (`Measurement<UnitLength>` 等)
- モデル層に UI 都合のプロパティを持たせないこと (表示可否・ピッカー用の一覧・並び順などの UI ポリシーは View / ViewContainer 側の責務)
- View にフォーマット用のクロージャを渡さないこと (React のレンダープロップ的な発想を持ち込まない)。View 自身が値から表示を導出する
- 定数はアッパースネークケースではなく `static let` + キャメルケースで宣言すること (Google Swift Style Guide 準拠。過去コードにアッパースネークの定数が残っているが、真似しない)

  ```swift
  // 良い例
  static let defaultBackgroundColor: IDPhotoBackgroundColor = .blue

  // 悪い例
  static let DEFAULT_BACKGROUND_COLOR: IDPhotoBackgroundColor = .blue
  ```

- インスタンス変数を初期化しているだけの init を struct に書かないこと (memberwise init に委ねる)。特別な変換・検証がある場合のみ init を書く

## ドキュメントコメント

ドキュメントコメント (`///`) は、実装内部を知らない使用側に向けた抽象的な「ドキュメント」であって、内部実装のメモではない。

- 使用側の関心事 (何を返すか・いつ throw するか・座標系などの契約) だけを書くこと
- 内部実装の都合 (「protocol extension は stored property を持てないため computed にしている」「〜だからこの書き方をしている」等) は論外。内部向けの補足が必要なら通常コメント (`//`) を使うこと
- private メンバーの内部メモも `//` で書くこと
- 補足はカッコ書きで summary に詰め込まず、改行して Discussion 記法で書くこと

  ```swift
  // 良い例
  /// 髪を含む顔の矩形
  ///
  /// 幅は顔の boundingBox の幅、上端は crownY、下端は chinY
  let faceWithHairRect: CGRect

  // 悪い例
  /// 髪を含む顔の矩形 (幅は顔の boundingBox の幅、上端は crownY、下端は chinY)
  let faceWithHairRect: CGRect
  ```

- プロパティを「何に使うか」を doc コメントで勝手に規定しないこと (どう活かすかは使用者側が決める)。書いてよいのは事実 (値の定義・nil になる条件など) のみ。避けるべき使い方がある場合に限り `- Important:` などの警告レベルの記法で書くこと

## MARK コメント

- MARK コメントは、実装のカタマリの区切りを明確にしたい場合にのみ使う。あえて増やさないこと
- 個々の行・プロパティに貼る説明メモには使わないこと。不要な MARK はシンボル一覧のノイズになり、目的の箇所へのジャンプを妨げる。説明は通常の `//` コメントで書くこと
