# MCP サーバー評価ガイド

## 概要

このドキュメントでは、MCP サーバー向けの包括的な評価を作成するためのガイドラインを提供します。評価は、提供されたツールのみを使用して、LLM が MCP サーバーを効果的に活用し、現実的で複雑な質問に回答できるかどうかをテストします。

---

## クイックリファレンス

### 評価の要件
- 人間が読みやすい質問を10個作成する
- 質問は READ-ONLY（読み取り専用）、INDEPENDENT（独立）、NON-DESTRUCTIVE（非破壊）であること
- 各質問には複数回（場合によっては数十回）のツール呼び出しが必要
- 回答は単一で検証可能な値であること
- 回答は STABLE（時間とともに変化しない）であること

### 出力形式
```xml
<evaluation>
   <qa_pair>
      <question>Your question here</question>
      <answer>Single verifiable answer</answer>
   </qa_pair>
</evaluation>
```

---

## 評価の目的

MCP サーバーの品質を測る基準は、サーバーがツールをどれだけ上手く・網羅的に実装しているかではなく、その実装（入出力スキーマ、docstring/説明、機能）によって、他のコンテキストを持たず MCP サーバーのみにアクセスできる LLM が、現実的で困難な質問にどれだけ回答できるかです。

## 評価の概要

回答に READ-ONLY（読み取り専用）、INDEPENDENT（独立）、NON-DESTRUCTIVE（非破壊）、IDEMPOTENT（冪等）な操作のみを必要とする、人間が読みやすい質問を10個作成してください。各質問は以下の条件を満たす必要があります:
- 現実的であること
- 明確かつ簡潔であること
- 曖昧さがないこと
- 複雑で、場合によっては数十回のツール呼び出しやステップを必要とすること
- 事前に特定した、単一で検証可能な値で回答できること

## 質問のガイドライン

### 中核となる要件

1. **質問は必ず独立していること**
   - 各質問は他の質問の回答に依存してはならない
   - 他の質問を処理した際の書き込み操作を前提にしてはならない

2. **質問は非破壊かつ冪等なツールの使用のみを必要とすること**
   - 正しい回答を得るために状態を変更する指示や要件を含めてはならない

3. **質問は現実的で、明確で、簡潔で、複雑であること**
   - 回答するために別の LLM が複数（場合によっては数十個）のツールやステップを使用する必要があること

### 複雑性と深さ

4. **質問は深い探索を必要とすること**
   - 複数のサブ質問と順次的なツール呼び出しを必要とするマルチホップ質問を検討する
   - 各ステップは前の質問で得られた情報を活用できること

5. **質問は広範なページングを必要とする場合がある**
   - 複数ページの結果をめくる必要がある場合がある
   - ニッチな情報を見つけるために古いデータ（1〜2年前）を検索する必要がある場合がある
   - 質問は難しいものでなければならない

6. **質問は深い理解を必要とすること**
   - 表面的な知識ではなく
   - 証拠を必要とする複雑な概念を、True/False 形式の質問として提示する場合がある
   - LLM がさまざまな仮説を検索する必要がある選択式形式を使用する場合がある

7. **質問は単純なキーワード検索では解けないこと**
   - 対象コンテンツの特定のキーワードを含めない
   - 同義語、関連概念、言い換えを使用する
   - 複数回の検索、複数の関連項目の分析、コンテキストの抽出、そして回答の導出を必要とすること

### ツールのテスト

8. **質問はツールの戻り値をストレステストするべき**
   - 大きな JSON オブジェクトやリストを返すツールを呼び出させ、LLM を圧倒させる場合がある
   - 複数のデータ形式の理解を必要とするべき:
     - ID と名前
     - タイムスタンプと日時（月、日、年、秒）
     - ファイル ID、名前、拡張子、MIME タイプ
     - URL、GID など
   - ツールが有用な形のデータをすべて返せるかを調査するべき

