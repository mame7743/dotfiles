# install.ps1 — create symlinks for all dotfiles (Windows / PowerShell)
# Usage (Run as Administrator once, or enable Developer Mode for symlinks):
#   powershell -ExecutionPolicy Bypass -File install.ps1

param(
  [switch]$DryRun
)

$DOTFILES   = Split-Path -Parent $MyInvocation.MyCommand.Path
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
New-Link "$DOTFILES\Microsoft.PowerShell_profile.ps1" $PROFILE

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

# --- opencode global config --------------------------------------------------
Write-Info "Linking opencode config"
$ocDir = "$HOME_DIR\.config\opencode"
New-Item -ItemType Directory -Force -Path $ocDir | Out-Null
if (Test-Path "$DOTFILES\config\opencode\opencode.jsonc") {
  New-Link "$DOTFILES\config\opencode\opencode.jsonc" "$ocDir\opencode.jsonc"
}
foreach ($d in @("agent", "command")) {
  if (Test-Path "$DOTFILES\config\opencode\$d") {
    New-Link "$DOTFILES\config\opencode\$d" "$ocDir\$d"
  }
}

# --- LLM skills --------------------------------------------------------------
# Each skill in $DOTFILES\skills\<name> is linked into every agent's skills
# directory (opencode / claude / codex / ~/.agents).
$SKILL_DIRS = @(
  "$HOME_DIR\.config\opencode\skills",
  "$HOME_DIR\.claude\skills",
  "$HOME_DIR\.codex\skills",
  "$HOME_DIR\.agents\skills"
)
if (Test-Path "$DOTFILES\skills") {
  Write-Info "Linking LLM skills"
  foreach ($dir in $SKILL_DIRS) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  Get-ChildItem "$DOTFILES\skills" -Directory | ForEach-Object {
    $name = $_.Name
    foreach ($dir in $SKILL_DIRS) {
      New-Link $_.FullName "$dir\$name"
    }
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