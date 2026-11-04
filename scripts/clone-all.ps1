# 一键把候选项 clone 到 vendor/（不提交到本仓库）
# 用法：在仓库根目录运行  .\scripts\clone-all.ps1
$ErrorActionPreference = "Stop"

$repos = [ordered]@{
    "tmm"     = "https://github.com/sbyrnes321/tmm.git"
    "fdtdx"   = "https://github.com/ymahlau/fdtdx.git"
    "beamz"   = "https://github.com/beamzorg/beamz.git"
    "meep"    = "https://github.com/NanoComp/meep.git"
    "torcwa"  = "https://github.com/kch3782/torcwa.git"
    "S4"      = "https://github.com/victorliu/S4.git"
    "ceviche" = "https://github.com/fancompute/ceviche.git"
    "fdtd"    = "https://github.com/flaport/fdtd.git"
}

$root = Join-Path $PSScriptRoot "..\vendor"
New-Item -ItemType Directory -Force -Path $root | Out-Null

foreach ($name in $repos.Keys) {
    $dest = Join-Path $root $name
    if (Test-Path $dest) {
        Write-Host "[skip] $name 已存在：$dest" -ForegroundColor Yellow
        continue
    }
    Write-Host "[clone] $name" -ForegroundColor Cyan
    git clone --depth 1 $repos[$name] $dest
}

Write-Host "`n完成。项目在：$root" -ForegroundColor Green
