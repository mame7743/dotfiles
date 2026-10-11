-- config/wezterm/wezterm.lua — WezTerm 共通設定（dotfiles 管理）
-- 方針: 標準キーバインドを維持し、最小限の設定のみ行う。
--   ペイン・タブ操作は WezTerm 標準（macOS: Cmd, Windows/Linux: Ctrl+Shift）。
--   エージェントの永続実行は Herdr に任せ、ここでは作り込まない。

local wezterm = require('wezterm')
local config = wezterm.config_builder()

-- 既定シェル: Windows は PowerShell 7 (pwsh)、それ以外は環境既定（$SHELL）。
if wezterm.target_triple:find('windows') then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
end

-- 外観（最小限）
config.hide_tab_bar_if_only_one_tab = true

return config
