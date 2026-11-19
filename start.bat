@echo off
rem SquadPanel - one-click dev start for Windows.
rem Installs dependencies on first run, starts worker + web (npm run dev)
rem and opens http://127.0.0.1:5173 in the browser as soon as the panel answers.
setlocal
cd /d "%~dp0"
title SquadPanel

where node >nul 2>nul
if errorlevel 1 (
  echo [SquadPanel] Node.js 24+ is required: https://nodejs.org/
  pause
  exit /b 1
)

if not exist "node_modules\" (
  echo [SquadPanel] Installing dependencies, this takes a minute...
  call npm install
  if errorlevel 1 (
    echo [SquadPanel] npm install failed.
    pause
    exit /b 1
  )
)

set "SQUADPANEL_URL=http://127.0.0.1:5173"
echo [SquadPanel] Starting... the browser opens %SQUADPANEL_URL% when ready. Ctrl+C to stop.
start "" /b powershell -NoProfile -ExecutionPolicy Bypass -Command "$u=$env:SQUADPANEL_URL; for($i=0;$i -lt 180;$i++){ try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -MaximumRedirection 0 $u -ErrorAction Stop | Out-Null; break } catch { if($_.Exception.Response){ break }; Start-Sleep -Seconds 1 } }; Start-Process $u"

call npm run dev
echo.
echo [SquadPanel] Stopped.
pause
endlocal
