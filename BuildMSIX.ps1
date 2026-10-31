# BuildMSIX.ps1
$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$LauncherDir = Join-Path $ProjectRoot "launcher"
$MsixSourceDir = Join-Path $ProjectRoot "CopilotLauncherMSIX"
$MsixBinaryDir = Join-Path $MsixSourceDir "Binary"
$ManifestPath = Join-Path $MsixSourceDir "AppxManifest.xml"
$BundleFile = Join-Path $ProjectRoot "CopilotLauncherMSIX.msixbundle"

$Architectures = @(
    @{ RustTarget = "x86_64-pc-windows-msvc"; MsixArch = "x64" },
    @{ RustTarget = "aarch64-pc-windows-msvc"; MsixArch = "arm64" }
)

Write-Host "==> 1. Locating Windows SDK tools (MakeAppx)..." -ForegroundColor Cyan
$WinSdkDir = "C:\Program Files (x86)\Windows Kits\10\bin"
$MakeAppxPath = Get-ChildItem -Path $WinSdkDir -Filter "makeappx.exe" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*x64*" } |
        Select-Object -First 1 -ExpandProperty FullName

if (-not $MakeAppxPath) { Write-Error "MakeAppx.exe not found. Please ensure Windows SDK is installed." }

# Create a temporary directory to hold the generated MSIX packages for bundling
$BundleDir = Join-Path $ProjectRoot "BundleTemp"
if (Test-Path $BundleDir) { Remove-Item -Path $BundleDir -Recurse -Force }
New-Item -ItemType Directory -Path $BundleDir | Out-Null

Write-Host "`n==> Syncing version from Cargo.toml to AppxManifest.xml..." -ForegroundColor Cyan
$CargoTomlPath = Join-Path $LauncherDir "Cargo.toml"
$CargoTomlContent = Get-Content $CargoTomlPath -Raw

if ($CargoTomlContent -match '(?m)^version\s*=\s*"([^"]+)"') {
    $CargoVersion = $Matches[1]

    # Microsoft Store requires a 4-part version ending in .0
    # This converts a standard Rust 3-part version (e.g., 1.0.1) to 1.0.1.0
    $MsixVersion = if ($CargoVersion -match "^\d+\.\d+\.\d+$") { "$CargoVersion.0" } else { $CargoVersion }

    $manifestContent = Get-Content $ManifestPath -Raw

    # STRICT REGEX FIX: Only target the Version attribute inside the <Identity> node
    $manifestContent = $manifestContent -replace '(?i)(<Identity[^>]+?\sVersion=)"[^"]+"', "`$1`"$MsixVersion`""

    Set-Content -Path $ManifestPath -Value $manifestContent -NoNewline

    Write-Host "    Manifest Version updated to: $MsixVersion"
} else {
    Write-Warning "Could not read version from Cargo.toml"
}

foreach ($Arch in $Architectures) {
    $Target = $Arch.RustTarget
    $MsixArch = $Arch.MsixArch

    Write-Host "`n==> Building Rust binary for $Target..." -ForegroundColor Cyan
    Set-Location $LauncherDir
    cargo build --target $Target --release

    $TargetBinaryPath = Join-Path $LauncherDir "target\$Target\release\launcher.exe"
    if (-not (Test-Path $TargetBinaryPath)) { Write-Error "Binary not found at $TargetBinaryPath" }

    Write-Host "==> Copying binary for $MsixArch..." -ForegroundColor Cyan
    if (-not (Test-Path $MsixBinaryDir)) { New-Item -ItemType Directory -Path $MsixBinaryDir -Force | Out-Null }
    Copy-Item -Path $TargetBinaryPath -Destination (Join-Path $MsixBinaryDir "launcher.exe") -Force

    Write-Host "==> Updating AppxManifest.xml for ProcessorArchitecture=$MsixArch..." -ForegroundColor Cyan
    # Read raw XML to safely replace the architecture without breaking namespaces
    $manifestContent = Get-Content $ManifestPath -Raw
    $manifestContent = $manifestContent -replace '(?i)\sProcessorArchitecture="[^"]+"', ''
    $manifestContent = $manifestContent -replace '(?i)(<Identity[^>]+?)\s*/>', "`$1 ProcessorArchitecture=`"$MsixArch`" />"
    Set-Content -Path $ManifestPath -Value $manifestContent -NoNewline

    $OutputFile = Join-Path $ProjectRoot "CopilotLauncherMSIX_$MsixArch.msix"
    if (Test-Path $OutputFile) { Remove-Item -Path $OutputFile -Force }

    Write-Host "==> Packing $MsixArch folder into MSIX..." -ForegroundColor Cyan
    Set-Location $ProjectRoot
    & $MakeAppxPath pack /d "$MsixSourceDir" /p "$OutputFile" /o

    # Copy the package to our bundling directory
    Copy-Item -Path $OutputFile -Destination $BundleDir -Force
}

Write-Host "`n==> Creating unified MSIX Bundle..." -ForegroundColor Cyan
if (Test-Path $BundleFile) { Remove-Item -Path $BundleFile -Force }
& $MakeAppxPath bundle /d "$BundleDir" /p "$BundleFile" /o

# Cleanup temporary bundle directory
Remove-Item -Path $BundleDir -Recurse -Force

Write-Host "`n==> SUCCESS: Created Store-ready bundle at $BundleFile" -ForegroundColor Green