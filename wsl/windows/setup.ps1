<#
  setup.ps1 — configure the Windows HOST side of a WSL dev box.

  Installs a Nerd Font (and Windows Terminal) via winget, then points
  Windows Terminal's default profile at the font so starship / eza
  icons render. Idempotent: safe to re-run.

  Run from WSL with:  just windows
  Or from PowerShell:  powershell -ExecutionPolicy Bypass -File setup.ps1

  winget may show a UAC prompt when installing the font machine-wide —
  that's expected; accept it.
#>
[CmdletBinding()]
param(
    [string]$FontFace    = "JetBrainsMono Nerd Font",
    [string]$FontPackage = "DEVCOM.JetBrainsMonoNerdFont"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found. Install 'App Installer' from the Microsoft Store first."
    exit 1
}

Write-Host "==> Installing font: $FontPackage"
winget install --id $FontPackage --exact `
    --accept-source-agreements --accept-package-agreements --silent

Write-Host "==> Ensuring Windows Terminal is installed"
winget install --id Microsoft.WindowsTerminal --exact `
    --accept-source-agreements --accept-package-agreements --silent

# --- Point Windows Terminal's default profile at the font ---
$wt = Join-Path $env:LOCALAPPDATA `
    "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (-not (Test-Path $wt)) {
    Write-Warning "Windows Terminal settings.json not found. Launch WT once, then re-run."
    exit 0
}

$raw = Get-Content -Raw -Path $wt
if ($raw -match [regex]::Escape($FontFace)) {
    Write-Host "==> Windows Terminal already uses '$FontFace'. Nothing to change."
    exit 0
}

Copy-Item $wt "$wt.bak" -Force
Write-Host "==> Backed up settings.json -> settings.json.bak"

# settings.json ships with `"defaults": {}`. Inject the font there so
# every profile (incl. Ubuntu) inherits it, without touching anything
# else. Uses a text replace to tolerate the JSONC comments WT allows.
$block   = '"defaults": { "font": { "face": "' + $FontFace + '" } }'
$patched = [regex]::Replace($raw, '"defaults"\s*:\s*\{\s*\}', $block, 1)

if ($patched -eq $raw) {
    Write-Warning ("Couldn't auto-insert the font (defaults block isn't empty). " +
        "Set it manually: Settings > Profiles > Defaults > Appearance > Font face = '$FontFace'.")
    exit 0
}

Set-Content -Path $wt -Value $patched -Encoding UTF8
Write-Host "==> Set default font.face = '$FontFace'. Restart Windows Terminal to apply."

# --- Merge ghostty-parity keybindings into Windows Terminal "actions" ---
# Structured JSON merge (settings.json is plain JSON, no comments). Each
# binding from wt-keybindings.json replaces any existing entry with the
# same string "keys", so re-running is idempotent.
$kbFile = Join-Path $PSScriptRoot "wt-keybindings.json"
if (Test-Path $kbFile) {
    Write-Host "==> Merging keybindings from wt-keybindings.json"
    $settings = Get-Content -Raw -Path $wt | ConvertFrom-Json
    $newKeys  = Get-Content -Raw -Path $kbFile | ConvertFrom-Json

    # Existing actions whose "keys" we are NOT overriding.
    $overridden = $newKeys | ForEach-Object { $_.keys }
    $kept = @()
    if ($settings.actions) {
        $kept = $settings.actions | Where-Object {
            -not ($_.keys -is [string] -and $overridden -contains $_.keys)
        }
    }
    $settings.actions = @($kept) + @($newKeys)

    Copy-Item $wt "$wt.bak" -Force
    $settings | ConvertTo-Json -Depth 32 | Set-Content -Path $wt -Encoding UTF8
    Write-Host "==> Keybindings applied ($($newKeys.Count) binds). Restart Windows Terminal."
}
