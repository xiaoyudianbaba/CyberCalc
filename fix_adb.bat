@echo off
echo Cleaning ADB state...
del /f /q "%USERPROFILE%\.android\adb.lock" 2>nul
del /f /q "%USERPROFILE%\.android\adb.*.lock" 2>nul
echo.
echo Stopping existing ADB processes...
taskkill /f /im adb.exe 2>nul
timeout /t 2 /nobreak >nul
echo.
echo Starting ADB server...
D:\Android\Sdk\platform-tools\adb.exe start-server
echo.
echo Connecting to device...
D:\Android\Sdk\platform-tools\adb.exe connect 192.168.0.103:41361
echo.
echo Done.