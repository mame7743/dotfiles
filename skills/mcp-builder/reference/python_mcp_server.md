# Python MCP サーバー実装ガイド

## 概要

このドキュメントでは、MCP Python SDK を使用して MCP サーバーを実装するための Python 固有のベストプラクティスと例を紹介します。サーバーのセットアップ、ツール登録のパターン、Pydantic による入力検証、エラーハンドリング、完全な動作例を扱います。

---

## クイックリファレンス

### 主要なインポート
```python
from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, Field, field_validator, ConfigDict
from typing import Optional, List, Dict, Any
from enum import Enum
import httpx
```

### サーバーの初期化
```python
mcp = FastMCP("service_mcp")
```

### ツール登録のパターン
```python
@mcp.tool(name="tool_name", annotations={...})
async def tool_function(params: InputModel) -> str:
    # Implementation
    pass
```

---

## MCP Python SDK と FastMCP

公式の MCP Python SDK は、MCP サーバーを構築するための高レベルフレームワークである FastMCP を提供します。その機能は以下のとおりです:
- 関数シグネチャと docstring からの説明と inputSchema の自動生成
- 入力検証のための Pydantic モデル統合
- `@mcp.tool` によるデコレータベースのツール登録

**完全な SDK ドキュメントは、WebFetch を使用して読み込んでください:**
`https://raw.githubusercontent.com/modelcontextprotocol/python-sdk/main/README.md`

## サーバーの命名規則

Python の MCP サーバーは、この命名パターンに従う必要があります:
- **形式**: `{service}_mcp`（小文字とアンダースコア）
- **例**: `github_mcp`、`jira_mcp`、`stripe_mcp`

名前は以下を満たす必要があります:
- 汎用的であること（特定の機能に紐づかない）
- 統合するサービス/API を表すこと
- タスクの説明から推測しやすいこと
- バージョン番号や日付を含まないこと

## ツールの実装

### ツールの命名

ツール名は snake_case を使用し（例: "search_users"、"create_project"、"get_channel_info"）、明確でアクション指向の名前にします。

**命名の衝突を避ける**: 重複を防ぐためにサービスのコンテキストを含めてください:
- "send_message" だけでなく "slack_send_message" を使用
- "create_issue" だけでなく "github_create_issue" を使用
- "list_tasks" だけでなく "asana_list_tasks" を使用

### FastMCP でのツール構造

ツールは `@mcp.tool` デコレータと、入力検証用の Pydantic モデルを使用して定義します:

```python
from pydantic import BaseModel, Field, ConfigDict
from mcp.server.fastmcp import FastMCP

# Initialize the MCP server
mcp = FastMCP("example_mcp")

# Define Pydantic model for input validation
class ServiceToolInput(BaseModel):
    '''Input model for service tool operation.'''
    model_config = ConfigDict(
        str_strip_whitespace=True,  # Auto-strip whitespace from strings
        validate_assignment=True,    # Validate on assignment
        extra='forbid'              # Forbid extra fields
    )

    param1: str = Field(..., description="First parameter description (e.g., 'user123', 'project-abc')", min_length=1, max_length=100)
    param2: Optional[int] = Field(default=None, description="Optional integer parameter with constraints", ge=0, le=1000)
    tags: Optional[List[str]] = Field(default_factory=list, description="List of tags to apply", max_items=10)

@mcp.tool(
    name="service_tool_name",
    annotations={
        "title": "Human-Readable Tool Title",
        "readOnlyHint": True,     # Tool does not modify environment
        "destructiveHint": False,  # Tool does not perform destructive operations
        "idempotentHint": True,    # Repeated calls have no additional effect
        "openWorldHint": False     # Tool does not interact with external entities
    }
)
async def service_tool_name(params: ServiceToolInput) -> str:
    '''Tool description automatically becomes the 'description' field.

    This tool performs a specific operation on the service. It validates all inputs
    using the ServiceToolInput Pydantic model before processing.

    Args:
        params (ServiceToolInput): Validated input parameters containing:
            - param1 (str): First parameter description
            - param2 (Optional[int]): Optional parameter with default
            - tags (Optional[List[str]]): List of tags

    Returns:
        str: JSON-formatted response containing operation results
    '''
    # Implementation here
    pass
```

