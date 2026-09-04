---
name: mcp-builder
description: 高品質なMCP (Model Context Protocol) サーバーの作成ガイド。well-designed なツールを通じて LLM が外部サービスと連携できるようにします。外部 API やサービスを統合する MCP server を構築する際に使用してください。Python (FastMCP) または Node/TypeScript (MCP SDK) のどちらにも対応します。
license: Complete terms in LICENSE.txt
---

# MCP サーバー開発ガイド

## 概要

well-designed なツールを通じて LLM が外部サービスと連携できるようにする MCP (Model Context Protocol) サーバーを作成します。MCP サーバーの品質は、LLM が現実のタスクをどれだけうまく遂行できるかをどれだけ支えられるかで測られます。

---

# プロセス

## 🚀 全体のワークフロー

高品質な MCP サーバーの作成には、主に4つのフェーズがあります:

### フェーズ 1: 徹底的な調査と計画

#### 1.1 最新の MCP 設計を理解する

**API カバレッジとワークフローツールのバランス:**
包括的な API エンドポイントのカバレッジと、専用のワークフローツールのバランスを取ります。ワークフローツールは特定のタスクに対して便利な一方、包括的なカバレッジはエージェントに操作を組み合わせる柔軟性を与えます。パフォーマンスはクライアントによって異なります。基本的なツールを組み合わせるコード実行が有効なクライアントもあれば、高レベルのワークフローの方がうまく動作するクライアントもあります。迷った場合は、包括的な API カバレッジを優先してください。

**ツールの命名と発見可能性:**
明確で説明的なツール名は、エージェントが適切なツールを素早く見つけるのに役立ちます。一貫性のあるプレフィックス（例: `github_create_issue`、`github_list_repos`）と、アクション指向の命名を使用してください。

**コンテキスト管理:**
エージェントは、簡潔なツールの説明と、結果のフィルタリング・ページネーション機能から恩恵を受けます。焦点を絞った関連データを返すツールを設計してください。一部のクライアントはコード実行をサポートしており、エージェントがデータを効率的にフィルタリング・処理するのに役立ちます。

**実行可能なエラーメッセージ:**
エラーメッセージは、具体的な提案と次のステップを添えて、エージェントを解決策へ導くようにしてください。

#### 1.2 MCP プロトコルのドキュメントを調査する

**MCP 仕様の参照方法:**

まずサイトマップから関連ページを探します: `https://modelcontextprotocol.io/sitemap.xml`

次に、markdown 形式で特定のページを取得するには `.md` サフィックスを付けます（例: `https://modelcontextprotocol.io/specification/draft.md`）。

確認すべき主要ページ:
- 仕様の概要とアーキテクチャ
- トランスポートの仕組み (streamable HTTP、stdio)
- ツール、リソース、プロンプトの定義

#### 1.3 フレームワークのドキュメントを調査する

**推奨スタック:**
- **言語**: TypeScript (高品質な SDK サポートと、MCPB など多くの実行環境での優れた互換性を持ちます。さらに AI モデルは TypeScript コードの生成が得意で、広範な利用実績、静的型付け、優れた lint ツールの恩恵を受けられます)
- **トランスポート**: リモートサーバーには Streamable HTTP を使用し、ステートレスな JSON を利用します（ステートフルなセッションやストリーミングレスポンスと比較して、スケール・保守が容易）。ローカルサーバーには stdio を使用します。

**フレームワークのドキュメントの読み込み:**

- **MCP ベストプラクティス**: [📋 ベストプラクティスを表示](./reference/mcp_best_practices.md) - 中核となるガイドライン

**TypeScript の場合（推奨）:**
- **TypeScript SDK**: WebFetch を使用して `https://raw.githubusercontent.com/modelcontextprotocol/typescript-sdk/main/README.md` を読み込みます
- [⚡ TypeScript ガイド](./reference/node_mcp_server.md) - TypeScript のパターンと例

**Python の場合:**
- **Python SDK**: WebFetch を使用して `https://raw.githubusercontent.com/modelcontextprotocol/python-sdk/main/README.md` を読み込みます
- [🐍 Python ガイド](./reference/python_mcp_server.md) - Python のパターンと例

#### 1.4 実装計画を立てる

**API を理解する:**
サービスの API ドキュメントを確認して、主要なエンドポイント、認証要件、データモデルを特定します。必要に応じてウェブ検索と WebFetch を使用してください。

**ツールの選定:**
包括的な API カバレッジを優先します。最も一般的な操作から順に、実装するエンドポイントを列挙してください。

---

### フェーズ 2: 実装

#### 2.1 プロジェクト構造のセットアップ

プロジェクトのセットアップ方法は、言語別ガイドを参照してください:
- [⚡ TypeScript ガイド](./reference/node_mcp_server.md) - プロジェクト構造、package.json、tsconfig.json
- [🐍 Python ガイド](./reference/python_mcp_server.md) - モジュール構成、依存関係

#### 2.2 コアインフラの実装

共通ユーティリティを作成します:
- 認証付きの API クライアント
- エラーハンドリングのヘルパー
- レスポンスのフォーマット (JSON/Markdown)
- ページネーションのサポート

#### 2.3 ツールの実装

各ツールについて:

**入力スキーマ:**
- Zod (TypeScript) または Pydantic (Python) を使用
- 制約と明確な説明を含める
- フィールドの説明に例を追加

