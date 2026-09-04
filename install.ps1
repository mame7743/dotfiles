# install.ps1 — create symlinks for all dotfiles (Windows / PowerShell)
# Run as Administrator: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

param(
  [switch]$DryRun
)

$DOTFILES = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROFILE_DIR = Split-Path $PROFILE

function Write-Info    { param($msg) Write-Host "[info]  $msg" -ForegroundColor Blue }
function Write-Ok      { param($msg) Write-Host "[ok]    $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "[warn]  $msg" -ForegroundColor Yellow }

function New-Link {
  param($src, $dst)
  if (Test-Path $dst -PathType Container) {
    Write-Warning "Backing up $dst -> ${dst}.bak"
    if (-not $DryRun) { Move-Item $dst "${dst}.bak" }
  } elseif (Test-Path $dst) {
    Write-Warning "Backing up $dst -> ${dst}.bak"
    if (-not $DryRun) { Move-Item $dst "${dst}.bak" }
  }
  if (-not $DryRun) {
    $isDir = (Get-Item $src -ErrorAction SilentlyContinue) -is [System.IO.DirectoryInfo]
    $type = if ($isDir) { "Junction" } else { "HardLink" }
    New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
  }
  Write-Ok "$dst -> $src"
}

# --- PowerShell profile ------------------------------------------------------
Write-Info "Linking PowerShell profile"
New-Item -ItemType Directory -Force -Path $PROFILE_DIR | Out-Null
New-Link "$DOTFILES\Microsoft.PowerShell_profile.ps1" $PROFILE

# --- gitconfig ---------------------------------------------------------------
Write-Info "Linking .gitconfig"
New-Link "$DOTFILES\.gitconfig" "$env:USERPROFILE\.gitconfig"
New-Link "$DOTFILES\.gitignore_global" "$env:USERPROFILE\.gitignore_global"

# --- vim (if installed) ------------------------------------------------------
if (Get-Command vim -ErrorAction SilentlyContinue) {
  Write-Info "Linking .vimrc"
  New-Link "$DOTFILES\.vimrc" "$env:USERPROFILE\.vimrc"
}

# --- Neovim ------------------------------------------------------------------
if (Get-Command nvim -ErrorAction SilentlyContinue) {
  Write-Info "Linking nvim config"
  $nvimDir = "$env:LOCALAPPDATA\nvim"
  New-Item -ItemType Directory -Force -Path (Split-Path $nvimDir) | Out-Null
  New-Link "$DOTFILES\config\nvim" $nvimDir
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
