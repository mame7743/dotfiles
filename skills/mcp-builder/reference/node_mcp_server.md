# Node/TypeScript MCP サーバー実装ガイド

## 概要

このドキュメントでは、MCP TypeScript SDK を使用して MCP サーバーを実装するための Node/TypeScript 固有のベストプラクティスと例を紹介します。プロジェクト構造、サーバーのセットアップ、ツール登録のパターン、Zod による入力検証、エラーハンドリング、完全な動作例を扱います。

---

## クイックリファレンス

### 主要なインポート
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import express from "express";
import { z } from "zod";
```

### サーバーの初期化
```typescript
const server = new McpServer({
  name: "service-mcp-server",
  version: "1.0.0"
});
```

### ツール登録のパターン
```typescript
server.registerTool(
  "tool_name",
  {
    title: "Tool Display Name",
    description: "What the tool does",
    inputSchema: { param: z.string() },
    outputSchema: { result: z.string() }
  },
  async ({ param }) => {
    const output = { result: `Processed: ${param}` };
    return {
      content: [{ type: "text", text: JSON.stringify(output) }],
      structuredContent: output // Modern pattern for structured data
    };
  }
);
```

---

## MCP TypeScript SDK

公式の MCP TypeScript SDK が提供するもの:
- サーバー初期化用の `McpServer` クラス
- ツール登録用の `registerTool` メソッド
- 実行時入力検証のための Zod スキーマ統合
- 型安全なツールハンドラの実装

**重要 - 最新の API のみを使用:**
- **使用する**: `server.registerTool()`、`server.registerResource()`、`server.registerPrompt()`
- **使用しない**: `server.tool()`、`server.setRequestHandler(ListToolsRequestSchema, ...)` などの古い非推奨 API、または手動のハンドラ登録
- `register*` メソッドは優れた型安全性と自動スキーマ処理を提供し、推奨されるアプローチです

詳細は、リファレンス内の MCP SDK ドキュメントを参照してください。

## サーバーの命名規則

Node/TypeScript の MCP サーバーは、この命名パターンに従う必要があります:
- **形式**: `{service}-mcp-server`（小文字とハイフン）
- **例**: `github-mcp-server`、`jira-mcp-server`、`stripe-mcp-server`

名前は以下を満たす必要があります:
- 汎用的であること（特定の機能に紐づかない）
- 統合するサービス/API を表すこと
- タスクの説明から推測しやすいこと
- バージョン番号や日付を含まないこと

## プロジェクト構造

Node/TypeScript の MCP サーバーには、次の構造を作成してください:

```
{service}-mcp-server/
├── package.json
├── tsconfig.json
├── README.md
├── src/
│   ├── index.ts          # Main entry point with McpServer initialization
│   ├── types.ts          # TypeScript type definitions and interfaces
│   ├── tools/            # Tool implementations (one file per domain)
│   ├── services/         # API clients and shared utilities
│   ├── schemas/          # Zod validation schemas
│   └── constants.ts      # Shared constants (API_URL, CHARACTER_LIMIT, etc.)
└── dist/                 # Built JavaScript files (entry point: dist/index.js)
```

## ツールの実装

### ツールの命名

ツール名は snake_case を使用し（例: "search_users"、"create_project"、"get_channel_info"）、明確でアクション指向の名前にします。

**命名の衝突を避ける**: 重複を防ぐためにサービスのコンテキストを含めてください:
- "send_message" だけでなく "slack_send_message" を使用
- "create_issue" だけでなく "github_create_issue" を使用
- "list_tasks" だけでなく "asana_list_tasks" を使用

### ツール構造

ツールは `registerTool` メソッドを使用して登録し、以下の要件を満たす必要があります:
- 実行時入力検証と型安全性のために Zod スキーマを使用
- `description` フィールドは明示的に指定する必要がある - JSDoc コメントは自動抽出されない
- `title`、`description`、`inputSchema`、`annotations` を明示的に指定
- `inputSchema` は Zod スキーマオブジェクトである必要がある（JSON スキーマは不可）
- すべてのパラメータと戻り値を明示的に型指定

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

const server = new McpServer({
  name: "example-mcp",
  version: "1.0.0"
});

// Zod schema for input validation
const UserSearchInputSchema = z.object({
  query: z.string()
    .min(2, "Query must be at least 2 characters")
    .max(200, "Query must not exceed 200 characters")
    .describe("Search string to match against names/emails"),
  limit: z.number()
    .int()
    .min(1)
    .max(100)
    .default(20)
    .describe("Maximum results to return"),
  offset: z.number()
    .int()
    .min(0)
    .default(0)
    .describe("Number of results to skip for pagination"),
  response_format: z.nativeEnum(ResponseFormat)
    .default(ResponseFormat.MARKDOWN)
    .describe("Output format: 'markdown' for human-readable or 'json' for machine-readable")
}).strict();

// Type definition from Zod schema
type UserSearchInput = z.infer<typeof UserSearchInputSchema>;

server.registerTool(
  "example_search_users",
  {
    title: "Search Example Users",
    description: `Search for users in the Example system by name, email, or team.

