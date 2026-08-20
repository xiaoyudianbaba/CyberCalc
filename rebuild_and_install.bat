@echo off
cd /d D:\CyberCalc

echo === Step 1: Clean ===
call flutter clean 2>&1
echo Clean done.

echo === Step 2: Get packages ===
call flutter pub get 2>&1
echo Pub get done.

echo === Step 3: Build APK ===
call flutter build apk --release 2>&1
echo Build done.

echo === Step 4: Install via ADB ===
D:\Android\Sdk\platform-tools\adb.exe install -r D:\CyberCalc\build\app\outputs\flutter-apk\app-release.apk
echo Install done.

echo === Complete ===