9. **質問はほとんどが実際の人間のユースケースを反映するべき**
   - LLM の支援を受けた人間が関心を持つ、情報検索タスクの種類

10. **質問は数十回のツール呼び出しを必要とする場合がある**
    - これはコンテキストに制限がある LLM に挑戦を与える
    - MCP サーバーのツールが返す情報を削減することを促す

11. **曖昧な質問を含める**
    - 曖昧であるか、どのツールを呼ぶかについて難しい判断を必要とする場合がある
    - LLM に誤りや誤解をさせる可能性を持たせる
    - 曖昧さにもかかわらず、単一で検証可能な回答が存在することを保証する

### 安定性

12. **回答が変化しないように質問を設計すること**
    - 動的な「現在の状態」に依存する質問はしない
    - 例えば、以下を数えない:
      - 投稿へのリアクション数
      - スレッドへの返信数
      - チャンネルのメンバー数

13. **MCP サーバーに作成する質問の種類を制限させない**
    - 挑戦的で複雑な質問を作成する
    - 一部は利用可能な MCP サーバーのツールでは解けないかもしれない
    - 質問は特定の出力形式を必要とする場合がある（datetime と epoch 時間、JSON と MARKDOWN）
    - 完了に数十回のツール呼び出しを必要とする場合がある

## 回答のガイドライン

### 検証

1. **回答は直接の文字列比較で検証可能であること**
   - 回答が複数の形式で表現できる場合は、質問内で出力形式を明確に指定する
   - 例: "YYYY/MM/DD 形式を使用してください。"、"True または False で回答してください。"、"A、B、C、D のみで回答し、それ以外は付け加えないでください。"
   - 回答は次のような単一で検証可能な値であるべき:
     - ユーザー ID、ユーザー名、表示名、名、姓
     - チャンネル ID、チャンネル名
     - メッセージ ID、文字列
     - URL、タイトル
     - 数値
     - タイムスタンプ、日時
     - ブール値（True/False 質問用）
     - メールアドレス、電話番号
     - ファイル ID、ファイル名、ファイル拡張子
     - 選択式の回答
   - 回答は特別な整形や複雑な構造化出力を必要としないこと
   - 回答は直接の文字列比較で検証される

### 読みやすさ

2. **回答は一般的に人間が読みやすい形式を優先すること**
   - 例: 名前、名、姓、日時、ファイル名、メッセージ文字列、URL、yes/no、true/false、a/b/c/d
   - 意味不明な ID ではなく（ID も許容される）
   - 圧倒的多数の回答は人間が読みやすい形式であるべき

### 安定性

3. **回答は安定・固定していること**
   - 古いコンテンツを参照する（例: 終了した会話、公開済みのプロジェクト、回答済みの質問）
   - 常に同じ回答を返す「確定済み」の概念に基づいて質問を作成する
   - 固定の時間枠を考慮するよう求めることで、変化する回答から隔離できる
   - 変化しそうにないコンテキストに依存する
   - 例: 論文名を探す場合は、後から発表された論文と混同されないよう十分に具体的にする

4. **回答は明確で曖昧さがないこと**
   - 単一で明確な回答が存在するように質問を設計すること
   - 回答は MCP サーバーのツールを使用して導き出せること

### 多様性

5. **回答は多様であること**
   - 回答は多様な形式やフォーマットの単一で検証可能な値であるべき
   - ユーザー概念: ユーザー ID、ユーザー名、表示名、名、姓、メールアドレス、電話番号
   - チャンネル概念: チャンネル ID、チャンネル名、チャンネルトピック
   - メッセージ概念: メッセージ ID、メッセージ文字列、タイムスタンプ、月、日、年

6. **回答は複雑な構造であってはならない**
   - 値のリストではない
   - 複雑なオブジェクトではない
   - ID や文字列のリストではない
   - 自然言語のテキストではない
   - 直接の文字列比較で簡単に検証でき、現実的に再現できる場合を除く
   - そして現実的に再現できること
   - LLM が同じリストを別の順序や形式で返す可能性は低いことが望ましい

