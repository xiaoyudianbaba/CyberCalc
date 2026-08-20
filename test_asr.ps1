$apiKey1 = "58a5c15d-94ba-4739-b7d4-cc4e4de2ff4ae"
$apiKey2 = "fff36f79-546b-4959-9011-6b941373fb3f"

Write-Host "=== 火山引擎 ASR 端点检测 ===" -ForegroundColor Cyan

$endpoints = @(
    "https://openspeech.bytedance.com/api/v1/asr"
    "https://openspeech.bytedance.com/api/v2/asr"
    "https://openspeech.bytedance.com/api/v1/ws"
    "https://openspeech.bytedance.com/api/v2/ws"
    "https://openspeech.bytedance.com/"
)

foreach ($ep in $endpoints) {
    try {
        $code = curl.exe -L --connect-timeout 5 -s -o nul -w "%{http_code}" -H "Authorization: Bearer;access_token=$apiKey1" $ep 2>&1
        Write-Host "$ep -> HTTP $code" -ForegroundColor $(if ($code -eq "200") { "Green" } else { "Yellow" })
    } catch {
        Write-Host "$ep -> ERROR" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== 测试结束 ===" -ForegroundColor Cyan