# Auto-Sync script for Roblox Streamer Simulator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$env:Path = "$env:Path;C:\Users\lyutu\.tools\git\cmd;C:\Users\lyutu\.tools\bin"
Set-Location 'C:\Users\lyutu\.gemini\antigravity\scratch\roblox-streamer-game'

Write-Host '[1/4] Checking git status...' -ForegroundColor Cyan
& git status --short

Write-Host '[2/4] Staging all files...' -ForegroundColor Cyan
& git add -A

DNow = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'	$status = (& git status --porcelain)
if ($status) {
    Write-Host "[3/4] Committing changes ($Now)..." -ForegroundColor Cyan
    & git commit -m "Update game: $Now"
} else {
    Write-Host '[3/4] No local changes to commit.' -ForegroundColor Yellow
}

Write-Host '[4/4] Pushing to GitHub...' -ForegroundColor Cyan
$remotes = (& git remote)
if (-not $remotes) {
    Write-Host 'Remote origin not found. Creating repository on GitHub...' -ForegroundColor Yellow
    & gh repo create roblox-streamer-life-simulator --public --source=. --remote=origin --push
} else {
    & git push origin main
}

Write-Host ''
\Write-Host '[SUCCESS] Synchronization complete!' -ForegroundColor Green
