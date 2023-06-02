# このアプリについて

## AppStore

https://apple.co/3NYbmEz

## コンセプト

証明写真作成をより簡単に。
極力、ユーザーに面倒な作業をさせない。

## 機能概要

- 自撮り画像から人物を自動認識し、背景を指定された色で塗りつぶす
- 自撮り画像から頭の先端と顎の先端を自動認識し、指定されたサイズにトリミング
- (AirPrint 限定) 印刷時、指定されたサイズで正確に証明写真を印刷できる

## アーキテクチャについて

独自の試みで、SwiftUI が React と書き方が似ていることから、Container / Presentational アーキテクチャを採用

- `**View`: 原則として、ビューロジック のみ担当
- `**ViewContainer`: ビジネスロジックを担当

![](https://svogp.vercel.app/api?url=https://qiita.com/Uhucream/items/0453f667f128c6d185b9)