## Pydantic v2 の主要機能

- ネストした `Config` クラスの代わりに `model_config` を使用
- 非推奨の `validator` の代わりに `field_validator` を使用
- 非推奨の `dict()` の代わりに `model_dump()` を使用
- バリデータには `@classmethod` デコレータが必要
- バリデータメソッドには型ヒントが必要

```python
from pydantic import BaseModel, Field, field_validator, ConfigDict

class CreateUserInput(BaseModel):
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True
    )

    name: str = Field(..., description="User's full name", min_length=1, max_length=100)
    email: str = Field(..., description="User's email address", pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    age: int = Field(..., description="User's age", ge=0, le=150)

    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Email cannot be empty")
        return v.lower()
```

## レスポンス形式のオプション

柔軟性のため、複数の出力形式をサポートしてください:

```python
from enum import Enum

class ResponseFormat(str, Enum):
    '''Output format for tool responses.'''
    MARKDOWN = "markdown"
    JSON = "json"

class UserSearchInput(BaseModel):
    query: str = Field(..., description="Search query")
    response_format: ResponseFormat = Field(
        default=ResponseFormat.MARKDOWN,
        description="Output format: 'markdown' for human-readable or 'json' for machine-readable"
    )
```

**Markdown 形式**:
- 見出し、リスト、書式を使用して明確にする
- タイムスタンプを人間が読みやすい形式に変換（例: epoch の代わりに "2024-01-15 10:30:00 UTC"）
- 表示名と ID を括弧付きで表示（例: "@john.doe (U123456)"）
- 冗長なメタデータは省略（例: すべてのサイズではなく、プロフィール画像の URL を1つだけ表示）
- 関連情報を論理的にグループ化

**JSON 形式**:
- プログラムによる処理に適した、完全で構造化されたデータを返す
- 利用可能なすべてのフィールドとメタデータを含める
- 一貫したフィールド名と型を使用

## ページネーションの実装

リソースを一覧表示するツール向け:

```python
class ListInput(BaseModel):
    limit: Optional[int] = Field(default=20, description="Maximum results to return", ge=1, le=100)
    offset: Optional[int] = Field(default=0, description="Number of results to skip for pagination", ge=0)

async def list_items(params: ListInput) -> str:
    # Make API request with pagination
    data = await api_request(limit=params.limit, offset=params.offset)

    # Return pagination info
    response = {
        "total": data["total"],
        "count": len(data["items"]),
        "offset": params.offset,
        "items": data["items"],
        "has_more": data["total"] > params.offset + len(data["items"]),
        "next_offset": params.offset + len(data["items"]) if data["total"] > params.offset + len(data["items"]) else None
    }
    return json.dumps(response, indent=2)
```

## エラーハンドリング

明確で実行可能なエラーメッセージを提供してください:

```python
def _handle_api_error(e: Exception) -> str:
    '''Consistent error formatting across all tools.'''
    if isinstance(e, httpx.HTTPStatusError):
        if e.response.status_code == 404:
            return "Error: Resource not found. Please check the ID is correct."
        elif e.response.status_code == 403:
            return "Error: Permission denied. You don't have access to this resource."
        elif e.response.status_code == 429:
            return "Error: Rate limit exceeded. Please wait before making more requests."
        return f"Error: API request failed with status {e.response.status_code}"
    elif isinstance(e, httpx.TimeoutException):
        return "Error: Request timed out. Please try again."
    return f"Error: Unexpected error occurred: {type(e).__name__}"
```

## 共通ユーティリティ

共通の機能を再利用可能な関数に抽出してください:

```python
# Shared API request function
async def _make_api_request(endpoint: str, method: str = "GET", **kwargs) -> dict:
    '''Reusable function for all API calls.'''
    async with httpx.AsyncClient() as client:
        response = await client.request(
            method,
            f"{API_BASE_URL}/{endpoint}",
            timeout=30.0,
            **kwargs
        )
        response.raise_for_status()
        return response.json()
```

