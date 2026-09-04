# install-deps.ps1 — Windows dependencies via winget
# Usage: powershell -ExecutionPolicy Bypass -File install-deps.ps1

$ErrorActionPreference = "Stop"

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
  Write-Host "[error] winget が見つかりません。Windows 10/11 の App Installer を更新してください。" -ForegroundColor Red
  exit 1
}

$packages = @(
  "Git.Git",
  "Neovim.Neovim",
  "vim.vim",
  "BurntSushi.ripgrep.MSVC",
  "sharkdp.fd",
  "sharkdp.bat",
  "junegunn.fzf",
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

Write-Host "[ok]    依存ソフトウェアのインストールが完了しました。" -ForegroundColor Green