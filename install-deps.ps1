# install-deps.ps1 — Windows dependencies via winget
# Usage: powershell -ExecutionPolicy Bypass -File install-deps.ps1
# 構成は Brewfile に対応。winget に無いツールは最後の post-install で導入する。

$ErrorActionPreference = "Stop"

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
  Write-Host "[error] winget が見つかりません。Windows 10/11 の App Installer を更新してください。" -ForegroundColor Red
  exit 1
}

# ---------------------------------------------------------------------------
# winget パッケージ一覧
# ※ zsh / tmux / gdb / direnv は winget に無いため WSL か MSYS2 で導入すること
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
  "Sumneko.LuaLanguageServer"
)

foreach ($pkg in $packages) {
  Write-Host "[info]  winget install $pkg" -ForegroundColor Blue
  winget install --id $pkg --source winget --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[warn]  $pkg のインストールに失敗しました。" -ForegroundColor Yellow
  }
}

# ---------------------------------------------------------------------------
# post-install: VS Code 拡張機能 (vscode-extensions.txt)
# ---------------------------------------------------------------------------
$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) {
  $extensions = Get-Content "$PSScriptRoot\vscode-extensions.txt" |
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

  # PyVista 系ライブラリ (python/requirements-visualization.txt)
  $venv = Join-Path $env:USERPROFILE ".local\venvs\visualization"
  if (-not (Test-Path "$venv\Scripts\python.exe")) {
    Write-Host "[info]  Creating venv: $venv" -ForegroundColor Blue
    & uv venv $venv
  }
  & uv pip install --python "$venv\Scripts\python.exe" -r "$PSScriptRoot\python\requirements-visualization.txt"
  Write-Host "[ok]    PyVista 系ライブラリ -> $venv" -ForegroundColor Green
} else {
  Write-Host "[warn]  uv が見つかりません — Python visualization はスキップ" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# post-install: Go ツール (gopls / golangci-lint)
# ---------------------------------------------------------------------------
$go = Get-Command go -ErrorAction SilentlyContinue
if ($go) {
  & go install golang.org/x/tools/gopls@latest
  & go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
}

Write-Host "[ok]    依存ソフトウェアのインストールが完了しました。" -ForegroundColor Green