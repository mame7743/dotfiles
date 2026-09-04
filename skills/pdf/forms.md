**重要：これらの手順は必ず順番どおりに実行すること。コード作成に飛びついて先に進まないこと。**

PDFフォームへの入力が必要な場合は、まず PDF に入力可能なフォームフィールドがあるかどうかを確認します。このファイルがあるディレクトリから次のスクリプトを実行してください：
`python scripts/check_fillable_fields <file.pdf>` を実行し、その結果に応じて「入力可能なフィールド」または「入力不可能なフィールド」のいずれかの手順に進んでください。

# 入力可能なフィールド
PDF に入力可能なフォームフィールドがある場合：
- このファイルがあるディレクトリから次のスクリプトを実行してください：`python scripts/extract_form_field_info.py <input.pdf> <field_info.json>`。このスクリプトは以下の形式のフィールド一覧を含む JSON ファイルを作成します：
```
[
  {
    "field_id": (フィールドの一意のID),
    "page": (ページ番号、1始まり),
    "rect": ([left, bottom, right, top] の PDF 座標でのバウンディングボックス。y=0 はページの下端),
    "type": ("text", "checkbox", "radio_group", または "choice"),
  },
  // チェックボックスには "checked_value" と "unchecked_value" プロパティがあります：
  {
    "field_id": (フィールドの一意のID),
    "page": (ページ番号、1始まり),
    "type": "checkbox",
    "checked_value": (チェックボックスをオンにするためにこのフィールドに設定する値),
    "unchecked_value": (チェックボックスをオフにするためにこのフィールドに設定する値),
  },
  // ラジオグループには選択肢を表す "radio_options" リストがあります。
  {
    "field_id": (フィールドの一意のID),
    "page": (ページ番号、1始まり),
    "type": "radio_group",
    "radio_options": [
      {
        "value": (このラジオオプションを選択するためにこのフィールドに設定する値),
        "rect": (このオプションのラジオボタンのバウンディングボックス)
      },
      // その他のラジオオプション
    ]
  },
  // 選択式フィールドには選択肢を表す "choice_options" リストがあります：
  {
    "field_id": (フィールドの一意のID),
    "page": (ページ番号、1始まり),
    "type": "choice",
    "choice_options": [
      {
        "value": (このオプションを選択するためにこのフィールドに設定する値),
        "text": (オプションの表示テキスト)
      },
      // その他の選択オプション
    ],
  }
]
```
- 次のスクリプトで PDF を PNG 画像に変換します（各ページにつき1枚の画像。このファイルがあるディレクトリから実行）：
`python scripts/convert_pdf_to_images.py <file.pdf> <output_directory>`
その後、画像を分析して各フォームフィールドの用途を判断してください（バウンディングボックスの PDF 座標は必ず画像座標に変換すること）。
- 各フィールドに入力する値を含む `field_values.json` ファイルを以下の形式で作成します：
```
[
  {
    "field_id": "last_name", // extract_form_field_info.py の field_id と一致させる必要があります
    "description": "The user's last name",
    "page": 1, // field_info.json の "page" の値と一致させる必要があります
    "value": "Simpson"
  },
  {
    "field_id": "Checkbox12",
    "description": "Checkbox to be checked if the user is 18 or over",
    "page": 1,
    "value": "/On" // チェックボックスの場合は、その "checked_value" の値を設定してオンにします。ラジオボタングループの場合は、"radio_options" のいずれかの "value" 値を使用します。
  },
  // その他のフィールド
]
```
- このファイルがあるディレクトリから `fill_fillable_fields.py` スクリプトを実行して、入力済みの PDF を作成します：
`python scripts/fill_fillable_fields.py <input pdf> <field_values.json> <output pdf>`
このスクリプトは、指定したフィールド ID と値が有効かどうかを検証します。エラーメッセージが出力された場合は、該当するフィールドを修正して再試行してください。

# 入力不可能なフィールド
PDF に入力可能なフォームフィールドがない場合は、テキスト注釈を追加します。まず PDF 構造から座標を抽出してみて（より正確）、必要に応じて視覚的な推定にフォールバックしてください。

## ステップ1：まず構造抽出を試す

次のスクリプトを実行して、テキストラベル、線、チェックボックスを正確な PDF 座標付きで抽出します：
`python scripts/extract_form_structure.py <input.pdf> form_structure.json`

