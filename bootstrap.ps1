# bootstrap.ps1 — install dotfiles from GitHub with a single command (Windows)
#
#   Set-ExecutionPolicy -Scope Process Bypass
#   irm https://raw.githubusercontent.com/mame7743/dotfiles/master/bootstrap.ps1 | iex
#
# By default this also installs dependencies (install-deps.ps1, winget).
#
# Options:
#   -NoDeps   only link dotfiles; install nothing
#   -Deps     install dependencies (default)

param(
  [switch]$Deps,
  [switch]$NoDeps
)

$RepoUrl    = "https://github.com/mame7743/dotfiles.git"
$Branch     = "master"
$DotfilesDir = Join-Path $HOME "dotfiles"

function Write-Info { param($msg) Write-Host "[info]  $msg" -ForegroundColor Blue }
function Write-Ok   { param($msg) Write-Host "[ok]    $msg" -ForegroundColor Green }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "git is required. Install it first: https://git-scm.com/download/win"
  exit 1
}

if (Test-Path (Join-Path $DotfilesDir ".git")) {
  Write-Info "Updating existing repo at $DotfilesDir"
  git -C $DotfilesDir fetch origin --prune
  git -C $DotfilesDir checkout -B $Branch "origin/$Branch"
} else {
  Write-Info "Cloning dotfiles into $DotfilesDir"
  git clone --branch $Branch $RepoUrl $DotfilesDir
}

Write-Info "Linking dotfiles"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $DotfilesDir "scripts\install.ps1")

if (-not $NoDeps) {
  Write-Info "Installing dependencies"
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $DotfilesDir "scripts\install-deps.ps1")
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[error] 依存ソフトの導入に失敗しました。dotfiles のリンクは完了しています。" -ForegroundColor Red
    exit 1
  }
}

Write-Ok "Done! Restart your shell to apply changes."