## 評価プロセス

### ステップ 1: ドキュメントの調査

対象 API のドキュメントを読み、以下を理解してください:
- 利用可能なエンドポイントと機能
- 曖昧さがある場合は、ウェブから追加情報を取得する
- このステップは可能な限り並列化する
- 各サブエージェントがファイルシステムまたはウェブ上のドキュメントのみを調査していることを確認する

### ステップ 2: ツールの調査

MCP サーバーで利用可能なツールを列挙してください:
- MCP サーバーを直接調査する
- 入出力スキーマ、docstring、説明を理解する
- この段階ではツール自体を呼び出さない

### ステップ 3: 理解を深める

十分に理解できるまでステップ 1 と 2 を繰り返してください:
- 複数回繰り返す
- 作成したいタスクの種類を考える
- 理解を洗練させる
- いかなる段階でも MCP サーバー実装のコード自体を読まないこと
- 直感と理解を用いて、妥当で現実的かつ非常に挑戦的なタスクを作成する

### ステップ 4: 読み取り専用のコンテンツ調査

API とツールを理解したら、MCP サーバーのツールを使用してください:
- 読み取り専用かつ非破壊的な操作のみを使用してコンテンツを調査する
- 目標: 現実的な質問を作成するための具体的なコンテンツ（例: ユーザー、チャンネル、メッセージ、プロジェクト、タスク）を特定する
- 状態を変更するツールを呼び出してはならない
- MCP サーバー実装のコード自体は読まない
- 独立した探索を行う個々のサブエージェントとこのステップを並列化する
- 各サブエージェントが読み取り専用、非破壊、冪等な操作のみを実行していることを確認する
- 注意: 一部のツールは大量のデータを返し、コンテキストを使い果たす可能性がある
- 探索には段階的で小さく、的を絞ったツール呼び出しを行う
- すべてのツール呼び出しで `limit` パラメータを使用して結果を制限する（10未満）
- ページネーションを使用する

### ステップ 5: タスクの作成

コンテンツを調査したら、人間が読みやすい質問を10個作成してください:
- LLM が MCP サーバーを使って回答できるものであること
- 上記のすべての質問・回答ガイドラインに従うこと

## 出力形式

各 QA ペアは質問と回答で構成されます。出力はこの構造を持つ XML ファイルにしてください:

```xml
<evaluation>
   <qa_pair>
      <question>Find the project created in Q2 2024 with the highest number of completed tasks. What is the project name?</question>
      <answer>Website Redesign</answer>
   </qa_pair>
   <qa_pair>
      <question>Search for issues labeled as "bug" that were closed in March 2024. Which user closed the most issues? Provide their username.</question>
      <answer>sarah_dev</answer>
   </qa_pair>
   <qa_pair>
      <question>Look for pull requests that modified files in the /api directory and were merged between January 1 and January 31, 2024. How many different contributors worked on these PRs?</question>
      <answer>7</answer>
   </qa_pair>
   <qa_pair>
      <question>Find the repository with the most stars that was created before 2023. What is the repository name?</question>
      <answer>data-pipeline</answer>
   </qa_pair>
</evaluation>
```

## 評価の例

### 良い質問の例

**例 1: 深い探索を必要とするマルチホップ質問（GitHub MCP）**
```xml
<qa_pair>
   <question>Find the repository that was archived in Q3 2023 and had previously been the most forked project in the organization. What was the primary programming language used in that repository?</question>
   <answer>Python</answer>
</qa_pair>
```

この質問が良い理由:
- アーカイブされたリポジトリを見つけるために複数回の検索が必要
- アーカイブ前に最もフォークされていたものを特定する必要がある
- 言語を確認するためにリポジトリの詳細を調べる必要がある
- 回答が単純で検証可能な値である
- 変化しない履歴（確定済み）データに基づいている