これにより、次の内容を含む JSON ファイルが作成されます：
- **labels**: 正確な座標付きのすべてのテキスト要素（PDF ポイント単位の x0, top, x1, bottom）
- **lines**: 行の境界を定義する水平線
- **checkboxes**: チェックボックスである小さな正方形の矩形（中心座標付き）
- **row_boundaries**: 水平線から計算された行の top/bottom 位置

**結果を確認する**：`form_structure.json` に意味のあるラベル（フォームフィールドに対応するテキスト要素）がある場合は、**アプローチA：構造ベースの座標** を使用します。PDF がスキャン画像ベースでラベルがほとんどない場合は、**アプローチB：視覚的な推定** を使用します。

---

## アプローチA：構造ベースの座標（推奨）

`extract_form_structure.py` が PDF 内のテキストラベルを見つけた場合に使用します。

### A.1：構造を分析する

form_structure.json を読み、以下を特定します：

1. **ラベルグループ**: 1つのラベルを構成する隣接するテキスト要素（例：「Last」+「Name」）
2. **行構造**: 同じ `top` 値を持つラベルは同じ行にある
3. **フィールド列**: 入力エリアはラベルの終わりから始まる（x0 = label.x1 + gap）
4. **チェックボックス**: 構造からチェックボックスの座標を直接使用する

**座標系**: PDF 座標は y=0 がページの上端で、y は下方向に増加します。

### A.2：欠落要素の確認

構造抽出ではすべてのフォーム要素を検出できない場合があります。一般的なケース：
- **円形のチェックボックス**: 正方形の矩形のみがチェックボックスとして検出される
- **複雑なグラフィック**: 装飾要素や標準外のフォームコントロール
- **薄い・淡い色の要素**: 抽出されない場合がある

PDF 画像上に form_structure.json に含まれていないフォームフィールドが見える場合は、その特定のフィールドについては**視覚的な分析**を使用する必要があります（下記の「ハイブリッドアプローチ」を参照）。

### A.3：PDF座標で fields.json を作成する

各フィールドについて、抽出した構造から入力座標を計算します：

**テキストフィールド：**
- entry x0 = label x1 + 5（ラベル後の小さな余白）
- entry x1 = 次のラベルの x0、または行の境界
- entry top = ラベルの top と同じ
- entry bottom = 下の行境界線、または label bottom + row_height

**チェックボックス：**
- form_structure.json のチェックボックスの矩形座標を直接使用する
- entry_bounding_box = [checkbox.x0, checkbox.top, checkbox.x1, checkbox.bottom]

`pdf_width` と `pdf_height` を使って fields.json を作成します（PDF 座標であることを示します）：
```json
{
  "pages": [
    {"page_number": 1, "pdf_width": 612, "pdf_height": 792}
  ],
  "form_fields": [
    {
      "page_number": 1,
      "description": "Last name entry field",
      "field_label": "Last Name",
      "label_bounding_box": [43, 63, 87, 73],
      "entry_bounding_box": [92, 63, 260, 79],
      "entry_text": {"text": "Smith", "font_size": 10}
    },
    {
      "page_number": 1,
      "description": "US Citizen Yes checkbox",
      "field_label": "Yes",
      "label_bounding_box": [260, 200, 280, 210],
      "entry_bounding_box": [285, 197, 292, 205],
      "entry_text": {"text": "X"}
    }
  ]
}
```

**重要**：`pdf_width`/`pdf_height` と座標は form_structure.json から直接使用してください。

### A.4：バウンディングボックスを検証する

入力前に、バウンディングボックスにエラーがないか確認します：
`python scripts/check_bounding_boxes.py fields.json`

これは、交差するバウンディングボックスや、フォントサイズに対して小さすぎる入力ボックスをチェックします。報告されたエラーは、入力前に修正してください。

---

## アプローチB：視覚的な推定（フォールバック）

PDF がスキャン画像ベースで、構造抽出で使用可能なテキストラベルが見つからない場合（例：すべてのテキストが「(cid:X)」パターンで表示される）に使用します。

### B.1：PDFを画像に変換する

`python scripts/convert_pdf_to_images.py <input.pdf> <images_dir/>`

### B.2：初期フィールド特定

各ページ画像を調べてフォームのセクションを特定し、フィールドの位置の**おおよその推定値**を取得します：
- フォームフィールドのラベルとそのおおよその位置
- 入力エリア（テキスト入力用の線、ボックス、空白スペース）
- チェックボックスとそのおおよその位置

各フィールドについて、おおよそのピクセル座標をメモします（この時点では正確である必要はありません）。

### B.3：ズームによる精緻化（正確さのために重要）

各フィールドについて、推定位置の周囲をクロップして座標を正確に精緻化します。

