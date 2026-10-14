param(
    [Parameter(Mandatory = $true)]
    [string]$LanIp
)

$ErrorActionPreference = 'Stop'

$parsedIp = $null
if (-not [System.Net.IPAddress]::TryParse($LanIp, [ref]$parsedIp) -or
    $parsedIp.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
    throw "Provide a valid IPv4 address, for example: .\scripts\setup-lan-https.ps1 -LanIp 192.168.0.133"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$certificateRoot = Join-Path $projectRoot 'eduportal_app\lan-certs'
$webRoot = Join-Path $projectRoot 'eduportal_app\build\web'
$rootCertificatePath = Join-Path $certificateRoot 'lan-ca.cer'
$serverCertificatePath = Join-Path $certificateRoot 'server-cert.pem'
$privateKeyPath = Join-Path $certificateRoot 'server-key.pem'
$thumbprintsPath = Join-Path $certificateRoot 'certificate-thumbprints.json'

if (-not (Test-Path (Join-Path $webRoot 'index.html'))) {
    throw 'Flutter web build not found. Run flutter build web in eduportal_app first.'
}

New-Item -ItemType Directory -Force -Path $certificateRoot | Out-Null

if (Test-Path $thumbprintsPath) {
    $oldThumbprints = Get-Content $thumbprintsPath -Raw | ConvertFrom-Json
    foreach ($thumbprint in @($oldThumbprints.ca, $oldThumbprints.server)) {
        if ($thumbprint) {
            Remove-Item "Cert:\CurrentUser\My\$thumbprint" -ErrorAction SilentlyContinue
            Remove-Item "Cert:\CurrentUser\Root\$thumbprint" -ErrorAction SilentlyContinue
        }
    }
}

Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.FriendlyName -like 'AcademyAlys LAN CA *' -or $_.FriendlyName -like 'AcademyAlys LAN HTTPS *' } |
    Remove-Item -ErrorAction SilentlyContinue

$suffix = [Guid]::NewGuid().ToString('N')
$ca = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=AcademyAlys LAN CA $suffix" `
    -FriendlyName "AcademyAlys LAN CA $suffix" `
    -KeyAlgorithm RSA `
    -KeyLength 3072 `
    -HashAlgorithm SHA256 `
    -KeyExportPolicy Exportable `
    -KeyUsage CertSign, CRLSign, DigitalSignature `
    -TextExtension @(
        '2.5.29.19={critical}{text}ca=TRUE&pathlength=0'
    ) `
    -CertStoreLocation 'Cert:\CurrentUser\My' `
    -NotAfter (Get-Date).AddYears(5)

$serverCertificate = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=$LanIp" `
    -FriendlyName "AcademyAlys LAN HTTPS $LanIp" `
    -Signer $ca `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -KeyExportPolicy Exportable `
    -KeyUsage DigitalSignature, KeyEncipherment `
    -TextExtension @(
        "2.5.29.17={text}IPAddress=$LanIp",
        '2.5.29.37={text}1.3.6.1.5.5.7.3.1'
    ) `
    -CertStoreLocation 'Cert:\CurrentUser\My' `
    -NotAfter (Get-Date).AddDays(30)

$rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($serverCertificate)
try {
    $privateKeyBytes = $rsa.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
    $privateKeyBase64 = [Convert]::ToBase64String(
        $privateKeyBytes,
        [Base64FormattingOptions]::InsertLineBreaks
    )
} finally {
    $rsa.Dispose()
}

$certificateBase64 = [Convert]::ToBase64String(
    $serverCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert),
    [Base64FormattingOptions]::InsertLineBreaks
)

@(
    '-----BEGIN PRIVATE KEY-----'
    $privateKeyBase64
    '-----END PRIVATE KEY-----'
) | Set-Content -Path $privateKeyPath -Encoding ascii

@(
    '-----BEGIN CERTIFICATE-----'
    $certificateBase64
    '-----END CERTIFICATE-----'
) | Set-Content -Path $serverCertificatePath -Encoding ascii

Export-Certificate -Cert $ca -FilePath $rootCertificatePath -Type CERT | Out-Null
Copy-Item -Path $rootCertificatePath -Destination (Join-Path $webRoot 'lan-ca.cer') -Force
$trustedRootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new(
    [System.Security.Cryptography.X509Certificates.StoreName]::Root,
    [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
)
try {
    $trustedRootStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $trustedRootStore.Add($ca)
} finally {
    $trustedRootStore.Close()
}

[PSCustomObject]@{
    ca = $ca.Thumbprint
    server = $serverCertificate.Thumbprint
} | ConvertTo-Json | Set-Content -Path $thumbprintsPath -Encoding ascii

Write-Output "Created the LAN HTTPS certificate for $LanIp."
Write-Output "The public CA certificate is available at http://${LanIp}:3000/lan-ca.cer"
Write-Output 'Install that certificate on each phone as a trusted CA certificate before opening the HTTPS URL.'
Write-Output 'The CA private key remains in the Windows user certificate store and is not exported.'