**例 2: キーワード一致なしでコンテキストの理解を必要とする質問（プロジェクト管理 MCP）**
```xml
<qa_pair>
   <question>Locate the initiative focused on improving customer onboarding that was completed in late 2023. The project lead created a retrospective document after completion. What was the lead's role title at that time?</question>
   <answer>Product Manager</answer>
</qa_pair>
```

この質問が良い理由:
- 特定のプロジェクト名を使用していない（「顧客オンボーディングの改善に焦点を当てたイニシアチブ」）
- 特定の期間の完了プロジェクトを見つける必要がある
- プロジェクトリーダーとその役割を特定する必要がある
- 振り返り（レトロスペクティブ）ドキュメントからコンテキストを理解する必要がある
- 回答が人間が読みやすく、安定している
- 完了した作業に基づいている（変化しない）

**例 3: 複数のステップを必要とする複雑な集計（イシュートラッカー MCP）**
```xml
<qa_pair>
   <question>Among all bugs reported in January 2024 that were marked as critical priority, which assignee resolved the highest percentage of their assigned bugs within 48 hours? Provide the assignee's username.</question>
   <answer>alex_eng</answer>
</qa_pair>
```

この質問が良い理由:
- バグを日付、優先度、ステータスでフィルタリングする必要がある
- 担当者ごとにグループ化し、解決率を計算する必要がある
- 48時間の枠を判断するためにタイムスタンプの理解が必要
- ページネーションをテストする（処理対象のバグが多数ある可能性）
- 回答が単一のユーザー名である
- 特定の期間の履歴データに基づいている

**例 4: 複数のデータタイプにわたる総合分析を必要とする質問（CRM MCP）**
```xml
<qa_pair>
   <question>Find the account that upgraded from the Starter to Enterprise plan in Q4 2023 and had the highest annual contract value. What industry does this account operate in?</question>
   <answer>Healthcare</answer>
</qa_pair>
```

この質問が良い理由:
- サブスクリプション層の変更を理解する必要がある
- 特定の期間のアップグレードイベントを特定する必要がある
- 契約額を比較する必要がある
- アカウントの業界情報にアクセスする必要がある
- 回答が単純で検証可能である
- 完了した履歴取引に基づいている

### 悪い質問の例

**例 1: 回答が時間とともに変化する**
```xml
<qa_pair>
   <question>How many open issues are currently assigned to the engineering team?</question>
   <answer>47</answer>
</qa_pair>
```

この質問が悪い理由:
- イシューの作成、クローズ、再割り当てにより回答が変化する
- 安定・固定したデータに基づいていない
- 動的な「現在の状態」に依存している

**例 2: キーワード検索で簡単に解けてしまう**
```xml
<qa_pair>
   <question>Find the pull request with title "Add authentication feature" and tell me who created it.</question>
   <answer>developer123</answer>
</qa_pair>
```

この質問が悪い理由:
- 正確なタイトルの単純なキーワード検索で解ける
- 深い探索や理解を必要としない
- 総合分析や分析が不要

**例 3: 回答形式が曖昧**
```xml
<qa_pair>
   <question>List all the repositories that have Python as their primary language.</question>
   <answer>repo1, repo2, repo3, data-pipeline, ml-tools</answer>
</qa_pair>
```

この質問が悪い理由:
- 回答がリストであり、任意の順序で返される可能性がある
- 直接の文字列比較で検証するのが難しい
- LLM が異なる形式（JSON 配列、カンマ区切り、改行区切り）で整形する可能性がある
- 特定の集計値（件数）や最上級（最多スター）を尋ねる方が良い

## 検証プロセス

評価を作成した後:

1. **XML ファイルを調べる** スキーマを理解する
2. **各タスクの指示を読み込み**、並列して MCP サーバーとツールを使用し、タスクを自分自身で解いて正しい回答を特定する
3. **WRITE（書き込み）または DESTRUCTIVE（破壊的）な操作を必要とするものをフラグする**
4. **すべての正しい回答を集約し**、ドキュメント内の誤った回答を置き換える
5. **WRITE（書き込み）または DESTRUCTIVE（破壊的）な操作を必要とする `<qa_pair>` を削除する**

コンテキストを使い果たさないようにタスクの解決を並列化し、最後にすべての回答を集約してファイルに変更を加えることを忘れないでください。

## 高品質な評価を作成するためのヒント

1. **タスクを生成する前にしっかり考え、事前に計画する**
2. **機会があれば並列化する** プロセスを高速化し、コンテキストを管理する
3. **人間が実際に達成したい現実的なユースケースに焦点を当てる**
4. **MCP サーバーの機能の限界を試す挑戦的な質問を作成する**
5. **履歴データと確定済みの概念を使用して安定性を確保する**
6. **MCP サーバーのツールを使用して自分で質問を解き、回答を検証する**
7. **プロセス中に学んだことに基づいて反復・改善する**

---

# 評価の実行

評価ファイルを作成したら、提供された評価ハーネスを使用して MCP サーバーをテストできます。

## セットアップ

1. **依存関係のインストール**

   ```bash
   pip install -r scripts/requirements.txt
   ```

   または手動でインストール:
   ```bash
   pip install anthropic mcp
   ```

2. **API キーの設定**

   ```bash
   export ANTHROPIC_API_KEY=your_api_key_here
   ```

## 評価ファイルの形式

評価ファイルは `<qa_pair>` 要素を持つ XML 形式を使用します:

```xml
<evaluation>
   <qa_pair>
      <question>Find the project created in Q2 2024 with the highest number of completed tasks. What is the project name?</question>
      <answer>Website Redesign</answer>
   </qa_pair>
   <qa_pair>
      <question>Search for issues labeled as "bug" that were closed in March 2024. Which user closed the most issues? Provide their username.</question>
      <answer>sarah_dev</answer>
   </qa_pair>
</evaluation>
```

## 評価の実行

評価スクリプト（`scripts/evaluation.py`）は3つのトランスポートタイプをサポートします:

**重要:**
- **stdio トランスポート**: 評価スクリプトが MCP サーバーのプロセスを自動的に起動・管理します。サーバーを手動で起動しないでください。
- **sse/http トランスポート**: 評価を実行する前に MCP サーバーを別途起動する必要があります。スクリプトは指定された URL で起動済みのサーバーに接続します。

### 1. ローカル STDIO サーバー

ローカルで実行する MCP サーバー向け（スクリプトがサーバーを自動的に起動します）:

```bash
python scripts/evaluation.py \
  -t stdio \
  -c python \
  -a my_mcp_server.py \
  evaluation.xml
```

環境変数を指定する場合:
```bash
python scripts/evaluation.py \
  -t stdio \
  -c python \
  -a my_mcp_server.py \
  -e API_KEY=abc123 \
  -e DEBUG=true \
  evaluation.xml
```

### 2. Server-Sent Events (SSE)

SSE ベースの MCP サーバー向け（先にサーバーを起動する必要があります）:

```bash
python scripts/evaluation.py \
  -t sse \
  -u https://example.com/mcp \
  -H "Authorization: Bearer token123" \
  -H "X-Custom-Header: value" \
  evaluation.xml
```

### 3. HTTP（Streamable HTTP）

HTTP ベースの MCP サーバー向け（先にサーバーを起動する必要があります）:

```bash
python scripts/evaluation.py \
  -t http \
  -u https://example.com/mcp \
  -H "Authorization: Bearer token123" \
  evaluation.xml
```

## コマンドラインオプション

