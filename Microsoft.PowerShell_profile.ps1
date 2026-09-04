# Microsoft.PowerShell_profile.ps1 — PowerShell profile

# --- PATH (bin/ is added by install.ps1) -------------------------------------

# --- Aliases -----------------------------------------------------------------
Set-Alias -Name g   -Value git
Set-Alias -Name v   -Value vim
Set-Alias -Name ll  -Value Get-ChildItem

# --- Functions ---------------------------------------------------------------
function mkcd { param($path); New-Item -ItemType Directory -Force $path | Set-Location }
function showpath { $env:PATH -split ';' }

# --- Prompt (simple) ---------------------------------------------------------
function prompt {
  $loc = (Get-Location).Path.Replace($HOME, "~")
  "$loc> "
}

# --- Local overrides (not tracked by git) ------------------------------------
$localProfile = Join-Path (Split-Path $PROFILE) "profile.local.ps1"
if (Test-Path $localProfile) { . $localProfile }
