# Download prebuilt Awaaz assets (indexes + ONNX models) from the GitHub
# release. Run once after cloning on Windows — no GPU / no model downloads.
# Usage:  powershell -ExecutionPolicy Bypass -File scripts\fetch_assets.ps1
$ErrorActionPreference = "Stop"

$Repo = "FeV-06/awaaz-rag-goa"
$Tag  = "assets-v1"
$Base = "https://github.com/$Repo/releases/download/$Tag"
$Dest = Split-Path -Parent $PSScriptRoot   # repo root (scripts/..)

Set-Location $Dest
New-Item -ItemType Directory -Force -Path "data\indexes", "data\onnx_models" | Out-Null

$files = @("awaaz-indexes.tar.gz", "awaaz-onnx.tar.gz")
foreach ($f in $files) {
    Write-Host ">> downloading $Base/$f ..."
    curl.exe -fL --retry 3 -o $f "$Base/$f"
}

Write-Host ">> extracting ..."
tar.exe -xzf "awaaz-indexes.tar.gz" -C data
tar.exe -xzf "awaaz-onnx.tar.gz" -C data
Remove-Item "awaaz-indexes.tar.gz", "awaaz-onnx.tar.gz" -ErrorAction SilentlyContinue

Write-Host "`n✅ assets ready:"
Get-ChildItem "data\indexes" | Select-Object Name, Length
Get-ChildItem "data\onnx_models" | Select-Object Name, Length
