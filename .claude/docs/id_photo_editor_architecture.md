# IDPhotoEditor アーキテクチャ (設計意図・決定事項・宿題)

ロードマップ4-1「バラけている証明写真生成ロジックのモデル化」(PR #17) の設計記録。
**今後のセッション (Sonnet / Opus 含む) は、この領域のコードを触る前に必ず本書を読むこと。**
ここに書かれた設計判断はオーナーとの議論で確定したものであり、理由なく覆さないこと。

関連資料:

- サイズの仕様: `.claude/docs/photo_size_spec.md` (DNP 2023年5月時点)
- パスポート規格: `.claude/docs/japan_passport_photo_spec.md` (外務省)
- コーディング規範: `.claude/rules/swift.md` (**API 設計ルールとドキュメントコメントの節は本PRのレビューで確立されたオーナーの強い規範**)

---

## 1. 何を作ったか

`CreateIDPhotoViewContainer` / `EditIDPhotoViewContainer` に重複していた証明写真生成ロジック
(被写体検出・背景合成・クロップ) を、UI 非依存の `actor IDPhotoEditor` に集約した。

```swift
let idPhotoEditor: IDPhotoEditor = .init(sourceCIImage: ciImage, orientation: .up)

let painted: IDPhoto = try await idPhotoEditor.painted(with: .brown)          // 背景合成 (元画像サイズ)
let cropped: IDPhoto = try await idPhotoEditor.cropped(to: JapanIDPhotoSize.w30xh40)  // 切り抜き
```

コンセプトは「現実世界のエディタのメタファー」: エディタに写真を投げ、操作 (ペイント・クロップ) を依頼する。

### ファイル構成

- `iOS/IDPhotoEditor/` — **将来パッケージ化してプライベートリポジトリへ切り離す単位** (roadmap 4-1 後半)。
  依存は Foundation / CoreGraphics / CoreImage / Vision のみ。**UIKit / SwiftUI を import してはならない (不変条件)**
  - `IDPhotoEditor.swift` — actor 本体
  - `IDPhoto.swift` — 操作結果 (画像 + 適用済み背景色 + 適用済みクロップ矩形)
  - `IDPhotoSubject.swift` — 被写体検出結果
  - `IDPhotoBackgroundColor.swift` — 背景色 (enum)
  - `IDPhotoEditorError.swift`
  - `MeasurementSize.swift` — `Measurement<UnitLength>` ベースの寸法
  - `IDPhotoSizeSpecification/` — サイズ仕様書 (protocol + Original / FaceOccupancy / EdgeCut)
- `iOS/Entities/IDPhoto/` — アプリ層
  - `JapanIDPhotoSize.swift` — 日本の規格サイズ (enum)
  - `IDPhotoBackgroundColor+Presets.swift` — asset catalog 由来のプリセット・SwiftUI 連携
  - `IDPhotoSizeSpecification+Label.swift` — 表示名の解決 (仕様書 ID がキー)

---

## 2. コア設計

### 2.1 `actor IDPhotoEditor` — 作業画像方式のステートフルなエディタ

- **actor である理由**: 複数の SwiftUI `.task(id:)` から並行に触られる可変状態 (検出キャッシュ・作業画像) を持つため。class では危険
- **作業画像 (working image) のセマンティクス**:
  - `painted(with:)` は**常に元画像から再合成**して作業画像を差し替える → 何度色を変えても画質は劣化しない
  - `cropped(to:)` は作業画像を**変異させず**、切り抜いた `IDPhoto` を返すだけ
  - よって「ペイント → クロップ → ペイント」等、どの順番・回数で呼んでも常に「最新の背景色 × 指定サイズ」になる
  - クロップ状態 (選択中のサイズ) の記憶はコンテナ側の責務。色変更後の再クロップはコンテナが `cropped(to:)` を呼び直す
- **遅延キャッシュ**: 被写体検出結果と背景合成用マスクは独立した遅延キャッシュ。呼び出し順に制約はない
  (`painted` が先ならマスクだけ生成され、被写体検出は `cropped` / `detectedSubject()` が最初に必要としたときに走る)
- **Vision の実行**: `VNImageRequestHandler.perform` は同期かつ高負荷なので、専用の `DispatchQueue` で実行して
  Swift Concurrency の協調スレッドプールをブロックしない。
  旧 `Vision+.swift` の async ラッパーは「continuation の中で同期 perform をその場で呼ぶだけ」でスレッドを逃しておらず、削除した
- **頭頂の検出手順 (旧 VisionFrameworkHelper から継承)**: `VNDetectFaceLandmarksRequest` は頭頂座標を返さないため、
  人物セグメンテーションマスク (iOS 17+ は `VNGeneratePersonInstanceMaskRequest`、それ未満は balanced 品質の
  `VNGeneratePersonSegmentationRequest`) を `VNDetectContoursRequest` にかけ、人物輪郭の boundingBox 上端を頭頂とする。
  背景合成用マスクは iOS 17+ はインスタンスマスク共用、それ未満は accurate 品質で別生成
- **複数人物対応の拡張ポイント**: マスク生成はインスタンス選択を1箇所 (`generatePersonInstanceMaskPixelBuffer` 内の
  `IndexSet(integer: 1)`) に隔離してある。将来 `detectedPersons()` / `selectPerson(_:)` を追加するときは
  ここに選択インスタンスを渡すだけでよい (roadmap の iOS 17 対応の範囲。**本PRでは公開 API を作らないことをオーナーと合意済み**)

### 2.2 `IDPhotoSubject` — 被写体検出結果

- すべて **CoreImage 座標系 (原点は左下、単位 px、元画像 extent 基準)**
- `faceWithHairRect` (旧 detectedFaceRect 互換) / `crownY` (頭頂) / `chinY` (顎) / `eyeCenterY` (両瞳の中心、optional)
- **`eyeCenterY` を持つ理由**: 外務省パスポート規格の「髪のボリュームが大きい場合は、目から顎までの幅と同程度の幅を
  目から上側にとり、その部分を頭頂とみなす」規定のため。みなし頭頂の計算
  `deemedCrownY = min(crownY, eyeCenterY + (eyeCenterY - chinY))` は**パスポート仕様書 struct の内部で行う**
  (subject は事実だけを持ち、解釈は仕様書側)。
  ただしこの用途を `eyeCenterY` の doc コメントに書いてはならない
  (プロパティの用途を doc で規定しない、というオーナー規範。経緯はここに記録する)
- `Codable` なのは Core Data への永続化 (`DetectedSubject`) のため

### 2.3 サイズ仕様書 (`IDPhotoSizeSpecification`)

「エディタに仕様書を渡す」メタファー。クロップ矩形の計算はすべて仕様書側に閉じ、
**エディタは仕様書が返した CGRect を `ciImage.cropped(to:)` に渡すだけ** (エディタの責務を肥大化させないため。
旧 `IDPhotoSizeVariant` の「enum の case で処理側が切り抜きを分岐する」設計は柔軟性に欠けるとして廃止された)。

- `requiresSubjectDetection` が false の仕様書 (オリジナルサイズ) では Vision が一切走らない。
  **このプロパティに protocol extension のデフォルト実装を与えてはならない** (被写体検出の要否は各仕様書が
  意識して宣言すべきセマンティクスであり、デフォルトで隠さない。オーナー決定)
- 仕様書が rect を生成できない場合は throw し、エディタはそのまま rethrow する
- 実装:
  - `OriginalSizeSpecification` — 切り抜きなし。`IDPhotoSizeSpecification where Self == OriginalSizeSpecification` に
    `static var original` (SwiftUI の `ButtonStyle.bordered` 方式)
  - `FaceOccupancyIDPhotoSizeSpecification` — 標準の写り方 (顔占有率一定)。旧 `generateCroppingRect` の数式を移植。
    **カスタムサイズ (roadmap 7) もこの型で表現できる** (寸法・顔高・頭上余白がすべてパラメータ)
  - `EdgeCutIDPhotoSizeSpecification` — 派生サイズ (元サイズから下部カット (上端固定)・左右均等カット。DNP 仕様 §7)

### 2.4 `JapanIDPhotoSize` — 日本の規格サイズ

```swift
enum JapanIDPhotoSize: String {
    case w24xh30 = "jp.w24h30"   // 運転免許
    ...
}
```

- **String rawValue = 永続化 ID** (`AppliedIDPhotoSize.sizeSpecificationID`)。復元は `JapanIDPhotoSize(rawValue:)`
- enum 自身が `IDPhotoSizeSpecification` に準拠し、private な `specification` (case ごとの寸法データ選択) に委譲
- **「namespace enum に他の型の定数を寄せ集める」形 (旧 JapanIDPhotoSizes) はオーナーが明確に拒否**。
  この enum 化はオーナー選定 (A案)。詳細は `.claude/rules/swift.md` の API 設計ルール参照
- **派生サイズのベースになるサイズ (長型枠 w25xh30 / 大型ベース w50xh70) も case として宣言する (オーナー指示)**。
  標準の写り方の仕様書は private static 定数 (`w25xh30Standard` 等) に1箇所で定義し、
  ベース case 自身の `specification` と派生 case の `baseSize` の両方がそれを参照する (force cast 不要)
- 旧 `IDPhotoSizeVariant` からの変換は `init?(legacySizeVariantRawValue:)`。
  original (0) と passport (1) は enum の範囲外で、呼び出し側 (`AppliedIDPhotoSize.resolvedSizeSpecificationID`) が個別に扱う。
  旧 w25_h30 (4) はベース case の宣言に伴い `.w25xh30` へ復元できる
- パスポートの予約 ID は `JapanIDPhotoSize.reservedPassportSpecificationID` ("jp.passport")
- **UI 都合の一覧 (selectable 等) をモデルに持たせない (オーナー指示)**。
  ピッカーの選択肢は各 ViewContainer の `availableSizeSpecifications` が**アローリストで明示列挙**する
  (w35xh45 とベース2種は DNP の対象サイズ一覧に無い/誤認防止のため出さない)
- サイズ一覧は DNP 2023年5月仕様に刷新済み: 旧 40×50 / 40×55 / 50×50 は廃止。
  正方形 (25×25, 30×30)・大型 (40×60, 45×60) は「元サイズからのカット」方式に変更 (顔占有率が旧実装から変わる。承認済み)
- **w35xh45 (4.5×3.5 規格外) は定義のみでピッカー非表示**: 同寸法のパスポート規格と誤認したユーザーが
  パスポート申請に使ってしまう事故を防ぐため。パスポートサイズ対応が完了したら表示する (オーナー決定)

### 2.5 `IDPhotoBackgroundColor` — 背景色

```swift
enum IDPhotoBackgroundColor {
    case clear   // 背景合成なし
    case solid(red: Double, green: Double, blue: Double, alpha: Double, colorSpace: RGBColorSpace)
}
```

- コア層は数値 (成分 + 色空間) のみ。asset catalog 由来のプリセット (`.blue` 等)・SwiftUI 連携はアプリ層 extension
- **`colorSpace` を持つ理由**: asset catalog の色は Display P3 の可能性があり、裸の RGBA だと色空間情報が落ちて合成色がズレる。
  Core Data (`AppliedBackgroundColor.colorSpace`) にも保存する (nil = レガシー = sRGB 扱い)
- **`Identifiable`**: 成分から導出される安定 ID で同一色判定・ピッカー選択判定を行う。
  `Equatable` は自動合成ではなく **ID 比較を手書き** (色空間変換由来の浮動小数の揺れで同色が不一致になるのを防ぐ)
- 永続化成分からの復元は `init(red:green:blue:alpha:colorSpaceRawValue:)`。プリセットと同一色
  (`isSameColor(as:)` = Display P3 に変換して許容誤差つき比較) なら該当プリセットになる。alpha 0 は `.clear`
- CIColor への変換は `CIColor.init?(idPhotoBackgroundColor:)` (変換は変換先の型の init に置く)

### 2.6 エラーフロー

仕様書が throw → エディタが rethrow → **コンテナが catch してアラート表示 + 選択肢を直前の値へ戻す**。
旧実装の「`.null` を返して無言でスキップ」は失敗が不可視だったため廃止。
パスポート実装後は「この写真では規格の配置ができません」系の文言につながる。

---

## 3. Core Data (モデル v5) と移行

### 3.1 スキーマの考え方

旧 `AppliedIDPhotoFaceHeight` / `AppliedMarginsAroundFace` は「enum の仕様定数 (mm) の複製」を保存していただけで
一度も読み戻されておらず削除した。当時の意図 (Create/Edit の検出ズレ懸念・Edit 時の Vision コスト回避) は正当だったため、
**検出結果そのもの (px 座標の `IDPhotoSubject`) を `DetectedSubject` エンティティとして `SourcePhoto` に永続化**する形で正しく実現した。

- Create の保存時に検出結果を書き、Edit は `IDPhotoEditor.init(..., precomputedSubject:)` に注入
  → サイズ変更だけなら Edit で Vision が走らず、Create と結果が完全一致
- 背景色変更時のマスク生成だけは (容量的にマスクを永続化しないため) 従来どおり Vision が走る
- `DetectedSubject.detectionVersion` は検出アルゴリズム変更時に再検出へフォールバックさせる版数。
  **iOS 18 の Vision 新 API へ移行したらインクリメントすること**

### 3.2 v5 の変更点

- `AppliedIDPhotoSize`: `sizeSpecificationID: String?` を追加。`millimetersWidth / millimetersHeight` は維持
  (印刷実寸 (`IDPhotoDetailViewContainer` の AirPrint) と、廃止サイズの表示フォールバックに必要)。
  `sizeVariant: Int32` は移行元として残存 (**v6 で削除予定**)
- `AppliedBackgroundColor`: `colorSpace: String?` を追加
- `AppliedIDPhotoFaceHeight` / `AppliedMarginsAroundFace` / `CustomIDPhotoFaceSize` / `CustomMarginsAroundFace` を削除
- `CustomIDPhotoSize` を1エンティティに統合 (id / name / millimetersWidth / millimetersHeight / millimetersFaceHeight /
  millimetersCrownMargin)。**カスタムサイズ機能 (roadmap 7) のための予約であり、機能構想は維持されている。消さないこと**
- `DetectedSubject` を新設 (SourcePhoto に to-one, Cascade)

### 3.3 移行戦略: 軽量マイグレーション + 起動時バックフィル (二段階)

NSMappingModel (重量級) は避けた (ストア全体コピー・失敗時のリカバリ困難・テスト不能。
Apple 自身が iOS 17 の NSStagedMigrationManager で重量級から誘導している領域だが min target iOS 15 では使えない)。

1. v5 へ軽量マイグレーション (属性追加・エンティティ削除は lightweight で可能)
2. 起動時に `PersistenceController.backfillSizeSpecificationIDsIfNeeded()` が
   `sizeSpecificationID == nil` のレコードへ `resolvedSizeSpecificationID` を書き込む
3. 読み出しフォールバック順: `sizeSpecificationID` → 旧 `sizeVariant` からの解決 → 保存済み mm 実寸 → `.unknown`
   (`AppliedIDPhotoSize.resolvedSizeSpecificationID` / `.sizeLabel`)
4. 廃止サイズ (旧 custom / w25_h30 / w40_h50 / w40_h55 / w50_h50) は ID が nil のまま mm 実寸で表示される

**これは恒久設計ではない**: `sizeVariant` 属性とバックフィルコードは、次にモデルを触るタイミング (v6、おそらくパスポート対応時) で削除して清算する。

---

## 4. 宿題 (今後のセッションへの引き継ぎ)

| 宿題 | 対応時期 | メモ |
|---|---|---|
| `JapanPassportIDPhotoSizeSpecification` の実装 | roadmap 5 (別PR) | 下記 4.1 に設計済みアルゴリズム |
| w35xh45 と passport をピッカーに追加 | パスポート対応完了時 | 各コンテナの `availableSizeSpecifications` を変更 |
| 顔占有率 60% / 頭上余白 4mm の適正値調査 | 未定 | **現在の値は根拠のない暫定値** (`JapanIDPhotoSize` の `provisional*` 定数)。変更はデータ書き換えのみで済む |
| Core Data v6: `sizeVariant` 属性とバックフィル削除 | 次にモデルを触るとき | §3.3 |
| 複数人物の選択 API (`detectedPersons()` / `selectPerson(_:)`) | roadmap iOS 17 対応 | §2.1 の拡張ポイントに実装。UI はタップ座標→boundingBox ヒットテスト |
| `iOS/IDPhotoEditor/` のパッケージ化・切り離し | roadmap 4-1 後半 | UIKit/SwiftUI 非依存の不変条件を維持。`Measurement<UnitLength>.millimeters` 拡張 (現在 `iOS/Extensions/Foundation/`) はパッケージ側へ移す |
| 保存フロー (EXIF・ファイル保存・Core Data 登録) の UseCase 化 | roadmap 4-2 | 本PRでは構造を触っていない (両コンテナに残存) |
| 表示名の String Catalog 化 | roadmap 6 | `IDPhotoSizeSpecification+Label.swift` と `IDPhotoBackgroundColor.label` のリテラルをキーに差し替えるだけの形に集約済み |
| ロケール別サイズ一覧 | roadmap 6 | `JapanIDPhotoSize` と同様のリージョン専用型を追加 (JSON 化はしない。オーナーが撤回済み) |
| iOS 18 Vision struct API への移行 | roadmap iOS 18 対応 | `IDPhotoEditor` の private な perform ヘルパーごと差し替え、`DetectedSubject.detectionVersion` をインクリメント |
| 美肌エフェクト | roadmap 19 | `IDPhotoEditor` に関数追加する想定 (オーナーのロードマップ記載) |

### 4.1 パスポート仕様書の設計済みアルゴリズム (実装は別PR)

`.claude/docs/japan_passport_photo_spec.md` の規定 (顔寸法 34±2mm・頭上余白 4±2mm・顎下余白 7±2mm・横中心 17±2mm) に対し:

1. `deemedCrownY = min(crownY, eyeCenterY + (eyeCenterY - chinY))` でみなし頭頂を計算 (髪ボリューム大対応)
2. 顔高 (みなし頭頂〜顎) 34mm 基準でスケールを決定し、45×35mm 枠を配置
3. 枠が画像に収まらなければ許容範囲 (±2mm) 内で調整
4. それでも不可なら「縦横比の維持が難しい場合は横幅を優先」規定に従い横幅基準でスケールを再計算し、顔寸法が許容範囲か検証
5. 満たせなければ `IDPhotoEditorError.croppingRegionUnsatisfiable` を throw (コンテナがアラート表示)

パスポート固有規定はすべてこの仕様書 struct に閉じ、`IDPhotoEditor` は無変更で対応できる。

---

## 5. テスト方針

- **Vision は一切実行しない** (フレームワーク自体のテストになるため。オーナー方針)。
  `IDPhotoEditor.init` の `precomputedSubject:` / `precomputedPersonMaskCIImage:` でスタブを注入する
- 検証の柱:
  - クロップ仕様書の数式 (既知の被写体 → 期待 CGRect。旧 `generateCroppingRect` と同値であることの固定化)
  - エディタの状態遷移 (ペイント→クロップ→ペイント等の交互呼び出しで色とサイズが維持されること。ピクセルサンプリングで検証)
  - レガシー `sizeVariant` → ID の変換、廃止サイズのフォールバック
  - 背景色の ID 導出・プリセット復元・色空間をまたぐ同一色判定
- Swift Testing (`@Test` / `#expect`) を使用。XCTest の雛形は削除済み
- 注意: 旧 `TEST_HOST` はプロダクト名と食い違っておりテストが実行不能だった (修正済み)

---

## 6. 検証状態 (2026-07 時点)

実装は Linux 環境 (Claude Code リモート) で行われたため **Xcode ビルドは未検証**。手元確認の観点:

1. ビルド + テスト実行 (⌘U、Xcode 16 以降)
2. 既存レコードがある状態でのアップデート起動 (軽量マイグレーション + バックフィル)
3. 廃止サイズ (40×50 等) の履歴レコードが mm 表示されること
4. 作成画面: 色変更 → サイズ変更 → 保存 / 正方形サイズの新しい切り抜き結果
5. 編集画面: 初期シード・変更検知・(新規レコードで) サイズ変更時に Vision が走らないこと
6. クロップ失敗時のアラートと選択の復帰
