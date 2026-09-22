# OpenCode 設定の V2 ネイティブ化と Jev judge ツール

- date: 2026-09-22
- status: decided
- related: `config/opencode/opencode.jsonc`, `config/opencode/AGENTS.md`, `config/opencode/agents/judge.md`, `config/opencode/plugins/jev.ts`, `install.sh`, `AGENTS.md`

## Context（背景）

「AGENTS.md / judge専用プロンプト / Jev API カスタムツール」の3層構成の提案を受けたが、内容が OpenCode V1 構文であり、稼働中の OpenCode v2.0.12 では動作しない箇所が多数あった。V2 ネイティブに修正してグローバル設定（`config/opencode/` → `~/.config/opencode/` の symlink）へ実装した。

## Decision / Finding（決定・発見）

- **カスタムツール機構は V2 に存在しない**。V1 の `.opencode/tool/*.ts` + `@opencode-ai/plugin` の `tool()` は廃止。V2 はプラグイン（`.opencode/plugins/`）の `ctx.tool.transform` で登録する。スキーマは JSON Schema、戻り値は `{ content }`。
- `@opencode/plugin` はプラグインの**実体パス**（symlink 先の dotfiles 側）から解決されるため、`~/.config/opencode/node_modules` に置いても読まれない。`Plugin.define` は恒等関数なので、`plugins/jev.ts` は**依存なしの素のオブジェクト**（`export default { id, setup }`）にした。これにより npm 依存を持ち込まずに済む。
- ツールは `editor.namespace({ name: "jev" })` により `jev_yesno` / `jev_choice` / `jev_score` として登録される（`codemode: true` で Code Mode からも呼べる）。
- **V2 ネイティブ化**: `agent`→`agents`、`command`→`commands`、`permission`(オブジェクト)→`permissions`(順序付き配列)、`bash`→`shell`、`task`→`subagent`、`reasoningEffort`→モデル variant（`openai/gpt-5.6-terra#medium`, `openai/gpt-6-astra#high`）。
- `instructions: ["AGENTS.md"]` は V2 では**解決されない no-op**（公式ドキュメント明記）。AGENTS.md は自動読込されるため追加しない。
- `judge` には edit を deny。shell は git status/diff/log と pytest/go test のみ allow、`jev_*` を allow、subagent を deny。
- Jev は OpenCode Zen の判断エンドポイント（`https://opencode.ai/zen/v1/systemone`）を使用。モデルは `jev-1.13` / `jev-1.13-free`。`models` ツールのカタログには出てこない（チャット用モデル一覧とは別）。
- 接続情報は環境変数で注入（秘密値は非記録）: `JEV_ENDPOINT` / `JEV_MODEL` / `JEV_API_KEY`（fallback: `OPENCODE_API_KEY` / `OPENROUTER_API_KEY`）。環境変数が無い場合は `~/.local/share/opencode/auth.json` の `opencode-go` キーを自動使用（`OPENCODE_AUTH_FILE` で上書き可）。
- `install.sh` を複数形ディレクトリ（`agents` `commands` `plugins`）対応にし、旧 `agent`/`command` symlink を除去するようにした。

## Verification（検証）

- 失敗の切り分け: 当初 `Cannot find package '@opencode/plugin'` でロード失敗。import 除去後も**サービス再起動までキャッシュが残り**同エラーが再現した。`opencode service restart` 後に解消。
- 再起動後、Code Mode カタログに `jev.yesno` / `jev.choice` / `jev.score`（3ツール）が出現。
- ログにプラグインの load 失敗なし、agent/config の警告なし。

## Open Questions（未解決の問い）

- Jev は導入初期のため**助言のみ**。人間の判断との不一致を30〜50件蓄積してからしきい値・質問文を固定する。
- `judge` からの実際の Jev 呼び出しは 2026-09-22 に検証済み（`noul` / `choice` / `score` の3形式が HTTP 200）。認証は環境変数優先、未設定時は `auth.json` の `opencode-go` キーを自動使用。常用時は 1Password CLI 等からの環境変数注入も可。
- 既存の V1 形式 `~/.config/opencode/package.json`（`@opencode-ai/plugin`）は V2 では未使用。不要なら整理候補。