This tool searches across all user profiles in the Example platform, supporting partial matches and various search filters. It does NOT create or modify users, only searches existing ones.

Args:
  - query (string): Search string to match against names/emails
  - limit (number): Maximum results to return, between 1-100 (default: 20)
  - offset (number): Number of results to skip for pagination (default: 0)
  - response_format ('markdown' | 'json'): Output format (default: 'markdown')

Returns:
  For JSON format: Structured data with schema:
  {
    "total": number,           // Total number of matches found
    "count": number,           // Number of results in this response
    "offset": number,          // Current pagination offset
    "users": [
      {
        "id": string,          // User ID (e.g., "U123456789")
        "name": string,        // Full name (e.g., "John Doe")
        "email": string,       // Email address
        "team": string,        // Team name (optional)
        "active": boolean      // Whether user is active
      }
    ],
    "has_more": boolean,       // Whether more results are available
    "next_offset": number      // Offset for next page (if has_more is true)
  }

Examples:
  - Use when: "Find all marketing team members" -> params with query="team:marketing"
  - Use when: "Search for John's account" -> params with query="john"
  - Don't use when: You need to create a user (use example_create_user instead)

Error Handling:
  - Returns "Error: Rate limit exceeded" if too many requests (429 status)
  - Returns "No users found matching '<query>'" if search returns empty`,
    inputSchema: UserSearchInputSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: true
    }
  },
  async (params: UserSearchInput) => {
    try {
      // Input validation is handled by Zod schema
      // Make API request using validated parameters
      const data = await makeApiRequest<any>(
        "users/search",
        "GET",
        undefined,
        {
          q: params.query,
          limit: params.limit,
          offset: params.offset
        }
      );

      const users = data.users || [];
      const total = data.total || 0;

      if (!users.length) {
        return {
          content: [{
            type: "text",
            text: `No users found matching '${params.query}'`
          }]
        };
      }

      // Prepare structured output
      const output = {
        total,
        count: users.length,
        offset: params.offset,
        users: users.map((user: any) => ({
          id: user.id,
          name: user.name,
          email: user.email,
          ...(user.team ? { team: user.team } : {}),
          active: user.active ?? true
        })),
        has_more: total > params.offset + users.length,
        ...(total > params.offset + users.length ? {
          next_offset: params.offset + users.length
        } : {})
      };

      // Format text representation based on requested format
      let textContent: string;
      if (params.response_format === ResponseFormat.MARKDOWN) {
        const lines = [`# User Search Results: '${params.query}'`, "",
          `Found ${total} users (showing ${users.length})`, ""];
        for (const user of users) {
          lines.push(`## ${user.name} (${user.id})`);
          lines.push(`- **Email**: ${user.email}`);
          if (user.team) lines.push(`- **Team**: ${user.team}`);
          lines.push("");
        }
        textContent = lines.join("\n");
      } else {
        textContent = JSON.stringify(output, null, 2);
      }

      return {
        content: [{ type: "text", text: textContent }],
        structuredContent: output // Modern pattern for structured data
      };
    } catch (error) {
      return {
        content: [{
          type: "text",
          text: handleApiError(error)
        }]
      };
    }
  }
);
```

## 入力検証のための Zod スキーマ

Zod は実行時の型検証を提供します:

```typescript
import { z } from "zod";

