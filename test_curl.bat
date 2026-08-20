@echo off
set KEY1=58a5c15d-94ba-4739-b7d4-cc4e4de2ff4ae
set KEY2=fff36f79-546b-4959-9011-6b941373fb3f

echo === Testing Volcengine ASR Endpoints ===
echo.

echo Test 1: v1 endpoint with Key1
curl.exe -L --connect-timeout 5 -s -w "HTTP %%{http_code}" -o nul -H "Authorization: Bearer;access_token=%KEY1%" "https://openspeech.bytedance.com/api/v1/asr"
echo.

echo Test 2: v2 endpoint with Key2
curl.exe -L --connect-timeout 5 -s -w "HTTP %%{http_code}" -o nul -H "Authorization: Bearer;access_token=%KEY2%" "https://openspeech.bytedance.com/api/v2/asr"
echo.

echo === Done ===