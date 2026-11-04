# 初始化/更新所有 git submodule 到上游最新
# 用法：在仓库根目录运行  .\scripts\update-submodules.ps1
$ErrorActionPreference = "Stop"

git submodule sync --recursive
git submodule update --init --recursive --depth 1
git submodule update --remote --merge
Write-Host "`n子模块已更新。" -ForegroundColor Green
git submodule status
