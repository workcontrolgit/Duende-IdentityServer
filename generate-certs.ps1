# Generate self-signed SSL certificates for local development
# Run this script as Administrator in PowerShell

$domains = @(
    "sts.skoruba.local",
    "admin.skoruba.local",
    "admin-api.skoruba.local"
)

$certPath = "shared\nginx\certs"

# Create certs directory if it doesn't exist
if (!(Test-Path $certPath)) {
    New-Item -ItemType Directory -Path $certPath -Force
}

foreach ($domain in $domains) {
    Write-Host "Generating certificate for $domain..." -ForegroundColor Green

    # Generate certificate
    $cert = New-SelfSignedCertificate `
        -DnsName $domain `
        -CertStoreLocation "cert:\LocalMachine\My" `
        -NotAfter (Get-Date).AddYears(2) `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -KeyExportPolicy Exportable

    # Export certificate as PFX (includes private key)
    $pfxFile = Join-Path $certPath "$domain.pfx"
    $password = ConvertTo-SecureString -String "password" -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath $pfxFile -Password $password | Out-Null

    # Convert PFX to CRT and KEY using OpenSSL (if available)
    $certFile = Join-Path $certPath "$domain.crt"
    $keyFile = Join-Path $certPath "$domain.key"

    # Try using OpenSSL if available
    try {
        & openssl pkcs12 -in $pfxFile -clcerts -nokeys -out $certFile -passin pass:password 2>$null
        & openssl pkcs12 -in $pfxFile -nocerts -nodes -out $keyFile -passin pass:password 2>$null

        if (Test-Path $certFile -and Test-Path $keyFile) {
            Write-Host "  Created: $certFile" -ForegroundColor Cyan
            Write-Host "  Created: $keyFile" -ForegroundColor Cyan
            Remove-Item $pfxFile -Force
        } else {
            Write-Host "  OpenSSL conversion failed, kept PFX: $pfxFile" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  OpenSSL not found, kept PFX: $pfxFile" -ForegroundColor Yellow
        Write-Host "  You may need to install OpenSSL to convert to .crt/.key format" -ForegroundColor Yellow
    }

    # Remove certificate from certificate store
    Remove-Item -Path "cert:\LocalMachine\My\$($cert.Thumbprint)" -Force

    Write-Host ""
}

Write-Host "Certificate generation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. If OpenSSL is not installed, install it from: https://slproweb.com/products/Win32OpenSSL.html"
Write-Host "2. Restart Docker containers: docker-compose down && docker-compose up"
Write-Host "3. Access services via HTTPS (you may need to accept browser security warnings)"
