# Simple static file server for Monster Truck game
# Run: powershell -ExecutionPolicy Bypass -File serve.ps1

$port = 8765
$root = $PSScriptRoot
$url = "http://localhost:$port/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
$listener.Start()
Write-Host "Monster Truck server running at $url"
Write-Host "Press Ctrl+C to stop."

# Open Chrome automatically
Start-Process "chrome.exe" "$url" -ErrorAction SilentlyContinue
if ($?) {} else {
    Start-Process "msedge.exe" "$url" -ErrorAction SilentlyContinue
}

$mimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".js"   = "application/javascript"
  ".wasm" = "application/wasm"
  ".data" = "application/octet-stream"
  ".tflite" = "application/octet-stream"
  ".binarypb" = "application/octet-stream"
  ".css"  = "text/css"
}

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response

    $localPath = $req.Url.LocalPath.TrimStart('/')
    if ($localPath -eq "") { $localPath = "index.html" }
    $filePath = Join-Path $root $localPath

    if (Test-Path $filePath -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
      $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
      $res.ContentType = $mime
      $res.Headers.Add("Cross-Origin-Opener-Policy", "same-origin")
      $res.Headers.Add("Cross-Origin-Embedder-Policy", "require-corp")
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
      $body = [System.Text.Encoding]::UTF8.GetBytes("Not found: $localPath")
      $res.OutputStream.Write($body, 0, $body.Length)
    }
    $res.OutputStream.Close()
  } catch {
    # ignore connection resets
  }
}
