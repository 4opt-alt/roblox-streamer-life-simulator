# Auto-Sync script for Roblox Streamer Simulator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$env:Path = "$env:Path;C:\Users\lyutu\.tools\git\cmd;C:\Users\lyutu\.tools\bin"
Set-Location $PSScriptRoot

Write-Host '====================================================' -ForegroundColor Green
Write-Host '   Roblox Streamer Simulator - Auto-Sync GitHub    ' -ForegroundColor Green
Write-Host '====================================================' -ForegroundColor Green

Write-Host '[1/4] Checking git status...' -ForegroundColor Cyan
& git status --short

Write-Host '`n[2/4] Staging all files...' -ForegroundColor Cyan
& git add -A

$Now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$status = (& git status --porcelain)
if ($status) {
    Write-Host "[3/4] Committing changes ($Now)..." -ForegroundColor Cyan
    & git commit -m "Update game: $Now"
} else {
    Write-Host '[3/4] No new local changes to commit.' -ForegroundColor Yellow
}

Write-Host '`n[4/4] Pushing to GitHub...' -ForegroundColor Cyan
& git push origin main

Write-Host '`n[SUCCESS] Project is fully up to date on GitHub!' -ForegroundColor Green
Write-Host 'Repository: https://github.com/4opt-alt/roblox-streamer-life-simulator' -ForegroundColor Yellow
