[CmdletBinding()]
param([switch]$NoLaunchGame)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$installInfoPath = Join-Path $root 'config\install.json'
$settingsPath = Join-Path $root 'config\settings.json'

if (-not (Test-Path $settingsPath)) {
  Write-Host 'ValheimAI has not been bootstrapped yet. Running installer...' -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot 'Install-ValheimAI.ps1')
}
if (-not (Test-Path $installInfoPath)) {
  throw 'Installation metadata is missing. Run scripts\Install-ValheimAI.ps1.'
}
$install = Get-Content $installInfoPath -Raw | ConvertFrom-Json
$controllerCandidates = @(
  (Join-Path $root 'artifacts\ValheimAI.Controller.exe'),
  (Join-Path $root 'src\ValheimAI.Controller\bin\Release\net8.0\win-x64\publish\ValheimAI.Controller.exe'),
  (Join-Path $root 'src\ValheimAI.Controller\bin\Release\net8.0\ValheimAI.Controller.exe')
)
$controller = $controllerCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $controller) {
  Write-Host 'Controller build not found; attempting a local build.' -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot 'build.ps1')
  $controller = $controllerCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $controller) { throw 'Controller executable is still missing after build.' }

$env:VALHEIMAI_CONFIG = $settingsPath
Start-Process -FilePath $controller -WorkingDirectory $root

if (-not $NoLaunchGame) {
  $steamExe = Join-Path $install.steamPath 'steam.exe'
  if (-not (Test-Path $steamExe)) { throw 'Steam path changed. Rerun installer.' }
  Start-Process -FilePath $steamExe -ArgumentList '-applaunch 892970'
  Write-Host 'Steam/Valheim launch requested.' -ForegroundColor Green
}
Write-Host 'ValheimAI controller started.' -ForegroundColor Green
