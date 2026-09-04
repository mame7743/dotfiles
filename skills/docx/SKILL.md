---
name: docx
description: "Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation. Word 文書（.docx / .dotx）の作成・読み取り・編集・操作が必要なときに使用します。'Word doc', 'word document', '.docx', '.dotx' のほか、目次・見出し・ページ番号・レターヘッド付きの正式文書の作成依頼、既存 .docx/.dotx からの内容抽出・再構成、画像の挿入・置換、検索置換、変更履歴（tracked changes）やコメントの操作、Word 文書への変換を伴う依頼（'report', 'memo', 'letter', 'template' など）もトリガーします。PDF・スプレッドシート・Google Docs・文書生成と無関係なコーディングには使用しないでください。"
license: Proprietary. LICENSE.txt has complete terms
---

# DOCX の作成・編集・解析

`.docx` は XML ファイルをまとめた ZIP アーカイブです。タスクに応じてアプローチを選んでください:

| タスク | アプローチ |
|---|---|
| **新規作成** | `docx`（npm）スクリプトを書く — 下記の注意点を参照 |
| **既存ドキュメントの編集** | `unzip` → `word/document.xml` を編集 → `zip`（docx-js は既存ファイルを開けない） |
| **内容の読み取り** | `pandoc -t markdown file.docx` |

> 以下のスクリプトパスは、このスキルのディレクトリからの相対パスです。

## docx-js での作成 — 注意点

`docx` はプリインストールされています — `npm install` を先に実行せず、スクリプトを書いて `require('docx')` を直接呼び出してください。その require が失敗した場合のみ `npm install docx` を実行します。モデルは API を把握していますが、落とし穴は以下のとおりです:

- **ページサイズのデフォルトは A4 です。** 米国レターサイズにするには `page: { size: { width: 12240, height: 15840 } }` を指定します（DXA; 1440 = 1インチ）。
- **横向き（Landscape）:** 縦向きの寸法と `orientation: PageOrientation.LANDSCAPE` を渡します — docx-js が内部で width/height を入れ替えます。
- **表には二重の幅指定が必要:** 表の `columnWidths` と各セルの `width` の両方を、ともに `WidthType.DXA` で設定します（PERCENTAGE は Google Docs で壊れます）。列幅の合計は表幅と一致させる必要があります。
- **表の背景色:** `ShadingType.CLEAR` を使用し、`SOLID` は絶対に使わないでください（黒く描画されます）。
- **リスト:** `•` を文字通り挿入せず、`LevelFormat.BULLET` を使った `numbering` 設定を使用してください。
- **`ImageRun` には `type:` が必要です**（`"png"`、`"jpg"`、…）。
- **`PageBreak` は `Paragraph` の中に配置する必要があります。**
- **`\n` は絶対に使わないでください** — 代わりに個別の `Paragraph` 要素を使用してください。
- **目次（TOC）:** 見出しは組み込みの `HeadingLevel.*` を使用する必要があります。カスタム見出しスタイルは `outlineLevel` を設定しないと目次に表示されません。
- **表を水平線の代わりに使わないでください** — 代わりに段落の下ボーダーを使用してください。
- **ドットリーダー / 同行右寄せ:** リテラルの `.` やスペース埋めではなく、`TextRun` 内の `PositionalTab`（`alignment: PositionalTabAlignment.RIGHT`、`leader: PositionalTabLeader.DOT`）を使用してください。

## 出力の検証

`.docx` を書き終えたら、レンダリングして目視確認してください:

```bash
python scripts/office/soffice.py --headless --convert-to pdf output.docx
pdftoppm -jpeg -r 100 output.pdf page
ls page-*.jpg   # then Read the images
```

`pdftoppm` はページ番号をページ数の桁幅までゼロ埋めします（`page-01.jpg`…`page-12.jpg`）。

## 既存ドキュメントの編集

レガシーな `.doc` ファイルは先に変換する必要があります: `python scripts/office/soffice.py --headless --convert-to docx file.doc`。

