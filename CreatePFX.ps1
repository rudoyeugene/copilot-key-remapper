# Setup Certificate and Check Rights
$CertSubject = "CN=EugeneRudo"
$PfxPath = "D:\Projects\Copilot Key Remapper\CopilotKeyRemapCert.pfx"
$CertPassword = "Password123!"

# 1. Function to check if current shell is elevated
function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 2. Check if certificate is already in LocalMachine\Root
$existingCert = Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object { $_.Subject -match "EugeneRudo" }

if ($existingCert) {
    Write-Host "Certificate '$CertSubject' is already installed in LocalMachine\Root." -ForegroundColor Yellow
    $choice = Read-Host "Do you want to reinstall it? (Y/N)"
    if ($choice -notmatch '^[Yy]$') {
        Write-Host "Exiting without changes." -ForegroundColor Cyan
        exit
    }
}

# 3. If elevated rights are missing, relaunch script elevated (UAC prompt)
if (-not (Test-IsAdmin)) {
    Write-Host "Admin permissions required to install certificate to LocalMachine\Root." -ForegroundColor Yellow
    Write-Host "Requesting elevated permissions..." -ForegroundColor Yellow

    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# 4. Create and export PFX certificate
Write-Host "Creating self-signed certificate..." -ForegroundColor Cyan
$cert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject $CertSubject `
    -KeyUsage DigitalSignature `
    -FriendlyName "Copilot Key Remap Dev Cert" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

$secPassword = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText

Write-Host "Exporting certificate to $PfxPath..." -ForegroundColor Cyan
Export-PfxCertificate `
    -Cert $cert `
    -FilePath $PfxPath `
    -Password $secPassword | Out-Null

# 5. Install to LocalMachine\Root
Write-Host "Installing certificate to Cert:\LocalMachine\Root..." -ForegroundColor Cyan
Import-PfxCertificate `
    -FilePath $PfxPath `
    -CertStoreLocation "Cert:\LocalMachine\Root" `
    -Password $secPassword | Out-Null

Write-Host "SUCCESS: Certificate $CertSubject installed successfully!" -ForegroundColor Green
Pause