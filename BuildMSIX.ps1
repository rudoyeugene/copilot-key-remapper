# BuildMSIX.ps1
$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$LauncherDir = Join-Path $ProjectRoot "launcher"
$MsixSourceDir = Join-Path $ProjectRoot "CopilotLauncherMSIX"
$TargetBinaryPath = Join-Path $LauncherDir "target\release\launcher.exe"
$MsixBinaryDir = Join-Path $MsixSourceDir "Binary"
$OutputFile = Join-Path $ProjectRoot "CopilotLauncherMSIX.msix"
$CertFile = Join-Path $ProjectRoot "CopilotKeyRemapCert.pfx"
$CertPassword = "Password123!"

Write-Host "==> 1. Cleaning Rust build..." -ForegroundColor Cyan
Set-Location $LauncherDir
cargo clean

Write-Host "==> 2. Building Release binary..." -ForegroundColor Cyan
cargo build --release

if (-not (Test-Path $TargetBinaryPath)) {
    Write-Error "Release binary not found at $TargetBinaryPath"
}

Write-Host "==> 3. Copying compiled binary to MSIX folder..." -ForegroundColor Cyan
if (-not (Test-Path $MsixBinaryDir)) {
    New-Item -ItemType Directory -Path $MsixBinaryDir -Force | Out-Null
}
Copy-Item -Path $TargetBinaryPath -Destination (Join-Path $MsixBinaryDir "launcher.exe") -Force

Write-Host "==> 4. Locating Windows SDK tools (MakeAppx & SignTool)..." -ForegroundColor Cyan
$WinSdkDir = "C:\Program Files (x86)\Windows Kits\10\bin"
$MakeAppxPath = Get-ChildItem -Path $WinSdkDir -Filter "makeappx.exe" -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -like "*x64*" } |
                Select-Object -First 1 -ExpandProperty FullName

$SignToolPath = Get-ChildItem -Path $WinSdkDir -Filter "signtool.exe" -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -like "*x64*" } |
                Select-Object -First 1 -ExpandProperty FullName

if (-not $MakeAppxPath) {
    Write-Error "MakeAppx.exe not found. Please ensure Windows 10/11 SDK is installed."
}
if (-not $SignToolPath) {
    Write-Error "SignTool.exe not found. Please ensure Windows 10/11 SDK is installed."
}

Write-Host "==> 5. Packing folder into MSIX..." -ForegroundColor Cyan
Set-Location $ProjectRoot
if (Test-Path $OutputFile) {
    Remove-Item -Path $OutputFile -Force
}

& $MakeAppxPath pack /d "$MsixSourceDir" /p "$OutputFile" /o

Write-Host "==> 6. Signing MSIX package..." -ForegroundColor Cyan
& $SignToolPath sign /fd SHA256 /a /f "$CertFile" /p "$CertPassword" "$OutputFile"

Write-Host "==> SUCCESS: Created and signed $OutputFile" -ForegroundColor Green