// Basic schema with validation
const CreateUserSchema = z.object({
  name: z.string()
    .min(1, "Name is required")
    .max(100, "Name must not exceed 100 characters"),
  email: z.string()
    .email("Invalid email format"),
  age: z.number()
    .int("Age must be a whole number")
    .min(0, "Age cannot be negative")
    .max(150, "Age cannot be greater than 150")
}).strict();  // Use .strict() to forbid extra fields

// Enums
enum ResponseFormat {
  MARKDOWN = "markdown",
  JSON = "json"
}

const SearchSchema = z.object({
  response_format: z.nativeEnum(ResponseFormat)
    .default(ResponseFormat.MARKDOWN)
    .describe("Output format")
});

// Optional fields with defaults
const PaginationSchema = z.object({
  limit: z.number()
    .int()
    .min(1)
    .max(100)
    .default(20)
    .describe("Maximum results to return"),
  offset: z.number()
    .int()
    .min(0)
    .default(0)
    .describe("Number of results to skip")
});
```

## レスポンス形式のオプション

柔軟性のため、複数の出力形式をサポートしてください:

```typescript
enum ResponseFormat {
  MARKDOWN = "markdown",
  JSON = "json"
}

const inputSchema = z.object({
  query: z.string(),
  response_format: z.nativeEnum(ResponseFormat)
    .default(ResponseFormat.MARKDOWN)
    .describe("Output format: 'markdown' for human-readable or 'json' for machine-readable")
});
```

**Markdown 形式**:
- 見出し、リスト、書式を使用して明確にする
- タイムスタンプを人間が読みやすい形式に変換
- 表示名と ID を括弧付きで表示
- 冗長なメタデータは省略
- 関連情報を論理的にグループ化

**JSON 形式**:
- プログラムによる処理に適した、完全で構造化されたデータを返す
- 利用可能なすべてのフィールドとメタデータを含める
- 一貫したフィールド名と型を使用

## ページネーションの実装

リソースを一覧表示するツール向け:

```typescript
const ListSchema = z.object({
  limit: z.number().int().min(1).max(100).default(20),
  offset: z.number().int().min(0).default(0)
});

async function listItems(params: z.infer<typeof ListSchema>) {
  const data = await apiRequest(params.limit, params.offset);

  const response = {
    total: data.total,
    count: data.items.length,
    offset: params.offset,
    items: data.items,
    has_more: data.total > params.offset + data.items.length,
    next_offset: data.total > params.offset + data.items.length
      ? params.offset + data.items.length
      : undefined
  };

  return JSON.stringify(response, null, 2);
}
```

## 文字数制限と切り詰め

レスポンスが過剰になるのを防ぐために CHARACTER_LIMIT 定数を追加してください:

```typescript
// At module level in constants.ts
export const CHARACTER_LIMIT = 25000;  // Maximum response size in characters

async function searchTool(params: SearchInput) {
  let result = generateResponse(data);

  // Check character limit and truncate if needed
  if (result.length > CHARACTER_LIMIT) {
    const truncatedData = data.slice(0, Math.max(1, data.length / 2));
    response.data = truncatedData;
    response.truncated = true;
    response.truncation_message =
      `Response truncated from ${data.length} to ${truncatedData.length} items. ` +
      `Use 'offset' parameter or add filters to see more results.`;
    result = JSON.stringify(response, null, 2);
  }

  return result;
}
```

## エラーハンドリング

明確で実行可能なエラーメッセージを提供してください:

```typescript
import axios, { AxiosError } from "axios";

function handleApiError(error: unknown): string {
  if (error instanceof AxiosError) {
    if (error.response) {
      switch (error.response.status) {
        case 404:
          return "Error: Resource not found. Please check the ID is correct.";
        case 403:
          return "Error: Permission denied. You don't have access to this resource.";
        case 429:
          return "Error: Rate limit exceeded. Please wait before making more requests.";
        default:
          return `Error: API request failed with status ${error.response.status}`;
      }
    } else if (error.code === "ECONNABORTED") {
      return "Error: Request timed out. Please try again.";
    }
  }
  return `Error: Unexpected error occurred: ${error instanceof Error ? error.message : String(error)}`;
}
```

## 共通ユーティリティ

共通の機能を再利用可能な関数に抽出してください:

```typescript
// Shared API request function
async function makeApiRequest<T>(
  endpoint: string,
  method: "GET" | "POST" | "PUT" | "DELETE" = "GET",
  data?: any,
  params?: any
): Promise<T> {
  try {
    const response = await axios({
      method,
      url: `${API_BASE_URL}/${endpoint}`,
      data,
      params,
      timeout: 30000,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      }
    });
    return response.data;
  } catch (error) {
    throw error;
  }
}
```

## Async/Await のベストプラクティス

ネットワークリクエストと I/O 操作には常に async/await を使用してください:

```typescript
// Good: Async network request
async function fetchData(resourceId: string): Promise<ResourceData> {
  const response = await axios.get(`${API_URL}/resource/${resourceId}`);
  return response.data;
}

