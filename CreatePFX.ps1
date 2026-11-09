# Setup Certificate and Check Rights
$CertSubject = "CN=8C2213FA-9986-4D7F-9A2C-4C690B7E5BF5"
$PfxPath = "D:\Projects\copilot-key-remapper\CopilotKeyRemapCert.pfx"
$CertPassword = "Password123!"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "Admin permissions required to install certificate." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$PfxDir = Split-Path -Parent $PfxPath
if (-not (Test-Path $PfxDir)) {
    New-Item -ItemType Directory -Path $PfxDir -Force | Out-Null
}

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
Export-PfxCertificate -Cert $cert -FilePath $PfxPath -Password $secPassword | Out-Null

# Install to Root AND TrustedPeople
Write-Host "Installing certificate to Root and TrustedPeople stores..." -ForegroundColor Cyan
Import-PfxCertificate -FilePath $PfxPath -CertStoreLocation "Cert:\LocalMachine\Root" -Password $secPassword | Out-Null
Import-PfxCertificate -FilePath $PfxPath -CertStoreLocation "Cert:\LocalMachine\TrustedPeople" -Password $secPassword | Out-Null

Write-Host "SUCCESS: Certificate installed successfully!" -ForegroundColor Green
Pause