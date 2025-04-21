$token  = "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"
$owner  = "SatbytePnts"
$repo   = "OutCmd"
$branch = "main"
$path   = "test-folder/hello.txt"

$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.3"
}

function Update-GitHubFile($contentRaw) {
    $contentEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($contentRaw))

    $getUrl = "https://api.github.com/repos/$owner/$repo/contents/$path"
    Write-Host "🔍 Проверка существования файла: $getUrl"

    try {
        $existing = Invoke-RestMethod -Uri $getUrl -Headers $headers -Method GET
        $sha = $existing.sha
        Write-Host "Файл уже существует. SHA: $sha" -ForegroundColor Yellow
    }
    catch {
        $sha = $null
        Write-Host "Файл не найден. Будет создан новый." -ForegroundColor Green
    }

    $body = @{
        message = "Обновление лога PowerShell-команд"
        content = $contentEncoded
        branch  = $branch
    }
    if ($sha) {
        $body.sha = $sha
    }
    $bodyJson = $body | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri $getUrl `
                                      -Headers $headers `
                                      -Method PUT `
                                      -Body $bodyJson `
                                      -ContentType "application/json"
        Write-Host "✅ Коммит создан: $($response.commit.sha)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Ошибка: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "📄 Ответ: $($_.ErrorDetails.Message)" -ForegroundColor DarkGray
    }
}

# Цикл выполнения команд
while ($true) {
    $cmd = Read-Host "Введите PowerShell-команду (или 'exit' для выхода)"
    if ($cmd -eq 'exit') { break }

    try {
        $output = Invoke-Expression $cmd | Out-String
    }
    catch {
        $output = "[Ошибка выполнения команды] $($_.Exception.Message)"
    }

    Write-Host "Результат выполнения:
$output"

    # Обновляем файл в GitHub
    Update-GitHubFile -contentRaw $output
}

Write-Host "Сессия завершена." -ForegroundColor Magenta