**出力スキーマ:**
- 構造化データには可能な限り `outputSchema` を定義
- ツールのレスポンスで `structuredContent` を使用 (TypeScript SDK の機能)
- クライアントがツールの出力を理解・処理するのに役立つ

**ツールの説明:**
- 機能の簡潔な要約
- パラメータの説明
- 戻り値の型スキーマ

**実装:**
- I/O 操作には async/await を使用
- 実行可能なメッセージを伴う適切なエラーハンドリング
- 該当する場合にはページネーションをサポート
- 最新の SDK を使用する場合は、テキストコンテンツと構造化データの両方を返す

**アノテーション:**
- `readOnlyHint`: true/false
- `destructiveHint`: true/false
- `idempotentHint`: true/false
- `openWorldHint`: true/false

---

### フェーズ 3: レビューとテスト

#### 3.1 コード品質

以下を確認します:
- 重複コードがないこと (DRY 原則)
- 一貫したエラーハンドリング
- 型カバレッジが完全であること
- 明確なツールの説明

#### 3.2 ビルドとテスト

**TypeScript:**
- `npm run build` を実行してコンパイルを検証
- MCP Inspector でテスト: `npx @modelcontextprotocol/inspector`

**Python:**
- 構文を検証: `python -m py_compile your_server.py`
- MCP Inspector でテスト

詳細なテスト方法と品質チェックリストは、言語別ガイドを参照してください。

---

### フェーズ 4: 評価の作成

MCP サーバーを実装したら、その有効性をテストするための包括的な評価を作成してください。

**完全な評価ガイドラインは [✅ 評価ガイド](./reference/evaluation.md) を参照してください。**

#### 4.1 評価の目的を理解する

評価を使用して、LLM が MCP サーバーを効果的に利用し、現実的で複雑な質問に回答できるかどうかをテストします。

#### 4.2 評価用の質問を10個作成する

効果的な評価を作成するには、評価ガイドで説明されているプロセスに従ってください:

1. **ツールの調査**: 利用可能なツールを列挙し、その機能を理解する
2. **コンテンツの探索**: READ-ONLY 操作を使用して利用可能なデータを探索する
3. **質問の作成**: 複雑で現実的な質問を10個作成する
4. **回答の検証**: 各質問を自分で解いて回答を検証する

#### 4.3 評価の要件

各質問が以下の条件を満たしていることを確認してください:
- **独立性**: 他の質問に依存しない
- **読み取り専用**: 非破壊的な操作のみを必要とする
- **複雑性**: 複数のツール呼び出しと深い探索を必要とする
- **現実性**: 人間が気にする実際のユースケースに基づく
- **検証可能性**: 文字列比較で検証できる、単一かつ明確な回答である
- **安定性**: 回答が時間とともに変化しない

#### 4.4 出力形式

以下の構造の XML ファイルを作成してください:

```xml
<evaluation>
  <qa_pair>
    <question>Find discussions about AI model launches with animal codenames. One model needed a specific safety designation that uses the format ASL-X. What number X was being determined for the model named after a spotted wild cat?</question>
    <answer>3</answer>
  </qa_pair>
<!-- More qa_pairs... -->
</evaluation>
```

---

# リファレンスファイル

## 📚 ドキュメントライブラリ

開発中に必要に応じてこれらのリソースを読み込んでください:

### 中核の MCP ドキュメント（最初に読み込む）
- **MCP プロトコル**: まず `https://modelcontextprotocol.io/sitemap.xml` のサイトマップから始め、`.md` サフィックスを付けて特定のページを取得します
- [📋 MCP ベストプラクティス](./reference/mcp_best_practices.md) - MCP の普遍的なガイドライン。以下を含みます:
  - サーバーとツールの命名規則
  - レスポンス形式のガイドライン (JSON と Markdown)
  - ページネーションのベストプラクティス
  - トランスポートの選定 (streamable HTTP と stdio)
  - セキュリティとエラーハンドリングの基準

### SDK ドキュメント（フェーズ 1/2 で読み込む）
- **Python SDK**: `https://raw.githubusercontent.com/modelcontextprotocol/python-sdk/main/README.md` から取得
- **TypeScript SDK**: `https://raw.githubusercontent.com/modelcontextprotocol/typescript-sdk/main/README.md` から取得

### 言語別の実装ガイド（フェーズ 2 で読み込む）
- [🐍 Python 実装ガイド](./reference/python_mcp_server.md) - Python/FastMCP の完全ガイド。以下を含みます:
  - サーバー初期化のパターン
  - Pydantic モデルの例
  - `@mcp.tool` によるツール登録
  - 完全な動作例
  - 品質チェックリスト

- [⚡ TypeScript 実装ガイド](./reference/node_mcp_server.md) - TypeScript の完全ガイド。以下を含みます:
  - プロジェクト構造
  - Zod スキーマのパターン
  - `server.registerTool` によるツール登録
  - 完全な動作例
  - 品質チェックリスト

### 評価ガイド（フェーズ 4 で読み込む）
- [✅ 評価ガイド](./reference/evaluation.md) - 評価作成の完全ガイド。以下を含みます:
  - 質問作成のガイドライン
  - 回答検証の戦略
  - XML 形式の仕様
  - 質問と回答の例
  - 提供されたスクリプトを使用した評価の実行