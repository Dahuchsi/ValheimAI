[CmdletBinding()]
param(
  [switch]$SkipBuild,
  [switch]$ForceBepInEx
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$configDir = Join-Path $root 'config'
$configExample = Join-Path $configDir 'settings.example.json'
$configFile = Join-Path $configDir 'settings.json'
$artifacts = Join-Path $root 'artifacts'

function Write-Step($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-Ok($m) { Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Find-SteamPath {
  $candidates = @()
  try {
    $v = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
    if ($v) { $candidates += $v }
  } catch {}
  try {
    $v = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -ErrorAction Stop).InstallPath
    if ($v) { $candidates += $v }
  } catch {}
  $candidates += @("$env:ProgramFiles(x86)\Steam", "$env:ProgramFiles\Steam")
  foreach ($p in $candidates | Select-Object -Unique) {
    if ($p -and (Test-Path (Join-Path $p 'steam.exe'))) { return (Resolve-Path $p).Path }
  }
  return $null
}

function Get-SteamLibraries([string]$steamPath) {
  $libs = New-Object System.Collections.Generic.List[string]
  $libs.Add($steamPath)
  $vdf = Join-Path $steamPath 'steamapps\libraryfolders.vdf'
  if (Test-Path $vdf) {
    $txt = Get-Content $vdf -Raw
    [regex]::Matches($txt, '"path"\s+"([^"]+)"') | ForEach-Object {
      $p = $_.Groups[1].Value -replace '\\\\','\'
      if ($p -and -not $libs.Contains($p)) { $libs.Add($p) }
    }
  }
  return $libs
}

function Find-ValheimPath([string]$steamPath) {
  foreach ($lib in (Get-SteamLibraries $steamPath)) {
    $p = Join-Path $lib 'steamapps\common\Valheim'
    if (Test-Path (Join-Path $p 'valheim.exe')) { return (Resolve-Path $p).Path }
  }
  return $null
}

function Test-BepInEx([string]$valheimPath) {
  return (Test-Path (Join-Path $valheimPath 'BepInEx\core\BepInEx.dll')) -and
         (Test-Path (Join-Path $valheimPath 'winhttp.dll'))
}

function Install-BepInEx([string]$valheimPath) {
  Write-Step 'Installing Valheim BepInEx pack'
  $api = 'https://api.github.com/repos/BepInExPack/BepInExPack_Valheim/releases/latest'
  $headers = @{ 'User-Agent' = 'ValheimAI-Installer' }
  $release = Invoke-RestMethod -Uri $api -Headers $headers
  $asset = $release.assets | Where-Object { $_.name -match 'BepInExPack_Valheim.*\.zip$' } | Select-Object -First 1
  if (-not $asset) { throw 'Could not locate BepInExPack_Valheim ZIP in the latest GitHub release.' }
  $temp = Join-Path $env:TEMP ("ValheimAI-BepInEx-" + [guid]::NewGuid())
  New-Item -ItemType Directory -Force -Path $temp | Out-Null
  $zip = Join-Path $temp $asset.name
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
  $extract = Join-Path $temp 'extract'
  Expand-Archive -Path $zip -DestinationPath $extract -Force
  $payload = Get-ChildItem $extract -Directory | Where-Object { $_.Name -eq 'BepInExPack_Valheim' } | Select-Object -First 1
  if (-not $payload) {
    $payload = Get-ChildItem $extract -Directory -Recurse | Where-Object { $_.Name -eq 'BepInExPack_Valheim' } | Select-Object -First 1
  }
  if (-not $payload) { throw 'Downloaded BepInEx archive did not contain BepInExPack_Valheim.' }
  Copy-Item (Join-Path $payload.FullName '*') $valheimPath -Recurse -Force
  Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
  if (-not (Test-BepInEx $valheimPath)) { throw 'BepInEx files were copied but installation verification failed.' }
  Write-Ok "BepInEx installed ($($release.tag_name))."
}

Write-Host 'ValheimAI bootstrap installer' -ForegroundColor White
Write-Host 'This installs/checks local prerequisites. Steam credentials are never requested or stored.'

Write-Step 'Detecting Steam'
$steam = Find-SteamPath
if (-not $steam) {
  Write-Fail 'Steam was not found.'
  Write-Host 'Install Steam from https://store.steampowered.com/about/ then rerun this installer.'
  exit 2
}
Write-Ok "Steam: $steam"

Write-Step 'Detecting Valheim'
$valheim = Find-ValheimPath $steam
if (-not $valheim) {
  Write-Fail 'Valheim was not found in any registered Steam library.'
  Write-Host 'Install Valheim (AppID 892970) in Steam, launch it once, then rerun this installer.'
  exit 3
}
Write-Ok "Valheim: $valheim"

Write-Step 'Checking BepInEx'
if ($ForceBepInEx -or -not (Test-BepInEx $valheim)) {
  Write-Warn 'Compatible Valheim BepInEx pack is missing or reinstall was requested.'
  Install-BepInEx $valheim
} else {
  Write-Ok 'BepInEx is present.'
}

Write-Step 'Preparing configuration'
New-Item -ItemType Directory -Force -Path $configDir, $artifacts | Out-Null
if (-not (Test-Path $configFile)) {
  Copy-Item $configExample $configFile
  Write-Ok 'Created config\settings.json from the example.'
} else { Write-Ok 'Existing config\settings.json preserved.' }

if (-not $SkipBuild) {
  Write-Step 'Checking .NET SDK for local source build'
  $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
  if (-not $dotnet) {
    Write-Warn '.NET SDK not found. A packaged release will not require it, but source builds do.'
    Write-Host 'Install the current .NET 8 SDK from https://dotnet.microsoft.com/download/dotnet/8.0 and rerun, or use a prebuilt release.'
  } else {
    Write-Ok ((dotnet --version) + ' detected.')
    & (Join-Path $PSScriptRoot 'build.ps1')
  }
}

Write-Step 'Plugin deployment check'
$pluginBuilt = Get-ChildItem (Join-Path $root 'src\ValheimAI.Plugin\bin') -Filter 'ValheimAI.Plugin.dll' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
$pluginDestDir = Join-Path $valheim 'BepInEx\plugins\ValheimAI'
New-Item -ItemType Directory -Force -Path $pluginDestDir | Out-Null
if ($pluginBuilt) {
  Copy-Item $pluginBuilt.FullName (Join-Path $pluginDestDir 'ValheimAI.Plugin.dll') -Force
  Write-Ok 'ValheimAI plugin deployed to BepInEx.'
} else {
  Write-Warn 'Plugin DLL is not built yet. This is expected in the current scaffold; packaged releases will include it.'
}

$installInfo = @{
  steamPath = $steam
  valheimPath = $valheim
  installedAtUtc = [DateTime]::UtcNow.ToString('o')
} | ConvertTo-Json
$installInfo | Set-Content (Join-Path $configDir 'install.json') -Encoding UTF8

Write-Host "`nBootstrap checks completed." -ForegroundColor Green
Write-Host 'Next: edit config\settings.json, set OPENAI_API_KEY, then run scripts\Start-ValheimAI.ps1.'