## Async/Await のベストプラクティス

ネットワークリクエストと I/O 操作には常に async/await を使用してください:

```python
# Good: Async network request
async def fetch_data(resource_id: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{API_URL}/resource/{resource_id}")
        response.raise_for_status()
        return response.json()

# Bad: Synchronous request
def fetch_data(resource_id: str) -> dict:
    response = requests.get(f"{API_URL}/resource/{resource_id}")  # Blocks
    return response.json()
```

## 型ヒント

コード全体で型ヒントを使用してください:

```python
from typing import Optional, List, Dict, Any

async def get_user(user_id: str) -> Dict[str, Any]:
    data = await fetch_user(user_id)
    return {"id": data["id"], "name": data["name"]}
```

## ツールの docstring

すべてのツールは、明示的な型情報を含む包括的な docstring を持つ必要があります:

```python
async def search_users(params: UserSearchInput) -> str:
    '''
    Search for users in the Example system by name, email, or team.

    This tool searches across all user profiles in the Example platform,
    supporting partial matches and various search filters. It does NOT
    create or modify users, only searches existing ones.

    Args:
        params (UserSearchInput): Validated input parameters containing:
            - query (str): Search string to match against names/emails (e.g., "john", "@example.com", "team:marketing")
            - limit (Optional[int]): Maximum results to return, between 1-100 (default: 20)
            - offset (Optional[int]): Number of results to skip for pagination (default: 0)

    Returns:
        str: JSON-formatted string containing search results with the following schema:

        Success response:
        {
            "total": int,           # Total number of matches found
            "count": int,           # Number of results in this response
            "offset": int,          # Current pagination offset
            "users": [
                {
                    "id": str,      # User ID (e.g., "U123456789")
                    "name": str,    # Full name (e.g., "John Doe")
                    "email": str,   # Email address (e.g., "john@example.com")
                    "team": str     # Team name (e.g., "Marketing") - optional
                }
            ]
        }

        Error response:
        "Error: <error message>" or "No users found matching '<query>'"

    Examples:
        - Use when: "Find all marketing team members" -> params with query="team:marketing"
        - Use when: "Search for John's account" -> params with query="john"
        - Don't use when: You need to create a user (use example_create_user instead)
        - Don't use when: You have a user ID and need full details (use example_get_user instead)

    Error Handling:
        - Input validation errors are handled by Pydantic model
        - Returns "Error: Rate limit exceeded" if too many requests (429 status)
        - Returns "Error: Invalid API authentication" if API key is invalid (401 status)
        - Returns formatted list of results or "No users found matching 'query'"
    '''
```

## 完全な例

完全な Python MCP サーバーの例は以下を参照してください:

