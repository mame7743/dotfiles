-- jjui config.lua — 日本語の操作メニュー
--
-- 目的: 覚えるキーを「メニューを開く m」1つに絞る。
--   コミットを選ぶ → `m` → 操作名を選ぶ → Enter で実行（Esc でキャンセル）。
--   メニュー内は上下（↑↓ / k j）で選択、Enter 実行、Esc キャンセル、
--   `/` で絞り込み。これは jjui 標準の choose ダイアログの挙動。
--
-- 対応: jjui v0.10.x の Lua API（choose / jjui.* ビルトインアクション）。
--   ビルトインを呼ぶだけで、独自に jj コマンドは組み立てない。
--
-- 管理: dotfiles の config/jjui/config.lua を ~/.config/jjui/config.lua へ symlink。
--   （jjui 自身が types.lua / .luarc.json を同ディレクトリへ書くため、
--     ディレクトリ全体ではなくファイル単位でリンクする）

-- 前後の空白・改行を除去する
local function trim(s)
  if s == nil then return nil end
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  if s == "" then return nil end
  return s
end

-- カーソルで選択中のコミットの change ID（未選択なら nil）
local function selected_change_id()
  return trim(context.change_id())
end

-- jjui は context.change_id() に「最短一意プレフィックス」を返す（例: "u"）。
-- そのままでは短すぎるため、jj で標準の short（12文字）へ解決して表示する。
local function short_change_id(prefix)
  if prefix == nil then return nil end
  local out, err = jj("log", "-r", prefix, "--no-graph", "-T", "change_id.short()")
  if err ~= nil then return prefix end
  return trim(out) or prefix
end

-- 作業中コミット @ の change ID（取得できなければ nil）
--   選択コミットと @ を取り違えないよう、メニューに両方を表示する。
local function working_copy_change_id()
  local out, err = jj("log", "-r", "@", "--no-graph", "-T", "change_id.short()")
  if err ~= nil then return nil end
  return trim(out)
end

local function flash_no_selection()
  flash({
    text = "コミットが選択されていません。カーソルで対象コミットを選んでから m を押してください。",
    error = true,
  })
end

function setup(config)
  -- メニュー項目の一覧を作る。
  --   needs_selection = true  … カーソルで選択中のコミットが対象（未選択なら実行しない）
  --   needs_selection = false … リポジトリ全体が対象（選択不要）
  -- 各項目の [選択] / [全体] は「実際のビルトインアクションの対象」に合わせている。
  local function build_menu()
    local order = {}
    local entries = {}

    local function add(label, needs_selection, run)
      order[#order + 1] = label
      entries[label] = { needs_selection = needs_selection, run = run }
    end

    -- ---- カーソルで選択中のコミットが対象 ----
    -- revisions.diff()              : 選択コミットの差分を表示
    add("[選択] 差分を見る", true, function() revisions.diff() end)
    -- revisions.open_details()      : 選択コミットの変更ファイル一覧を開く
    add("[選択] 変更ファイルを見る", true, function() revisions.open_details() end)
    -- revisions.describe()          : 選択コミットのメッセージを外部エディタで編集
    add("[選択] メッセージを編集する", true, function() revisions.describe() end)
    -- revisions.new()               : 選択コミットを親として新しい作業コミットを作る
    add("[選択] 続きに新しい作業を作る", true, function() revisions.new() end)
    -- revisions.edit()              : 選択コミットを作業対象（@）にする（jj edit）
    add("[選択] 編集対象にする（jj edit）", true, function() revisions.edit() end)
    -- revisions.open_set_bookmark() : 選択コミットに bookmark を設定
    add("[選択] bookmark を設定する", true, function() revisions.open_set_bookmark() end)
    -- revisions.split()             : 選択コミットを分割（jj split、対象は標準UIで選択）
    add("[選択] 変更を分割する", true, function() revisions.split() end)
    -- revisions.open_squash()       : 選択コミットを別コミットへまとめる（squash、対象は標準UIで選択）
    add("[選択] 別のコミットへまとめる（squash）", true, function() revisions.open_squash() end)
    -- revisions.open_rebase()       : 選択コミットを rebase（移動先は標準UIで選択）
    add("[選択] rebase する", true, function() revisions.open_rebase() end)

    -- ---- リポジトリ全体が対象（選択不要） ----
    -- jjui.ui.open_git()            : git ビューを開く（fetch / push は標準UIで選択）
    add("[全体] リモート操作を開く（fetch / push）", false, function() jjui.ui.open_git() end)
    -- jjui.ui.open_undo()           : 直前の操作を取り消す（undo）
    add("[全体] 直前の操作を取り消す（undo）", false, function() jjui.ui.open_undo() end)
    -- jjui.ui.open_oplog()          : 操作履歴（oplog）を見る
    add("[全体] 操作履歴を見る（oplog）", false, function() jjui.ui.open_oplog() end)

    return order, entries
  end

  -- メニューを開く処理。キー m に束縛する。
  config.action("open_menu", function()
    local sel = short_change_id(selected_change_id())
    local wc = working_copy_change_id()

    local title = "操作メニュー　選択=" .. (sel or "なし") .. "　@=" .. (wc or "?")

    local order, entries = build_menu()
    local choice = choose({ options = order, title = title, ordered = true })
    if choice == nil then
      return -- Esc でキャンセル（何も変更しない）
    end

    local entry = entries[choice]
    if entry == nil then
      return
    end

    if entry.needs_selection and sel == nil then
      flash_no_selection()
      return
    end

    entry.run()
  end, {
    desc = "操作メニュー（日本語）",
    key = "m",
    scope = "revisions",
  })
end
