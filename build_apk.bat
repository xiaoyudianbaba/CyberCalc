@echo off
cd /d D:\CyberCalc
call flutter build apk --release --no-pub
echo Build exit code: %ERRORLEVEL%