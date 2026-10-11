# install-deps.ps1 — Windows dependencies via winget
# Usage: powershell -ExecutionPolicy Bypass -File scripts\install-deps.ps1
# 構成は Brewfile に対応。winget に無いツールは最後の post-install で導入する。

$ErrorActionPreference = "Stop"

# スクリプトは scripts/ にあり、リポジトリ直下の deps/ 等を参照する
$DOTFILES = Split-Path -Parent $PSScriptRoot

# 固定バージョンの唯一の情報源（deps/versions.env を読み取る）
$versions = @{}
Get-Content "$DOTFILES\deps\versions.env" | ForEach-Object {
  if ($_ -match '^\s*([A-Z0-9_]+)="([^"]*)"') { $versions[$Matches[1]] = $Matches[2] }
}

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
  Write-Host "[error] winget が見つかりません。Windows 10/11 の App Installer を更新してください。" -ForegroundColor Red
  exit 1
}

# ---------------------------------------------------------------------------
# winget パッケージ一覧
# ※ zsh / gdb / direnv は winget に無いため WSL か MSYS2 で導入すること。
#    既定シェルは PowerShell 7 (pwsh) とし、端末は WezTerm を使う。
# ---------------------------------------------------------------------------
$packages = @(
  # 基本
  "Git.Git",
  "GitHub.cli",
  "curl.curl",
  "GNU.Wget",
  # 検索・操作
  "BurntSushi.ripgrep.MSVC",
  "sharkdp.fd",
  "sharkdp.bat",
  "junegunn.fzf",
  "jqlang.jq",
  "MikeFarah.yq",
  "eza-community.eza",
  "ajeetdsouza.zoxide",
  # シェル
  "Starship.Starship",
  # 開発補助
  "jdx.mise",
  "casey.just",
  # Python
  "astral-sh.uv",
  "Python.Python.3.12",
  "astral-sh.ruff",
  "Microsoft.Pyright",
  # C/C++
  "LLVM.LLVM",
  "Kitware.CMake",
  "Ninja-build.Ninja",
  # コンテナ
  "Docker.DockerCLI",
  "Docker.DockerCompose",
  "Docker.DockerDesktop",
  # 文書・レポート
  "Obsidian.Obsidian",
  "RStudio.Quarto",
  "Typst.Typst",
  "JohnMacFarlane.Pandoc",
  # 可視化
  "Kitware.ParaView",
  # エディタ
  "Microsoft.VisualStudioCode",
  # その他（既存ツールの維持）
  "Neovim.Neovim",
  "vim.vim",
  "JesseDuffield.lazygit",
  "Sumneko.LuaLanguageServer",
  # 端末・シェル（Windows ネイティブ）
  "Microsoft.PowerShell",
  "wez.wezterm",
  # リポジトリ・AI（core 相当）
  "jj-vcs.jj",
  "IbrahimDursun.jjui",
  "x-motemen.ghq",
  "SST.opencode",
  "Herdr.Herdr.Preview"
)

foreach ($pkg in $packages) {
  Write-Host "[info]  winget install $pkg" -ForegroundColor Blue
  winget install --id $pkg --source winget --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[warn]  $pkg のインストールに失敗しました。" -ForegroundColor Yellow
  }
}

# ---------------------------------------------------------------------------
# post-install: VS Code 拡張機能 (deps/vscode-extensions.txt)
# ---------------------------------------------------------------------------
$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) {
  $extensions = Get-Content "$DOTFILES\deps\vscode-extensions.txt" |
    Where-Object { $_ -and -not $_.StartsWith("#") }
  $installed = @(& code --list-extensions)
  foreach ($ext in $extensions) {
    if ($installed -contains $ext) {
      Write-Host "[ok]    code --install-extension $ext (installed)" -ForegroundColor Green
    } else {
      Write-Host "[info]  code --install-extension $ext" -ForegroundColor Blue
      & code --install-extension $ext
    }
  }
} else {
  Write-Host "[warn]  VS Code の code CLI が見つかりません — 拡張機能はスキップ" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# post-install: uv で Python ツールと PyVista 系ライブラリを導入
# ---------------------------------------------------------------------------
$uv = Get-Command uv -ErrorAction SilentlyContinue
if ($uv) {
  # JupyterLab と pre-commit は分離されたツール環境として導入
  & uv tool install jupyterlab
  & uv tool install pre-commit

  # PyVista 系ライブラリ (deps/python/requirements-visualization.lock)
  $venv = Join-Path $env:USERPROFILE ".local\venvs\visualization"
  if (-not (Test-Path "$venv\Scripts\python.exe")) {
    Write-Host "[info]  Creating venv: $venv" -ForegroundColor Blue
    & uv venv $venv
  }
  & uv pip install --python "$venv\Scripts\python.exe" -r "$DOTFILES\deps\python\requirements-visualization.lock"
  Write-Host "[ok]    PyVista 系ライブラリ -> $venv" -ForegroundColor Green
} else {
  Write-Host "[warn]  uv が見つかりません — Python visualization はスキップ" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# post-install: Go ツール (ghq / gopls / golangci-lint) — 固定バージョン
# ---------------------------------------------------------------------------
$go = Get-Command go -ErrorAction SilentlyContinue
if ($go) {
  & go install "github.com/x-motemen/ghq@$($versions['GHQ_VERSION'])"
  & go install "golang.org/x/tools/gopls@$($versions['GOPLS_VERSION'])"
  & go install "github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$($versions['GOLANGCI_LINT_VERSION'])"
}

# ---------------------------------------------------------------------------
# post-install: 言語ランタイム (mise) — config/mise/config.toml が情報源
# ---------------------------------------------------------------------------
$mise = Get-Command mise -ErrorAction SilentlyContinue
if ($mise) {
  & mise install
  Write-Host "[ok]    言語ランタイム (mise)" -ForegroundColor Green
} else {
  Write-Host "[warn]  mise が見つかりません — 言語ランタイムはスキップ" -ForegroundColor Yellow
}

Write-Host "[ok]    依存ソフトウェアのインストールが完了しました。" -ForegroundColor Green