// Bad: Promise chains
function fetchData(resourceId: string): Promise<ResourceData> {
  return axios.get(`${API_URL}/resource/${resourceId}`)
    .then(response => response.data);  // Harder to read and maintain
}
```

## TypeScript のベストプラクティス

1. **Strict TypeScript を使用**: tsconfig.json で strict モードを有効にする
2. **インターフェースを定義**: すべてのデータ構造に明確なインターフェース定義を作成する
3. **`any` を避ける**: `any` の代わりに適切な型または `unknown` を使用する
4. **実行時検証には Zod**: Zod スキーマを使用して外部データを検証する
5. **型ガード**: 複雑な型チェックのための型ガード関数を作成する
6. **エラーハンドリング**: 適切なエラーの型チェックを伴う try-catch を常に使用する
7. **Null 安全性**: オプショナルチェイニング（`?.`）と null 合体演算子（`??`）を使用する

```typescript
// Good: Type-safe with Zod and interfaces
interface UserResponse {
  id: string;
  name: string;
  email: string;
  team?: string;
  active: boolean;
}

const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
  team: z.string().optional(),
  active: z.boolean()
});

type User = z.infer<typeof UserSchema>;

async function getUser(id: string): Promise<User> {
  const data = await apiCall(`/users/${id}`);
  return UserSchema.parse(data);  // Runtime validation
}

// Bad: Using any
async function getUser(id: string): Promise<any> {
  return await apiCall(`/users/${id}`);  // No type safety
}
```

## パッケージ設定

### package.json

```json
{
  "name": "{service}-mcp-server",
  "version": "1.0.0",
  "description": "MCP server for {Service} API integration",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "clean": "rm -rf dist"
  },
  "engines": {
    "node": ">=18"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.6.1",
    "axios": "^1.7.9",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/node": "^22.10.0",
    "tsx": "^4.19.2",
    "typescript": "^5.7.2"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "allowSyntheticDefaultImports": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## 完全な例

```typescript
#!/usr/bin/env node
/**
 * MCP Server for Example Service.
 *
 * This server provides tools to interact with Example API, including user search,
 * project management, and data export capabilities.
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import axios, { AxiosError } from "axios";

// Constants
const API_BASE_URL = "https://api.example.com/v1";
const CHARACTER_LIMIT = 25000;

// Enums
enum ResponseFormat {
  MARKDOWN = "markdown",
  JSON = "json"
}

// Zod schemas
const UserSearchInputSchema = z.object({
  query: z.string()
    .min(2, "Query must be at least 2 characters")
    .max(200, "Query must not exceed 200 characters")
    .describe("Search string to match against names/emails"),
  limit: z.number()
    .int()
    .min(1)
    .max(100)
    .default(20)
    .describe("Maximum results to return"),
  offset: z.number()
    .int()
    .min(0)
    .default(0)
    .describe("Number of results to skip for pagination"),
  response_format: z.nativeEnum(ResponseFormat)
    .default(ResponseFormat.MARKDOWN)
    .describe("Output format: 'markdown' for human-readable or 'json' for machine-readable")
}).strict();

type UserSearchInput = z.infer<typeof UserSearchInputSchema>;

// Shared utility functions
async function makeApiRequest<T>(
  endpoint: string,
  method: "GET" | "POST" | "PUT" | "DELETE" = "GET",
  data?: any,
  params?: any
): Promise<T> {
  try {
    const response = await axios({
      method,
      url: `${API_BASE_URL}/${endpoint}`,
      data,
      params,
      timeout: 30000,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      }
    });
    return response.data;
  } catch (error) {
    throw error;
  }
}

function handleApiError(error: unknown): string {
  if (error instanceof AxiosError) {
    if (error.response) {
      switch (error.response.status) {
        case 404:
          return "Error: Resource not found. Please check the ID is correct.";
        case 403:
          return "Error: Permission denied. You don't have access to this resource.";
        case 429:
          return "Error: Rate limit exceeded. Please wait before making more requests.";
        default:
          return `Error: API request failed with status ${error.response.status}`;
      }
    } else if (error.code === "ECONNABORTED") {
      return "Error: Request timed out. Please try again.";
    }
  }
  return `Error: Unexpected error occurred: ${error instanceof Error ? error.message : String(error)}`;
}

// Create MCP server instance
const server = new McpServer({
  name: "example-mcp",
  version: "1.0.0"
});

// Register tools
server.registerTool(
  "example_search_users",
  {
    title: "Search Example Users",
    description: `[Full description as shown above]`,
    inputSchema: UserSearchInputSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: true
    }
  },
  async (params: UserSearchInput) => {
    // Implementation as shown above
  }
);

// Main function
// For stdio (local):
async function runStdio() {
  if (!process.env.EXAMPLE_API_KEY) {
    console.error("ERROR: EXAMPLE_API_KEY environment variable is required");
    process.exit(1);
  }

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MCP server running via stdio");
}

// For streamable HTTP (remote):
async function runHTTP() {
  if (!process.env.EXAMPLE_API_KEY) {
    console.error("ERROR: EXAMPLE_API_KEY environment variable is required");
    process.exit(1);
  }

  const app = express();
  app.use(express.json());

  app.post('/mcp', async (req, res) => {
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined,
      enableJsonResponse: true
    });
    res.on('close', () => transport.close());
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  });

  const port = parseInt(process.env.PORT || '3000');
  app.listen(port, () => {
    console.error(`MCP server running on http://localhost:${port}/mcp`);
  });
}

