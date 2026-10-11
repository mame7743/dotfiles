# Microsoft.PowerShell_profile.ps1 — PowerShell profile

# --- PATH (bin/ is added by scripts/install.ps1) -------------------------------------

# Go tools (go install) — %USERPROFILE%\go\bin (ghq / gopls など)
$goBin = Join-Path $HOME "go\bin"
if ((Test-Path $goBin) -and ($env:PATH -notlike "*$goBin*")) {
  $env:PATH = "$goBin;$env:PATH"
}

# Default editor: Neovim。$env:EDITOR / $env:VISUAL を設定すればそちらが優先される。
# 変更したい場合は profile.local.ps1 で上書きする。
if (-not $env:EDITOR) { $env:EDITOR = 'nvim' }

# --- Aliases -----------------------------------------------------------------
Set-Alias -Name g   -Value git
Set-Alias -Name v   -Value vim
Set-Alias -Name ll  -Value Get-ChildItem
Set-Alias -Name oc  -Value opencode

# --- Functions ---------------------------------------------------------------
function mkcd { param($path); New-Item -ItemType Directory -Force $path | Set-Location }
function showpath { $env:PATH -split ';' }

# --- ghq + fzf ---------------------------------------------------------------
#   gcd : 選んだリポジトリへ移動
#   gco : 選んだリポジトリをエディタで開く
function Get-GhqRepository {
  if (-not (Get-Command ghq -ErrorAction SilentlyContinue)) {
    Write-Warning "ghq が見つかりません（scripts/install-deps.ps1 で導入できます）"
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

# エディタ解決: 環境変数を優先し、未設定なら nvim → vim → vi にフォールバック。
#   1. $env:GCO_EDITOR … gco 専用。VS Code など別のエディタを指定したいとき
#   2. $env:EDITOR      … 汎用（既定 nvim）
#   3. $env:VISUAL
# 対話起動では --wait を外す。
function Get-Editor {
  $ed = if ($env:GCO_EDITOR) { $env:GCO_EDITOR }
        elseif ($env:EDITOR) { $env:EDITOR }
        elseif ($env:VISUAL) { $env:VISUAL }
        else { $null }
  if (-not $ed) {
    foreach ($c in 'nvim', 'vim', 'vi') {
      if (Get-Command $c -ErrorAction SilentlyContinue) { $ed = $c; break }
    }
  }
  if (-not $ed) { $ed = 'vi' }
  return ($ed -replace '--wait', '')
}

function gco {
  $repo = Get-GhqRepository
  if (-not $repo) { return }
  $editor = Get-Editor
  $parts = @($editor -split '\s+' | Where-Object { $_ })
  $editorArgs = if ($parts.Length -gt 1) { $parts[1..($parts.Length - 1)] } else { @() }
  & $parts[0] @editorArgs $repo
}

# --- Prompt (simple) ---------------------------------------------------------
function prompt {
  $loc = (Get-Location).Path.Replace($HOME, "~")
  "$loc> "
}

# --- Local overrides (not tracked by git) ------------------------------------
$localProfile = Join-Path (Split-Path $PROFILE) "profile.local.ps1"
if (Test-Path $localProfile) { . $localProfile }
