# masjid-display/serve-web.ps1
#
# Minimal static web server for the app's web build, using only built-in
# Windows PowerShell (no Python/Node needed). Listens on localhost only, so
# the app isn't reachable from other machines.
#
# Usage: powershell -ExecutionPolicy Bypass -File serve-web.ps1 [-Root <folder>] [-Port 8080]

param(
    [string]$Root = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\web'),
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path (Join-Path $Root 'index.html'))) {
    Write-Error "No index.html in '$Root'. Run setup.bat to build the app."
    exit 1
}
# Normalise with a trailing slash so the "inside Root" check below is exact.
$Root = (Resolve-Path $Root).Path.TrimEnd('\') + '\'

$mimeTypes = @{
    '.html'  = 'text/html; charset=utf-8'
    '.js'    = 'text/javascript; charset=utf-8'
    '.mjs'   = 'text/javascript; charset=utf-8'
    '.json'  = 'application/json'
    '.wasm'  = 'application/wasm'
    '.css'   = 'text/css'
    '.png'   = 'image/png'
    '.jpg'   = 'image/jpeg'
    '.jpeg'  = 'image/jpeg'
    '.gif'   = 'image/gif'
    '.svg'   = 'image/svg+xml'
    '.ico'   = 'image/x-icon'
    '.otf'   = 'font/otf'
    '.ttf'   = 'font/ttf'
    '.woff'  = 'font/woff'
    '.woff2' = 'font/woff2'
    '.txt'   = 'text/plain; charset=utf-8'
    '.env'   = 'text/plain; charset=utf-8'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $Root at http://localhost:$Port/  (Ctrl+C to stop)"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $response = $context.Response
        try {
            $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath).TrimStart('/')
            if ($relative -eq '') { $relative = 'index.html' }

            $file = [IO.Path]::GetFullPath((Join-Path $Root $relative))
            $insideRoot = $file.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)

            if (-not $insideRoot -or -not (Test-Path -LiteralPath $file -PathType Leaf)) {
                if ($insideRoot -and -not [IO.Path]::HasExtension($relative)) {
                    # App route (no file extension): let the app handle it.
                    $file = Join-Path $Root 'index.html'
                } else {
                    $response.StatusCode = 404
                    $file = $null
                }
            }

            if ($file) {
                $bytes = [IO.File]::ReadAllBytes($file)
                $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
                $response.ContentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { 'application/octet-stream' }
                # Always revalidate, so an updated web build shows after a reload.
                $response.Headers['Cache-Control'] = 'no-cache'
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        } catch {
            try { $response.StatusCode = 500 } catch { }
        } finally {
            $response.Close()
        }
    }
} finally {
    $listener.Stop()
}
