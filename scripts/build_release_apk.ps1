<#
.SYNOPSIS
전도폭발 JUST EE 훈련 마스터 - 안전한 릴리즈 APK 원클릭 빌드 스크립트

.DESCRIPTION
1. LICENSE_API_URL 검증 (key.properties / 환경변수 / 파라미터)
2. 라이선스 서버 헬스체크 (status=OK, protocol=device_token_v2)
3. 릴리즈 서명 키 확인 (android/key.properties)
4. flutter build apk --release --dart-define=LICENSE_API_URL=... 실행
5. 빌드 산출물 서명 및 SHA-256 무결성 검증
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$LicenseApiUrl = "",

    [Parameter(Mandatory = $false)]
    [switch]$SkipHealthCheck
)

$ErrorActionPreference = "Stop"
$ProjectRoot = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { (Get-Location).Path }
Set-Location $ProjectRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  JUST EE Master - Release APK Build Pipeline" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. LICENSE_API_URL 확인
$KeyPropsPath = Join-Path $ProjectRoot "android\key.properties"
if (-not $LicenseApiUrl -and (Test-Path $KeyPropsPath)) {
    Get-Content $KeyPropsPath | ForEach-Object {
        if ($_ -match "^\s*licenseApiUrl\s*=\s*(.+)$") {
            $LicenseApiUrl = $matches[1].Trim()
        }
    }
}

if (-not $LicenseApiUrl -and $env:LICENSE_API_URL) {
    $LicenseApiUrl = $env:LICENSE_API_URL.Trim()
}

if (-not $LicenseApiUrl) {
    Write-Error "CRITICAL: LICENSE_API_URL이 설정되지 않았습니다.`nandroid/key.properties에 licenseApiUrl=https://script.google.com/macros/s/.../exec 를 추가하거나, -LicenseApiUrl 파라미터를 전달하세요."
}

# 2. URL 형식 검증
$UrlPattern = "^https://script\.google\.com/macros/s/[a-zA-Z0-9_\-]+/exec$"
if ($LicenseApiUrl -notmatch $UrlPattern) {
    Write-Error "CRITICAL: LICENSE_API_URL 형식이 올바르지 않습니다: $LicenseApiUrl`n올바른 형식: https://script.google.com/macros/s/.../exec"
}
Write-Host "[1/5] Server URL verified (Format: Google Apps Script WebApp)" -ForegroundColor Green

# 3. 헬스체크
if (-not $SkipHealthCheck) {
    Write-Host "[2/5] Performing pre-flight health check on licensing server..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri $LicenseApiUrl -Method Get -TimeoutSec 15
        if ($response.status -ne "OK" -or $response.protocol -ne "device_token_v2") {
            Write-Error "Server health check failed: Unexpected response. status=$($response.status), protocol=$($response.protocol). Expected protocol='device_token_v2'."
        }
        Write-Host "      Server healthy! (protocol: $($response.protocol), status: $($response.status))" -ForegroundColor Green
    } catch {
        Write-Error "Server connection failed: $($_.Exception.Message)`n(오프라인 빌드를 진행하려면 -SkipHealthCheck 스위치를 사용하세요)"
    }
} else {
    Write-Host "[2/5] Skipping pre-flight health check (-SkipHealthCheck specified)" -ForegroundColor Gray
}

# 4. 서명 키 확인
if (-not (Test-Path $KeyPropsPath)) {
    Write-Error "CRITICAL: android/key.properties 파일이 없습니다. 릴리즈 서명 키가 필요합니다."
}
Write-Host "[3/5] Release keystore configuration verified" -ForegroundColor Green

# 5. Flutter 릴리즈 빌드 실행
Write-Host "[4/5] Executing flutter build apk --release..." -ForegroundColor Yellow
& flutter build apk --release "--dart-define=LICENSE_API_URL=$LicenseApiUrl"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter release build failed with exit code $LASTEXITCODE"
}

# 6. 산출물 검증
$ApkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path -Path $ApkPath)) {
    Write-Error "CRITICAL: 빌드 산출물 app-release.apk 를 찾을 수 없습니다."
}

$ApkFile = Get-Item -Path $ApkPath
$ApkHash = (Get-FileHash -Path $ApkPath -Algorithm SHA256).Hash
$ApkSizeMb = [math]::Round($ApkFile.Length / 1MB, 2)

Write-Host "[5/5] Release APK verified successfully!" -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  APK Path  : $ApkPath" -ForegroundColor White
Write-Host "  File Size : $ApkSizeMb MB ($($ApkFile.Length) bytes)" -ForegroundColor White
Write-Host "  SHA-256   : $ApkHash" -ForegroundColor White
Write-Host "  Timestamp : $($ApkFile.LastWriteTime)" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
