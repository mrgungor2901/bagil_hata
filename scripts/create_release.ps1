Param(
    [string]$Owner = 'mrgungor2901',
    [string]$Repo = 'bagil_hata',
    [string]$Tag = 'v1.0.0',
    [string]$ReleaseNotes = 'RELEASES/v1.0.0.md',
    [string]$AssetPath = 'build/app/outputs/flutter-apk/app-release.apk'
)

if (-not $env:GITHUB_TOKEN) {
    Write-Error "GITHUB_TOKEN environment variable not set. Export your PAT to GITHUB_TOKEN and re-run."
    exit 1
}

try {
    $body = @{
        tag_name = $Tag
        name = $Tag
        body = Get-Content -Raw $ReleaseNotes
        draft = $false
        prerelease = $false
    } | ConvertTo-Json -Compress

    Write-Host "Creating release $Tag for $Owner/$Repo..."
    $resp = Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$Owner/$Repo/releases" `
        -Headers @{ Authorization = "token $env:GITHUB_TOKEN"; 'User-Agent' = "$Owner" } `
        -Body $body -ContentType 'application/json'

    if (-not $resp.upload_url) {
        Write-Error "Release creation response missing upload_url"
        exit 1
    }

    if (-not (Test-Path $AssetPath)) {
        Write-Error "Asset not found at path: $AssetPath"
        exit 1
    }

    $uploadUrl = $resp.upload_url -replace '\{.*\}$','?name=' + [System.IO.Path]::GetFileName($AssetPath)
    Write-Host "Uploading asset $AssetPath to release..."

    Invoke-RestMethod -Method Post -Uri $uploadUrl `
        -Headers @{ Authorization = "token $env:GITHUB_TOKEN"; 'User-Agent' = "$Owner"; 'Content-Type' = 'application/octet-stream' } `
        -InFile $AssetPath -UseBasicParsing

    Write-Host "Release and asset upload completed."
} catch {
    Write-Error "Error while creating release: $_"
    exit 1
}
