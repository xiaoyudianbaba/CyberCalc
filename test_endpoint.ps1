Write-Host "=== 火山引擎 ASR 端点检测 ===" -ForegroundColor Cyan
Write-Host ""

$apiKey1 = "58a5c15d-94ba-4739-b7d4-cc4e4de2ff4ae"
$apiKey2 = "fff36f79-546b-4959-9011-6b941373fb3f"

$endpoints = @(
    @{Url="https://openspeech.bytedance.com/api/v1/asr"; Label="v1 REST"}
    @{Url="wss://openspeech.bytedance.com/api/v1/asr"; Label="v1 WS"}
    @{Url="https://openspeech.bytedance.com/api/v2/asr"; Label="v2 REST"}
    @{Url="wss://openspeech.bytedance.com/api/v2/asr"; Label="v2 WS"}
    @{Url="https://openspeech.bytedance.com/api/v2/ws"; Label="v2 WS Rest"}
    @{Url="https://openspeech.bytedance.com/api/v1"; Label="v1 Base"}
    @{Url="https://openspeech.bytedance.com/"; Label="Root"}
)

foreach($ep in $endpoints) {
    try {
        $req = [System.Net.HttpWebRequest]::Create($ep.Url)
        $req.Headers.Add("Authorization", "Bearer;access_token=$apiKey1")
        $req.Timeout = 5000
        $resp = $req.GetResponse()
        $code = [int]$resp.StatusCode
        Write-Host "$($ep.Label): $($ep.Url) -> HTTP $code OK" -ForegroundColor Green
        $resp.Close()
    } catch {
        Write-Host "$($ep.Label): $($ep.Url) -> $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Cyan