```
usage: evaluation.py [-h] [-t {stdio,sse,http}] [-m MODEL] [-c COMMAND]
                     [-a ARGS [ARGS ...]] [-e ENV [ENV ...]] [-u URL]
                     [-H HEADERS [HEADERS ...]] [-o OUTPUT]
                     eval_file

positional arguments:
  eval_file             Path to evaluation XML file

optional arguments:
  -h, --help            Show help message
  -t, --transport       Transport type: stdio, sse, or http (default: stdio)
  -m, --model           Claude model to use (default: claude-3-7-sonnet-20250219)
  -o, --output          Output file for report (default: print to stdout)

stdio options:
  -c, --command         Command to run MCP server (e.g., python, node)
  -a, --args            Arguments for the command (e.g., server.py)
  -e, --env             Environment variables in KEY=VALUE format

sse/http options:
  -u, --url             MCP server URL
  -H, --header          HTTP headers in 'Key: Value' format
```

## 出力

評価スクリプトは以下を含む詳細なレポートを生成します:

- **概要統計**:
  - 正解率（正解数/全体数）
  - 平均タスク所要時間
  - タスクあたりの平均ツール呼び出し回数
  - ツール呼び出しの総数

- **タスク別の結果**:
  - プロンプトと期待される回答
  - エージェントの実際の回答
  - 回答が正しかったかどうか（✅/❌）
  - 所要時間とツール呼び出しの詳細
  - エージェントによるアプローチの要約
  - ツールに関するエージェントのフィードバック

### レポートをファイルに保存

```bash
python scripts/evaluation.py \
  -t stdio \
  -c python \
  -a my_server.py \
  -o evaluation_report.md \
  evaluation.xml
```

## 完全なワークフローの例

評価の作成と実行の完全な例は以下のとおりです:

1. **評価ファイルを作成する**（`my_evaluation.xml`）:

```xml
<evaluation>
   <qa_pair>
      <question>Find the user who created the most issues in January 2024. What is their username?</question>
      <answer>alice_developer</answer>
   </qa_pair>
   <qa_pair>
      <question>Among all pull requests merged in Q1 2024, which repository had the highest number? Provide the repository name.</question>
      <answer>backend-api</answer>
   </qa_pair>
   <qa_pair>
      <question>Find the project that was completed in December 2023 and had the longest duration from start to finish. How many days did it take?</question>
      <answer>127</answer>
   </qa_pair>
</evaluation>
```

2. **依存関係をインストールする**:

```bash
pip install -r scripts/requirements.txt
export ANTHROPIC_API_KEY=your_api_key
```

3. **評価を実行する**:

```bash
python scripts/evaluation.py \
  -t stdio \
  -c python \
  -a github_mcp_server.py \
  -e GITHUB_TOKEN=ghp_xxx \
  -o github_eval_report.md \
  my_evaluation.xml
```

4. **レポートを確認する** `github_eval_report.md` を確認して:
   - どの質問が成功・失敗したかを確認
   - ツールに関するエージェントのフィードバックを読む
   - 改善点を特定する
   - MCP サーバーの設計を反復・改善する

## トラブルシューティング

### 接続エラー

接続エラーが発生した場合:
- **STDIO**: コマンドと引数が正しいことを確認する
- **SSE/HTTP**: URL にアクセスでき、ヘッダーが正しいことを確認する
- 必要な API キーが環境変数またはヘッダーに設定されていることを確認する

### 精度が低い場合

多くの評価が失敗する場合:
- 各タスクのエージェントのフィードバックを確認する
- ツールの説明が明確で包括的かを確認する
- 入力パラメータが十分に文書化されているか確認する
- ツールが返すデータが多すぎるか少なすぎるかを検討する
- エラーメッセージが実行可能であることを確認する

### タイムアウトの問題

タスクがタイムアウトする場合:
- より高性能なモデルを使用する（例: `claude-3-7-sonnet-20250219`）
- ツールが大量のデータを返していないか確認する
- ページネーションが正しく動作しているか確認する
- 複雑な質問の簡略化を検討する