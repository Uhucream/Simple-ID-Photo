# Simple ID Photo

## プロジェクト概要

証明写真作成 iOS/macOS アプリ。自撮り画像から人物を自動認識して背景を塗りつぶし、顔の位置を自動検出して指定サイズにトリミングする。AirPrint による正確なサイズ印刷にも対応。

## アーキテクチャ

SwiftUI の書き方が React に似ていることから、Container / Presentational パターンを採用。

- `**View`: ビューロジックのみ担当
- `**ViewContainer`: ビジネスロジックを担当

## コーディングルール

`.claude/rules/swift.md` を参照。

## ロードマップ

### 大型アップデート (iOS 18 対応前)

- [ ] 詳細画面での `quickLookPreview` モディファイアへの対応

### iOS 18 対応

- [ ] Photo Editing Extension への対応 (#9)
