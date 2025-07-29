# Splite Examples

このディレクトリには、spliteプラグインの使用例が含まれています。

## ファイル一覧

### `sample.rs` - Rust Literate Programming Example
- Rust言語での文芸プログラミングの基本例
- 複数行コメント `/*lt...*/` 形式を使用
- Markdown記法のサンプル（見出し、太字、斜体、コードブロック等）

### `sample.py` - Python Literate Programming Example  
- Python言語での文芸プログラミングの基本例
- docstring `"""lt..."""` 形式を使用
- 同様のMarkdown記法サンプル

## 使用方法

1. サンプルファイルを開く：
   ```bash
   nvim examples/sample.rs
   ```

2. Literateモードに切り替え：
   ```
   <leader>lt
   ```

3. Spread Viewを試す：
   ```
   <leader>lv
   ```

## 期待される動作

### Literateモード
- 見出し（`#`, `##`, `###`）が色分けされる
- 太字（`**text**`）がオレンジ色で表示
- 斜体（`*text*`）が斜体で表示
- コードブロック内がシンタックスハイライト

### Spread View
- 3分割画面でコードの連続表示
- スクロール同期による文脈把握