$ErrorActionPreference = 'Continue'

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot 'eduportal_backend'
$pythonPath = Join-Path $backendRoot 'venv\Scripts\python.exe'
$serverPath = Join-Path $projectRoot 'lan_https_server.js'
$serverCertPath = Join-Path $projectRoot 'eduportal_app\lan-certs\server-cert.pem'
$serverKeyPath = Join-Path $projectRoot 'eduportal_app\lan-certs\server-key.pem'
$caCertPath = Join-Path $projectRoot 'eduportal_app\lan-certs\lan-ca.cer'
$webBuildPath = Join-Path $projectRoot 'eduportal_app\build\web\index.html'
$logRoot = Join-Path $projectRoot 'logs\local-stack'
$stackLogPath = Join-Path $logRoot 'supervisor.log'
$backendOutputPath = Join-Path $logRoot 'backend.stdout.log'
$backendErrorPath = Join-Path $logRoot 'backend.stderr.log'
$httpsOutputPath = Join-Path $logRoot 'https.stdout.log'
$httpsErrorPath = Join-Path $logRoot 'https.stderr.log'
$lanIp = '192.168.0.133'

New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

function Write-StackLog {
    param([string]$Message)
    Add-Content -LiteralPath $stackLogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
}

function Test-Endpoint {
    param(
        [string]$Url,
        [bool]$UseDefaultCredentials = $false
    )
    try {
        $params = @{
            Uri = $Url
            TimeoutSec = 3
            UseBasicParsing = $true
            ErrorAction = 'Stop'
        }
        if ($UseDefaultCredentials) {
            $params.Credential = [System.Management.Automation.PSCredential]::Empty
        }
        $response = Invoke-WebRequest @params
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Get-ListeningProcessId {
    param([int]$Port)
    try {
        $connection = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop |
            Select-Object -First 1
        return [int]$connection.OwningProcess
    } catch {
        return $null
    }
}

function Start-Backend {
    if (-not (Test-Path $pythonPath)) {
        Write-StackLog "Backend Python was not found at $pythonPath"
        return $null
    }

    Push-Location $backendRoot
    try {
        $seedOutput = & $pythonPath -c 'from app.seed import seed_database; seed_database()' 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-StackLog 'Database initialization failed; the API was not started.'
            return $null
        }
    } finally {
        Pop-Location
    }

    $previousHost = $env:HOST
    $previousPort = $env:PORT
    $env:HOST = '127.0.0.1'
    $env:PORT = '8000'
    try {
        $process = Start-Process `
            -FilePath $pythonPath `
            -ArgumentList @('-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', '8000') `
            -WorkingDirectory $backendRoot `
            -WindowStyle Hidden `
            -RedirectStandardOutput $backendOutputPath `
            -RedirectStandardError $backendErrorPath `
            -PassThru
    } catch {
        Write-StackLog "Could not start the backend: $($_.Exception.Message)"
        return $null
    } finally {
        $env:HOST = $previousHost
        $env:PORT = $previousPort
    }

    Write-StackLog "Started backend process $($process.Id)."
    return $process.Id
}

function Start-HttpsServer {
    if (-not (Test-Path $serverPath) -or
        -not (Test-Path $serverCertPath) -or
        -not (Test-Path $serverKeyPath) -or
        -not (Test-Path $caCertPath) -or
        -not (Test-Path $webBuildPath)) {
        Write-StackLog 'HTTPS server prerequisites are missing; run the setup instructions in README.md.'
        return $null
    }

    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) {
        Write-StackLog 'node.exe was not found on PATH.'
        return $null
    }

    $previousValues = @{
        LAN_IP = $env:LAN_IP
        PORT = $env:PORT
        CERT_PORT = $env:CERT_PORT
        HOST = $env:HOST
        API_HOST = $env:API_HOST
        API_PORT = $env:API_PORT
    }

    $env:LAN_IP = $lanIp
    $env:PORT = '3001'
    $env:CERT_PORT = '3000'
    $env:HOST = '0.0.0.0'
    $env:API_HOST = '127.0.0.1'
    $env:API_PORT = '8000'
    try {
        $process = Start-Process `
            -FilePath $node.Source `
            -ArgumentList @('lan_https_server.js') `
            -WorkingDirectory $projectRoot `
            -WindowStyle Hidden `
            -RedirectStandardOutput $httpsOutputPath `
            -RedirectStandardError $httpsErrorPath `
            -PassThru
    } catch {
        Write-StackLog "Could not start the HTTPS server: $($_.Exception.Message)"
        return $null
    } finally {
        foreach ($key in $previousValues.Keys) {
            Set-Item -Path "Env:\$key" -Value $previousValues[$key]
        }
    }

    Write-StackLog "Started HTTPS server process $($process.Id)."
    return $process.Id
}

$wifiIp = Get-NetIPAddress -InterfaceAlias 'Wi-Fi' -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '169.254.*' } |
    Select-Object -First 1 -ExpandProperty IPAddress

if ($wifiIp -and $wifiIp -ne $lanIp) {
    Write-StackLog "Wi-Fi address changed to $wifiIp, but the HTTPS certificate/app is configured for $lanIp. Reserve $lanIp for this PC on the router or regenerate the certificate and web build."
}

Write-StackLog 'Local stack supervisor started.'
$backendPid = $null
$httpsPid = $null
$lastStatusLog = Get-Date

while ($true) {
    if (-not (Test-Endpoint -Url 'http://127.0.0.1:8000/api/health')) {
        $existingBackendPid = Get-ListeningProcessId -Port 8000
        if ($existingBackendPid) {
            Write-StackLog "Port 8000 is occupied by process $existingBackendPid, but the API health check failed."
        } else {
            $backendPid = Start-Backend
        }
    } elseif (-not $backendPid) {
        $backendPid = Get-ListeningProcessId -Port 8000
        Write-StackLog "Backend is already healthy under process $backendPid."
    }

    if (-not (Test-Endpoint -Url "https://${lanIp}:3001/api/health")) {
        $existingHttpsPid = Get-ListeningProcessId -Port 3001
        if ($existingHttpsPid) {
            Write-StackLog "Port 3001 is occupied by process $existingHttpsPid, but HTTPS/API health failed."
        } else {
            $httpsPid = Start-HttpsServer
        }
    } elseif (-not $httpsPid) {
        $httpsPid = Get-ListeningProcessId -Port 3001
        Write-StackLog "HTTPS/API proxy is already healthy under process $httpsPid."
    }

    if (((Get-Date) - $lastStatusLog).TotalMinutes -ge 30) {
        Write-StackLog 'Local stack supervisor remains healthy.'
        $lastStatusLog = Get-Date
    }

    Start-Sleep -Seconds 15
}