```python
#!/usr/bin/env python3
'''
MCP Server for Example Service.

This server provides tools to interact with Example API, including user search,
project management, and data export capabilities.
'''

from typing import Optional, List, Dict, Any
from enum import Enum
import httpx
from pydantic import BaseModel, Field, field_validator, ConfigDict
from mcp.server.fastmcp import FastMCP

# Initialize the MCP server
mcp = FastMCP("example_mcp")

# Constants
API_BASE_URL = "https://api.example.com/v1"

# Enums
class ResponseFormat(str, Enum):
    '''Output format for tool responses.'''
    MARKDOWN = "markdown"
    JSON = "json"

# Pydantic Models for Input Validation
class UserSearchInput(BaseModel):
    '''Input model for user search operations.'''
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True
    )

    query: str = Field(..., description="Search string to match against names/emails", min_length=2, max_length=200)
    limit: Optional[int] = Field(default=20, description="Maximum results to return", ge=1, le=100)
    offset: Optional[int] = Field(default=0, description="Number of results to skip for pagination", ge=0)
    response_format: ResponseFormat = Field(default=ResponseFormat.MARKDOWN, description="Output format")

    @field_validator('query')
    @classmethod
    def validate_query(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Query cannot be empty or whitespace only")
        return v.strip()

# Shared utility functions
async def _make_api_request(endpoint: str, method: str = "GET", **kwargs) -> dict:
    '''Reusable function for all API calls.'''
    async with httpx.AsyncClient() as client:
        response = await client.request(
            method,
            f"{API_BASE_URL}/{endpoint}",
            timeout=30.0,
            **kwargs
        )
        response.raise_for_status()
        return response.json()

def _handle_api_error(e: Exception) -> str:
    '''Consistent error formatting across all tools.'''
    if isinstance(e, httpx.HTTPStatusError):
        if e.response.status_code == 404:
            return "Error: Resource not found. Please check the ID is correct."
        elif e.response.status_code == 403:
            return "Error: Permission denied. You don't have access to this resource."
        elif e.response.status_code == 429:
            return "Error: Rate limit exceeded. Please wait before making more requests."
        return f"Error: API request failed with status {e.response.status_code}"
    elif isinstance(e, httpx.TimeoutException):
        return "Error: Request timed out. Please try again."
    return f"Error: Unexpected error occurred: {type(e).__name__}"

# Tool definitions
@mcp.tool(
    name="example_search_users",
    annotations={
        "title": "Search Example Users",
        "readOnlyHint": True,
        "destructiveHint": False,
        "idempotentHint": True,
        "openWorldHint": True
    }
)
async def example_search_users(params: UserSearchInput) -> str:
    '''Search for users in the Example system by name, email, or team.

    [Full docstring as shown above]
    '''
    try:
        # Make API request using validated parameters
        data = await _make_api_request(
            "users/search",
            params={
                "q": params.query,
                "limit": params.limit,
                "offset": params.offset
            }
        )

        users = data.get("users", [])
        total = data.get("total", 0)

        if not users:
            return f"No users found matching '{params.query}'"

        # Format response based on requested format
        if params.response_format == ResponseFormat.MARKDOWN:
            lines = [f"# User Search Results: '{params.query}'", ""]
            lines.append(f"Found {total} users (showing {len(users)})")
            lines.append("")

            for user in users:
                lines.append(f"## {user['name']} ({user['id']})")
                lines.append(f"- **Email**: {user['email']}")
                if user.get('team'):
                    lines.append(f"- **Team**: {user['team']}")
                lines.append("")

            return "\n".join(lines)

        else:
            # Machine-readable JSON format
            import json
            response = {
                "total": total,
                "count": len(users),
                "offset": params.offset,
                "users": users
            }
            return json.dumps(response, indent=2)

    except Exception as e:
        return _handle_api_error(e)

if __name__ == "__main__":
    mcp.run()
```

---

## 高度な FastMCP 機能

### Context パラメータの注入

FastMCP は、ログ記録、進捗報告、リソース読み取り、ユーザーとの対話などの高度な機能を実現するために、ツールへ `Context` パラメータを自動的に注入できます:

```python
from mcp.server.fastmcp import FastMCP, Context

mcp = FastMCP("example_mcp")

@mcp.tool()
async def advanced_search(query: str, ctx: Context) -> str:
    '''Advanced tool with context access for logging and progress.'''

    # Report progress for long operations
    await ctx.report_progress(0.25, "Starting search...")

    # Log information for debugging
    await ctx.log_info("Processing query", {"query": query, "timestamp": datetime.now()})

    # Perform search
    results = await search_api(query)
    await ctx.report_progress(0.75, "Formatting results...")

    # Access server configuration
    server_name = ctx.fastmcp.name

    return format_results(results)

@mcp.tool()
async def interactive_tool(resource_id: str, ctx: Context) -> str:
    '''Tool that can request additional input from users.'''

    # Request sensitive information when needed
    api_key = await ctx.elicit(
        prompt="Please provide your API key:",
        input_type="password"
    )

    # Use the provided key
    return await api_call(resource_id, api_key)
```

