# GowienHelper - lancador unico.
# Garante Ollama no ar, sobe o backend e abre Swagger (/docs) + Painel da IA (/ai).
$ErrorActionPreference = 'SilentlyContinue'

$root    = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $root 'backend'
$py      = Join-Path $backend '.venv\Scripts\python.exe'

function Test-Port([int]$port) {
  try {
    $c = New-Object Net.Sockets.TcpClient
    $c.Connect('127.0.0.1', $port); $c.Close(); return $true
  } catch { return $false }
}

Write-Host "==> GowienHelper" -ForegroundColor Cyan

# 1) Ollama (motor da IA) -------------------------------------------------
if (-not (Test-Port 11434)) {
  Write-Host "    Iniciando Ollama..." -ForegroundColor DarkGray
  $ollama = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
  if (Test-Path $ollama) {
    Start-Process $ollama -ArgumentList 'serve' -WindowStyle Hidden
    for ($i = 0; $i -lt 30; $i++) { if (Test-Port 11434) { break }; Start-Sleep -Milliseconds 500 }
  } else {
    Write-Host "    [aviso] Ollama nao encontrado - a IA pode nao responder." -ForegroundColor Yellow
  }
}
if (Test-Port 11434) { Write-Host "    Ollama OK (11434)" -ForegroundColor Green }

# 2) Backend + navegador --------------------------------------------------
if (Test-Port 8000) {
  Write-Host "    Backend ja estava no ar (porta 8000)." -ForegroundColor Green
  Start-Process 'http://localhost:8000/docs'
  Start-Sleep -Milliseconds 400
  Start-Process 'http://localhost:8000/ai'
  Write-Host "    Navegador aberto (Swagger + Painel da IA)." -ForegroundColor Green
} else {
  # abre o navegador assim que a porta 8000 responder (job sobrevive pois o uvicorn segura a sessao)
  Start-Job -ScriptBlock {
    for ($i = 0; $i -lt 90; $i++) {
      try { $c = New-Object Net.Sockets.TcpClient; $c.Connect('127.0.0.1', 8000); $c.Close(); break }
      catch { Start-Sleep -Milliseconds 500 }
    }
    Start-Process 'http://localhost:8000/docs'
    Start-Sleep -Milliseconds 400
    Start-Process 'http://localhost:8000/ai'
  } | Out-Null

  Write-Host "    Subindo o backend em http://localhost:8000 ..." -ForegroundColor DarkGray
  Write-Host "    (deixe esta janela aberta; Ctrl+C aqui desliga o backend)" -ForegroundColor DarkGray
  Set-Location $backend
  & $py -m uvicorn app.main:app --host 0.0.0.0 --port 8000
}