```bash
unzip -q doc.docx -d unpacked/
find unpacked -type l -delete   # strip symlink entries — docx from external parties is untrusted
python scripts/merge_runs.py unpacked/   # coalesce fragmented runs so text is findable
# edit unpacked/word/document.xml in place — do NOT reformat or pretty-print
(cd unpacked && rm -f ../out.docx && zip -Xr ../out.docx .)
python scripts/office/validate.py out.docx --original doc.docx   # XSD checks; --auto-repair fixes common issues
# redlining? add --author "<the name you redlined under>" to check every edit is tracked
```

Word はテキストを多数の `<w:r>` ランに分割します（リビジョンID、スペルチェックマーカーなど）。そのため、ドキュメント上では見えるフレーズでも、XML 上では連続した文字列として存在しないことがよくあります。`merge_runs.py` は `word/document.xml` 内の隣接する同一書式のランを、内容やレンダリングを変えずに結合します。また `.docx` を直接受け取ることもできます（`python scripts/merge_runs.py doc.docx -o merged.docx`）。

**変更履歴（Tracked changes）:** 修正箇所を記録するときは、`--author "<the name you redlined under>"` 付きで検証してください（`--original` が必要）— これにより、`<w:ins>`/`<w:del>` で囲んでいないテキスト変更を報告します。これはうっかりやりがちで、変更を反映したビューでは見えません。ランを `w:id`、`w:author`、`w:date` 属性付きの `<w:ins>`/`<w:del>` で包んでください。`<w:del>` 内ではテキスト要素は `<w:t>` ではなく `<w:delText>` です。削除された段落記号（`<w:pPr><w:rPr><w:del w:id=".." w:author=".." w:date=".."/></w:rPr></w:pPr>`）は「この段落を次の段落に結合する」ことを意味します — つまり段落を完全に削除するには、これに加えてすべてのランを `<w:del>` で包みます。`<w:del/>` は rPr の他の子要素より前に置く必要があります。その順序はスキーマで強制されています。

すべての変更履歴を承認したクリーンなコピーを作成するには: `python scripts/accept_changes.py in.docx out.docx`。

削除された段落記号を承認すると、その段落は下の段落に結合されるはずなので、ランが*すべて*削除された段落は消滅します。Word はこれを行いますが、`accept_changes.py` と `pandoc --track-changes=accept` は必ずしもそうではありません。両者とも同じ方法で失敗します — 削除されたテキストを除去しますが、空になった段落を残すため、自動番号付きリストでは孤立した空の箇条書きとして表示されます:

- `pandoc --track-changes=accept` は段落を結合しません。
- `accept_changes.py`（LibreOffice）は正しく結合しますが、削除された段落の後に空のスペーサー段落が続く場合は例外です。

どちらの表示でも空の箇条書きはそのビューの表示上の産物であり、ドキュメント自体の欠陥ではありません。段落の削除は XML で確認してください。

## コメント

コメントには相互リンクされた6つのファイルが必要です。ヘルパーを使用してください — `document.xml` も編集する場合はディレクトリモード（unzip/rezip のサイクルを省ける）、それ以外の場合は `.docx` 直接モードを使用します:

```bash
# Against an already-unpacked directory (preferred when also placing markers)
python scripts/comment.py unpacked/ "Fees & expenses cap is too low"
python scripts/comment.py unpacked/ "Agreed" --parent 0

# Against a .docx directly
python scripts/comment.py contract.docx "This cap is too low" -o annotated.docx
```

このスクリプトは `comments.xml`、`commentsExtended.xml`、`commentsIds.xml`、`commentsExtensible.xml`、リレーションシップ、コンテントタイプのオーバーライドを書き込みます。コメントIDは自動割り当てされます。その後、コメントを特定のテキストにアンカーするための `<w:commentRangeStart>`/`<w:commentRangeEnd>`/`<w:commentReference>` スニペットを `word/document.xml` に追加するよう出力します — そのマーカーを配置するまでは、コメントは存在しますが表示されません。

## 依存関係

`docx`（npm、プリインストール済み — `require('docx')` が失敗した場合のみインストール）· `pandoc` · LibreOffice（`soffice`）· `pdftoppm`（Poppler）