**Context の機能:**
- `ctx.report_progress(progress, message)` - 長時間の操作の進捗を報告
- `ctx.log_info(message, data)` / `ctx.log_error()` / `ctx.log_debug()` - ログ記録
- `ctx.elicit(prompt, input_type)` - ユーザーに入力を要求
- `ctx.fastmcp.name` - サーバー設定にアクセス
- `ctx.read_resource(uri)` - MCP リソースを読み取り

### リソース登録

データをリソースとして公開し、テンプレートベースの効率的なアクセスを実現します:

```python
@mcp.resource("file://documents/{name}")
async def get_document(name: str) -> str:
    '''Expose documents as MCP resources.

    Resources are useful for static or semi-static data that doesn't
    require complex parameters. They use URI templates for flexible access.
    '''
    document_path = f"./docs/{name}"
    with open(document_path, "r") as f:
        return f.read()

@mcp.resource("config://settings/{key}")
async def get_setting(key: str, ctx: Context) -> str:
    '''Expose configuration as resources with context.'''
    settings = await load_settings()
    return json.dumps(settings.get(key, {}))
```

**リソースとツールの使い分け:**
- **リソース**: 単純なパラメータ（URI テンプレート）によるデータアクセス向け
- **ツール**: 検証とビジネスロジックを伴う複雑な操作向け

### 構造化された出力タイプ

FastMCP は文字列以外にも複数の戻り値タイプをサポートします:

```python
from typing import TypedDict
from dataclasses import dataclass
from pydantic import BaseModel

# TypedDict for structured returns
class UserData(TypedDict):
    id: str
    name: str
    email: str

@mcp.tool()
async def get_user_typed(user_id: str) -> UserData:
    '''Returns structured data - FastMCP handles serialization.'''
    return {"id": user_id, "name": "John Doe", "email": "john@example.com"}

# Pydantic models for complex validation
class DetailedUser(BaseModel):
    id: str
    name: str
    email: str
    created_at: datetime
    metadata: Dict[str, Any]

@mcp.tool()
async def get_user_detailed(user_id: str) -> DetailedUser:
    '''Returns Pydantic model - automatically generates schema.'''
    user = await fetch_user(user_id)
    return DetailedUser(**user)
```

### ライフスパン管理

リクエストをまたいで保持されるリソースを初期化します:

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def app_lifespan():
    '''Manage resources that live for the server's lifetime.'''
    # Initialize connections, load config, etc.
    db = await connect_to_database()
    config = load_configuration()

    # Make available to all tools
    yield {"db": db, "config": config}

    # Cleanup on shutdown
    await db.close()

mcp = FastMCP("example_mcp", lifespan=app_lifespan)

@mcp.tool()
async def query_data(query: str, ctx: Context) -> str:
    '''Access lifespan resources through context.'''
    db = ctx.request_context.lifespan_state["db"]
    results = await db.query(query)
    return format_results(results)
```

### トランスポートのオプション

FastMCP は2つの主要なトランスポート方式をサポートします:

```python
# stdio transport (for local tools) - default
if __name__ == "__main__":
    mcp.run()

# Streamable HTTP transport (for remote servers)
if __name__ == "__main__":
    mcp.run(transport="streamable_http", port=8000)
