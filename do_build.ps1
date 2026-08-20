Set-Location D:\CyberCalc
Write-Host "=== Starting clean build ==="
flutter clean 2>&1 | Out-Null
Write-Host "Cleaned."
flutter build apk --release --no-pub 2>&1
Write-Host "Build exit code: $LASTEXITCODE"