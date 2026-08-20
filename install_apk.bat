@echo off
echo Installing CyberCalc APK...
D:\Android\Sdk\platform-tools\adb.exe install -r D:\CyberCalc\build\app\outputs\flutter-apk\app-release.apk
echo Exit code: %ERRORLEVEL%