**ImageMagick でズームしたクロップを作成する：**
```bash
magick <page_image> -crop <width>x<height>+<x>+<y> +repage <crop_output.png>
```

ここで：
- `<x>, <y>` = クロップ領域の左上隅（おおよその推定値からパディングを差し引いた値を使用）
- `<width>, <height>` = クロップ領域のサイズ（フィールド領域＋各辺に約50pxのパディング）

**例：**「Name」フィールドが (100, 150) 付近と推定される場合の精緻化：
```bash
magick images_dir/page_1.png -crop 300x80+50+120 +repage crops/name_field.png
```

（注：`magick` コマンドが利用できない場合は、同じ引数で `convert` を試してください）。

**クロップした画像を調べて**、正確な座標を決定します：
1. 入力エリアが始まる正確なピクセルを特定する（ラベルの後）
2. 入力エリアが終わる場所を特定する（次のフィールドまたは端の前）
3. 入力線・ボックスの上下端を特定する

**クロップ座標をフル画像座標に変換する：**
- full_x = crop_x + crop_offset_x
- full_y = crop_y + crop_offset_y

例：クロップが (50, 120) で始まり、クロップ内で入力ボックスが (52, 18) から始まる場合：
- entry_x0 = 52 + 50 = 102
- entry_top = 18 + 120 = 138

**各フィールドで繰り返します**。可能な場合は近くのフィールドを1つのクロップにまとめてください。

### B.4：精緻化した座標で fields.json を作成する

`image_width` と `image_height` を使って fields.json を作成します（画像座標であることを示します）：
```json
{
  "pages": [
    {"page_number": 1, "image_width": 1700, "image_height": 2200}
  ],
  "form_fields": [
    {
      "page_number": 1,
      "description": "Last name entry field",
      "field_label": "Last Name",
      "label_bounding_box": [120, 175, 242, 198],
      "entry_bounding_box": [255, 175, 720, 218],
      "entry_text": {"text": "Smith", "font_size": 10}
    }
  ]
}
```

**重要**：`image_width`/`image_height` と、ズーム分析で精緻化したピクセル座標を使用してください。

### B.5：バウンディングボックスを検証する

入力前に、バウンディングボックスにエラーがないか確認します：
`python scripts/check_bounding_boxes.py fields.json`

これは、交差するバウンディングボックスや、フォントサイズに対して小さすぎる入力ボックスをチェックします。報告されたエラーは、入力前に修正してください。

---

## ハイブリッドアプローチ：構造＋視覚

構造抽出がほとんどのフィールドで機能するが、一部の要素（円形のチェックボックス、標準外のフォームコントロールなど）を見逃す場合に使用します。

1. **アプローチA** を form_structure.json で検出されたフィールドに使用する
2. 見逃したフィールドの視覚分析のために**PDFを画像に変換**する
3. 見逃したフィールドに**ズームによる精緻化**（アプローチB）を使用する
4. **座標を組み合わせる**：構造抽出のフィールドには `pdf_width`/`pdf_height` を使用する。視覚的に推定したフィールドは、画像座標を PDF 座標に変換する必要があります：
   - pdf_x = image_x * (pdf_width / image_width)
   - pdf_y = image_y * (pdf_height / image_height)
5. fields.json では**1つの座標系**を使用する - すべてを `pdf_width`/`pdf_height` 付きの PDF 座標に変換する

---

## ステップ2：入力前に検証する

**入力前には必ずバウンディングボックスを検証してください：**
`python scripts/check_bounding_boxes.py fields.json`

これは以下をチェックします：
- 交差するバウンディングボックス（テキストの重なりを引き起こす）
- 指定したフォントサイズに対して小さすぎる入力ボックス

続行する前に、fields.json 内の報告されたエラーを修正してください。

## ステップ3：フォームに入力する

入力スクリプトは座標系を自動検出して変換を処理します：
`python scripts/fill_pdf_form_with_annotations.py <input.pdf> fields.json <output.pdf>`

## ステップ4：出力を検証する

入力済みの PDF を画像に変換し、テキストの配置を検証します：
`python scripts/convert_pdf_to_images.py <output.pdf> <verify_images/>`

テキストの位置がずれている場合：
- **アプローチA**：form_structure.json の PDF 座標を `pdf_width`/`pdf_height` とともに使用しているか確認する
- **アプローチB**：画像の寸法が一致し、座標が正確なピクセルであるか確認する
- **ハイブリッド**：視覚的に推定したフィールドの座標変換が正しいことを確認する