```

**トランスポートの選定:**
- **stdio**: コマンドラインツール、ローカル統合、サブプロセス実行
- **Streamable HTTP**: ウェブサービス、リモートアクセス、複数クライアント

---

## コードのベストプラクティス

### コードの合成性と再利用性

実装では、合成性とコードの再利用を最優先する必要があります:

1. **共通機能の抽出**:
   - 複数のツールで使用される操作のための再利用可能なヘルパー関数を作成
   - コードを複製せず、HTTP リクエスト用の共有 API クライアントを構築
   - エラーハンドリングのロジックをユーティリティ関数に集約
   - ビジネスロジックを合成可能な専用関数に抽出
   - markdown または JSON の共通フィールド選択・整形機能を抽出

2. **重複の回避**:
   - ツール間で類似コードをコピーペーストしない
   - 同じようなロジックを2回書いていることに気づいたら、関数に抽出する
   - ページネーション、フィルタリング、フィールド選択、整形などの共通操作は共有する
   - 認証・認可のロジックは集中管理する

### Python 固有のベストプラクティス

1. **型ヒントを使用**: 関数のパラメータと戻り値には常に型アノテーションを含める
2. **Pydantic モデル**: すべての入力検証に明確な Pydantic モデルを定義する
3. **手動検証を避ける**: Pydantic に制約付きの入力検証を任せる
4. **適切なインポート**: インポートをグループ化する（標準ライブラリ、サードパーティ、ローカル）
5. **エラーハンドリング**: 具体的な例外タイプを使用する（汎用的な Exception ではなく httpx.HTTPStatusError）
6. **非同期コンテキストマネージャ**: クリーンアップが必要なリソースには `async with` を使用する
7. **定数**: モジュールレベルの定数を UPPER_CASE で定義する

## 品質チェックリスト

Python MCP サーバーの実装を完了する前に、以下を確認してください:

### 戦略的設計
- [ ] ツールが単なる API エンドポイントのラッパーではなく、完全なワークフローを実現する
- [ ] ツール名が自然なタスクの分割を反映している
- [ ] レスポンス形式がエージェントのコンテキスト効率に最適化されている
- [ ] 適切な箇所で人間が読みやすい識別子が使用されている
- [ ] エラーメッセージがエージェントを正しい使い方へ導く

### 実装品質
- [ ] 焦点を絞った実装: 最も重要で価値のあるツールが実装されている
- [ ] すべてのツールに説明的な名前とドキュメントがある
- [ ] 類似操作間で戻り値の型が一貫している
- [ ] すべての外部呼び出しにエラーハンドリングが実装されている
- [ ] サーバー名が `{service}_mcp` 形式に従っている
- [ ] すべてのネットワーク操作が async/await を使用している
- [ ] 共通機能が再利用可能な関数に抽出されている
- [ ] エラーメッセージが明確で、実行可能で、教育的である
- [ ] 出力が適切に検証・整形されている

### ツール設定
- [ ] すべてのツールがデコレータで 'name' と 'annotations' を実装している
- [ ] アノテーションが正しく設定されている (readOnlyHint、destructiveHint、idempotentHint、openWorldHint)
- [ ] すべてのツールが Field() 定義付きの Pydantic BaseModel を入力検証に使用している
- [ ] すべての Pydantic フィールドに明示的な型と制約付きの説明がある
- [ ] すべてのツールに明示的な入出力タイプを含む包括的な docstring がある
- [ ] docstring に dict/JSON 戻り値の完全なスキーマ構造が含まれている
- [ ] Pydantic モデルが入力検証を処理している（手動検証が不要）

### 高度な機能（該当する場合）
- [ ] ログ記録、進捗、または elicit に Context 注入が使用されている
- [ ] 適切なデータエンドポイントにリソースが登録されている
- [ ] 永続的な接続のためにライフスパン管理が実装されている
- [ ] 構造化された出力タイプが使用されている (TypedDict、Pydantic モデル)
- [ ] 適切なトランスポートが設定されている（stdio または streamable HTTP）

### コード品質
- [ ] ファイルに Pydantic のインポートを含む適切なインポートがある
- [ ] 該当する箇所でページネーションが適切に実装されている
- [ ] 潜在的に大きい結果セットに対してフィルタリングオプションが提供されている
- [ ] すべての非同期関数が `async def` で適切に定義されている
- [ ] HTTP クライアントの使用が適切なコンテキストマネージャを伴う非同期パターンに従っている
- [ ] コード全体で型ヒントが使用されている
- [ ] 定数がモジュールレベルで UPPER_CASE で定義されている

### テスト
- [ ] サーバーが正常に実行される: `python your_server.py --help`
- [ ] すべてのインポートが正しく解決される
- [ ] サンプルのツール呼び出しが期待どおりに動作する
- [ ] エラーシナリオが適切に処理される