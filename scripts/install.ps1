# install.ps1 — create symlinks for all dotfiles (Windows / PowerShell)
# Usage (Run as Administrator once, or enable Developer Mode for symlinks):
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1

param(
  [switch]$DryRun
)

$DOTFILES   = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$PROFILE_DIR = Split-Path $PROFILE
$HOME_DIR   = $env:USERPROFILE

function Write-Info    { param($msg) Write-Host "[info]  $msg" -ForegroundColor Blue }
function Write-Ok      { param($msg) Write-Host "[ok]    $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "[warn]  $msg" -ForegroundColor Yellow }

function New-Link {
  param($src, $dst)
  if (Test-Path $dst) {
    $item = Get-Item $dst -Force
    if ($item.LinkType) {
      Remove-Item $dst -Force
    } else {
      Write-Warning "Backing up $dst -> ${dst}.bak"
      if (-not $DryRun) { Move-Item $dst "${dst}.bak" }
    }
  }
  if (-not $DryRun) {
    $isDir = (Get-Item $src -Force -ErrorAction SilentlyContinue) -is [System.IO.DirectoryInfo]
    if ($isDir) {
      # Junction: no admin / Developer Mode required for directories
      New-Item -ItemType Junction -Path $dst -Target $src -Force | Out-Null
    } else {
      try {
        New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
      } catch {
        # Fallback: hard link (same volume only)
        New-Item -ItemType HardLink -Path $dst -Target $src -Force | Out-Null
      }
    }
  }
  Write-Ok "$dst -> $src"
}

# --- PowerShell profile ------------------------------------------------------
Write-Info "Linking PowerShell profile"
New-Item -ItemType Directory -Force -Path $PROFILE_DIR | Out-Null
New-Link "$DOTFILES\config\powershell\Microsoft.PowerShell_profile.ps1" $PROFILE

# --- gitconfig ---------------------------------------------------------------
Write-Info "Linking .gitconfig"
New-Link "$DOTFILES\.gitconfig" "$HOME_DIR\.gitconfig"
New-Link "$DOTFILES\.gitignore_global" "$HOME_DIR\.gitignore_global"

# --- vim (if installed) ------------------------------------------------------
if (Get-Command vim -ErrorAction SilentlyContinue) {
  Write-Info "Linking .vimrc"
  New-Link "$DOTFILES\.vimrc" "$HOME_DIR\.vimrc"
}

# --- Neovim ------------------------------------------------------------------
if (Get-Command nvim -ErrorAction SilentlyContinue) {
  Write-Info "Linking nvim config"
  $localAppData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME "AppData\Local" }
  $nvimDir = "$localAppData\nvim"
  New-Item -ItemType Directory -Force -Path (Split-Path $nvimDir) | Out-Null
  New-Link "$DOTFILES\config\nvim" $nvimDir
}

# --- WezTerm (terminal / panes) ---------------------------------------------
if (Test-Path "$DOTFILES\config\wezterm\wezterm.lua") {
  Write-Info "Linking WezTerm config"
  $wezDir = "$HOME_DIR\.config\wezterm"
  New-Item -ItemType Directory -Force -Path (Split-Path $wezDir) | Out-Null
  New-Link "$DOTFILES\config\wezterm" $wezDir
}

# --- opencode global config --------------------------------------------------
# 個別ファイル / ディレクトリのみリンクする（node_modules 等の生成物を含めない）
Write-Info "Linking opencode config"
$ocDir = "$HOME_DIR\.config\opencode"
New-Item -ItemType Directory -Force -Path $ocDir | Out-Null
if (Test-Path "$DOTFILES\config\opencode\opencode.jsonc") {
  New-Link "$DOTFILES\config\opencode\opencode.jsonc" "$ocDir\opencode.jsonc"
}
if (Test-Path "$DOTFILES\config\opencode\AGENTS.md") {
  New-Link "$DOTFILES\config\opencode\AGENTS.md" "$ocDir\AGENTS.md"
}
# 旧 V1 の単数ディレクトリ名は V2 の複数形へ移行済み
foreach ($legacy in @("agent", "command")) {
  $p = "$ocDir\$legacy"
  if (Test-Path $p) {
    $item = Get-Item $p -Force
    if ($item.LinkType) {
      Remove-Item $p -Force
      Write-Ok "Removed legacy link $p"
    }
  }
}
foreach ($d in @("agents", "commands", "plugins")) {
  if (Test-Path "$DOTFILES\config\opencode\$d") {
    New-Link "$DOTFILES\config\opencode\$d" "$ocDir\$d"
  }
}

# --- LLM skills --------------------------------------------------------------
# スキルは agent-skills\manifest.toml で宣言し、agent-skills\install.sh が導入する。
# Git / submodule 操作はここでは行わない。Windows では bash (Git for Windows) が
# ある場合のみ実行する。
$agentSkillsInstaller = "$DOTFILES\agent-skills\install.sh"
if (Test-Path $agentSkillsInstaller) {
  if (Test-Path "$DOTFILES\agent-skills\repos\mattpocock\skills") {
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if ($bash) {
      Write-Info "Installing agent skills from manifest.toml"
      & bash ($agentSkillsInstaller -replace '\\', '/')
      if ($LASTEXITCODE -ne 0) { Write-Warning "agent-skills: 競合のため一部未導入" }
    } else {
      Write-Warning "agent-skills: bash が見つからないためスキル導入をスキップ"
    }
  } else {
    Write-Warning "agent-skills: submodule 未初期化のためスキル導入をスキップ (git submodule update --init --recursive)"
  }
}

# --- bin/ (add to PATH if not present) ---------------------------------------
$binPath = "$DOTFILES\bin"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$binPath*") {
  Write-Info "Adding $binPath to user PATH"
  if (-not $DryRun) {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$binPath", "User")
  }
  Write-Ok "PATH updated (restart shell to apply)"
}

Write-Info "Done! Restart your shell to apply changes."