// Choose transport based on environment
const transport = process.env.TRANSPORT || 'stdio';
if (transport === 'http') {
  runHTTP().catch(error => {
    console.error("Server error:", error);
    process.exit(1);
  });
} else {
  runStdio().catch(error => {
    console.error("Server error:", error);
    process.exit(1);
  });
}
```

---

## 高度な MCP 機能

### リソース登録

データをリソースとして公開し、URI ベースの効率的なアクセスを実現します:

```typescript
import { ResourceTemplate } from "@modelcontextprotocol/sdk/types.js";

// Register a resource with URI template
server.registerResource(
  {
    uri: "file://documents/{name}",
    name: "Document Resource",
    description: "Access documents by name",
    mimeType: "text/plain"
  },
  async (uri: string) => {
    // Extract parameter from URI
    const match = uri.match(/^file:\/\/documents\/(.+)$/);
    if (!match) {
      throw new Error("Invalid URI format");
    }

    const documentName = match[1];
    const content = await loadDocument(documentName);

    return {
      contents: [{
        uri,
        mimeType: "text/plain",
        text: content
      }]
    };
  }
);

// List available resources dynamically
server.registerResourceList(async () => {
  const documents = await getAvailableDocuments();
  return {
    resources: documents.map(doc => ({
      uri: `file://documents/${doc.name}`,
      name: doc.name,
      mimeType: "text/plain",
      description: doc.description
    }))
  };
});
```

**リソースとツールの使い分け:**
- **リソース**: 単純な URI ベースのパラメータによるデータアクセス向け
- **ツール**: 検証とビジネスロジックが必要な複雑な操作向け
- **リソース**: データが比較的静的な場合やテンプレートベースの場合
- **ツール**: 操作に副作用がある場合や複雑なワークフローを伴う場合

### トランスポートのオプション

TypeScript SDK は2つの主要なトランスポート方式をサポートします:

#### Streamable HTTP（リモートサーバー向けに推奨）

```typescript
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import express from "express";

const app = express();
app.use(express.json());

app.post('/mcp', async (req, res) => {
  // Create new transport for each request (stateless, prevents request ID collisions)
  const transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: undefined,
    enableJsonResponse: true
  });

  res.on('close', () => transport.close());

  await server.connect(transport);
  await transport.handleRequest(req, res, req.body);
});

