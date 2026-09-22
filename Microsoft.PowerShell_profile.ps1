# Microsoft.PowerShell_profile.ps1 — PowerShell profile

# --- PATH (bin/ is added by install.ps1) -------------------------------------

# Go tools (go install) — %USERPROFILE%\go\bin (ghq / gopls など)
$goBin = Join-Path $HOME "go\bin"
if ((Test-Path $goBin) -and ($env:PATH -notlike "*$goBin*")) {
  $env:PATH = "$goBin;$env:PATH"
}

# --- Aliases -----------------------------------------------------------------
Set-Alias -Name g   -Value git
Set-Alias -Name v   -Value vim
Set-Alias -Name ll  -Value Get-ChildItem

# --- Functions ---------------------------------------------------------------
function mkcd { param($path); New-Item -ItemType Directory -Force $path | Set-Location }
function showpath { $env:PATH -split ';' }

# --- ghq + fzf ---------------------------------------------------------------
#   gcd : 選んだリポジトリへ移動
#   gco : 選んだリポジトリをエディタで開く
function Get-GhqRepository {
  if (-not (Get-Command ghq -ErrorAction SilentlyContinue)) {
    Write-Warning "ghq が見つかりません（install-deps.ps1 で導入できます）"
    return $null
  }
  if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Warning "fzf が見つかりません"
    return $null
  }
  # preview は Windows の shell (cmd) でも動くようリダイレクトを使わない
  $repo = ghq list -p | fzf --prompt='ghq> ' --height=60% --reverse `
    --preview 'git -C {} log --oneline --decorate -12' --preview-window='right:50%'
  if ([string]::IsNullOrWhiteSpace($repo)) { return $null }
  return $repo.Trim()
}

function gcd {
  $repo = Get-GhqRepository
  if ($repo) { Set-Location $repo }
}

function gco {
  $repo = Get-GhqRepository
  if (-not $repo) { return }
  $editor = if ($env:EDITOR) { $env:EDITOR }
            elseif (Get-Command nvim -ErrorAction SilentlyContinue) { 'nvim' }
            elseif (Get-Command vim -ErrorAction SilentlyContinue) { 'vim' }
            else { 'code' }
  & $editor $repo
}

# --- Prompt (simple) ---------------------------------------------------------
function prompt {
  $loc = (Get-Location).Path.Replace($HOME, "~")
  "$loc> "
}

# --- Local overrides (not tracked by git) ------------------------------------
$localProfile = Join-Path (Split-Path $PROFILE) "profile.local.ps1"
if (Test-Path $localProfile) { . $localProfile }
