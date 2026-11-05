# ==============================================================================
# Explore Haryana - Local Development Web Server & Launcher
# Automatically serves on http://localhost:8080 or launches index.html directly
# ==============================================================================

param(
    [int]$Port = 8080
)

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$htmlFile = Join-Path $baseDir "index.html"
$prefix = "http://localhost:$Port/"

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "  Explore Haryana – Discover Beyond the Ordinary" -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Green

$listener = $null
$startedServer = $false

try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    $startedServer = $true
} catch {
    Write-Host "Note: Local port binding requires administrator privileges on this system." -ForegroundColor Gray
    Write-Host "Launching Explore Haryana directly in your web browser..." -ForegroundColor Cyan
    Start-Process $htmlFile
    Write-Host "Application opened successfully!" -ForegroundColor Green
    exit 0
}

if ($startedServer) {
    Write-Host "  Web server is running live at: $prefix" -ForegroundColor Cyan
    Write-Host "  Opening your web browser..." -ForegroundColor Gray
    Write-Host "  Press Ctrl+C in this window when you wish to stop the server." -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""

    Start-Process $prefix

    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            $path = $request.Url.LocalPath.TrimStart('/')
            if ([string]::IsNullOrEmpty($path)) {
                $path = "index.html"
            }

            $localPath = Join-Path $baseDir ($path.Replace('/', '\'))

            if (Test-Path $localPath -PathType Leaf) {
                $extension = [System.IO.Path]::GetExtension($localPath).ToLower()
                $contentType = switch ($extension) {
                    ".html" { "text/html; charset=utf-8" }
                    ".htm"  { "text/html; charset=utf-8" }
                    ".css"  { "text/css; charset=utf-8" }
                    ".js"   { "application/javascript; charset=utf-8" }
                    ".json" { "application/json; charset=utf-8" }
                    ".png"  { "image/png" }
                    ".jpg"  { "image/jpeg" }
                    ".jpeg" { "image/jpeg" }
                    ".svg"  { "image/svg+xml" }
                    ".ico"  { "image/x-icon" }
                    Default { "application/octet-stream" }
                }

                $response.ContentType = $contentType
                $bytes = [System.IO.File]::ReadAllBytes($localPath)
                $response.ContentLength64 = $bytes.Length
                $response.StatusCode = 200
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 404
                $notFoundBytes = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found: $path")
                $response.ContentLength64 = $notFoundBytes.Length
                $response.OutputStream.Write($notFoundBytes, 0, $notFoundBytes.Length)
            }

            $response.OutputStream.Close()
        }
    } catch {
        Write-Host "Server shutting down..." -ForegroundColor Gray
    } finally {
        if ($listener -and $listener.IsListening) {
            $listener.Stop()
        }
        if ($listener) {
            $listener.Close()
        }
    }
}