app.listen(3000);
```

#### stdio（ローカル統合向け）

```typescript
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const transport = new StdioServerTransport();
await server.connect(transport);
```

**トランスポートの選定:**
- **Streamable HTTP**: ウェブサービス、リモートアクセス、複数クライアント
- **stdio**: コマンドラインツール、ローカル開発、サブプロセス統合

### 通知のサポート

サーバーの状態が変化したときにクライアントへ通知します:

```typescript
// Notify when tools list changes
server.notification({
  method: "notifications/tools/list_changed"
});

// Notify when resources change
server.notification({
  method: "notifications/resources/list_changed"
});
```

通知は控えめに使用してください。サーバーの機能が実際に変化した場合のみです。

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

## ビルドと実行

実行前に必ず TypeScript コードをビルドしてください:

```bash
# Build the project
npm run build

# Run the server
npm start

# Development with auto-reload
npm run dev
```

実装を完了と見なす前に、`npm run build` が成功することを常に確認してください。

## 品質チェックリスト

Node/TypeScript の MCP サーバーの実装を完了する前に、以下を確認してください:

### 戦略的設計
- [ ] ツールが単なる API エンドポイントのラッパーではなく、完全なワークフローを実現する
- [ ] ツール名が自然なタスクの分割を反映している
- [ ] レスポンス形式がエージェントのコンテキスト効率に最適化されている
- [ ] 適切な箇所で人間が読みやすい識別子が使用されている
- [ ] エラーメッセージがエージェントを正しい使い方へ導く

### 実装品質
- [ ] 焦点を絞った実装: 最も重要で価値のあるツールが実装されている
- [ ] すべてのツールが完全な設定で `registerTool` を使用して登録されている
- [ ] すべてのツールに `title`、`description`、`inputSchema`、`annotations` が含まれている
- [ ] アノテーションが正しく設定されている (readOnlyHint、destructiveHint、idempotentHint、openWorldHint)
- [ ] すべてのツールが `.strict()` を適用した Zod スキーマを実行時入力検証に使用している
- [ ] すべての Zod スキーマに適切な制約と説明的なエラーメッセージがある
- [ ] すべてのツールに明示的な入出力タイプを含む包括的な説明がある
- [ ] 説明に戻り値の例と完全なスキーマドキュメントが含まれている
- [ ] エラーメッセージが明確で、実行可能で、教育的である

### TypeScript 品質
- [ ] すべてのデータ構造に TypeScript インターフェースが定義されている
- [ ] tsconfig.json で strict TypeScript が有効になっている
- [ ] `any` 型を使用していない - 代わりに `unknown` または適切な型を使用している
- [ ] すべての非同期関数に明示的な Promise<T> の戻り値型がある
- [ ] エラーハンドリングが適切な型ガードを使用している（例: `axios.isAxiosError`、`z.ZodError`）

### 高度な機能（該当する場合）
- [ ] 適切なデータエンドポイントにリソースが登録されている
- [ ] 適切なトランスポートが設定されている（stdio または streamable HTTP）
- [ ] 動的なサーバー機能のために通知が実装されている
- [ ] SDK のインターフェースで型安全になっている

### プロジェクト設定
- [ ] package.json に必要な依存関係がすべて含まれている
- [ ] ビルドスクリプトが dist/ ディレクトリに動作する JavaScript を生成する
- [ ] メインエントリポイントが dist/index.js として適切に設定されている
- [ ] サーバー名が `{service}-mcp-server` 形式に従っている
- [ ] tsconfig.json が strict モードで適切に設定されている

### コード品質
- [ ] 該当する箇所でページネーションが適切に実装されている
- [ ] 大きなレスポンスが CHARACTER_LIMIT 定数を確認し、明確なメッセージ付きで切り詰める
- [ ] 潜在的に大きい結果セットに対してフィルタリングオプションが提供されている
- [ ] すべてのネットワーク操作がタイムアウトと接続エラーを適切に処理する
- [ ] 共通機能が再利用可能な関数に抽出されている
- [ ] 類似操作間で戻り値の型が一貫している

### テストとビルド
- [ ] `npm run build` がエラーなく正常に完了する
- [ ] dist/index.js が作成され、実行可能である
- [ ] サーバーが実行される: `node dist/index.js --help`
- [ ] すべてのインポートが正しく解決される
- [ ] サンプルのツール呼び出しが期待どおりに動作する