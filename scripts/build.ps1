$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if (-not $dotnet) { throw '.NET SDK 8 is required for a source build. Run scripts\Install-ValheimAI.ps1 for guidance.' }

Write-Host 'Building ValheimAI controller...' -ForegroundColor Cyan
dotnet restore (Join-Path $root 'src\ValheimAI.Controller\ValheimAI.Controller.csproj')
dotnet publish (Join-Path $root 'src\ValheimAI.Controller\ValheimAI.Controller.csproj') -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o (Join-Path $root 'artifacts')
Write-Host 'Controller published as a self-contained Windows executable.' -ForegroundColor Green

Write-Host 'Plugin build is intentionally separate until current Valheim/BepInEx assembly references are wired.' -ForegroundColor Yellow
