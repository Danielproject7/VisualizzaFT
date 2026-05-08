@echo off
chcp 65001 >nul
title VisualizzaFT - Pubblica in produzione
cd /d "%~dp0"

echo.
echo  ============================================
echo   VisualizzaFT - Pubblica dev -^> produzione
echo  ============================================
echo.

REM Verifica che git sia installato
where git >nul 2>nul
if errorlevel 1 (
    echo  [ERRORE] Git non e' installato o non e' nel PATH.
    echo  Installa Git da https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

REM Verifica che la cartella sia un repo git
if not exist ".git" (
    echo  [ERRORE] Questa cartella non e' un repository git.
    echo.
    pause
    exit /b 1
)

REM Salva il branch corrente per ripristinarlo alla fine
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set CURRENT_BRANCH=%%i

REM Verifica che non ci siano modifiche non committate
git diff --quiet
if errorlevel 1 (
    echo  [ATTENZIONE] Hai modifiche non committate sul branch corrente.
    echo  Committa o annulla prima di pubblicare.
    echo.
    git status --short
    echo.
    pause
    exit /b 1
)
git diff --cached --quiet
if errorlevel 1 (
    echo  [ATTENZIONE] Hai modifiche staged non committate.
    echo  Committa prima di pubblicare.
    echo.
    pause
    exit /b 1
)

REM Aggiorna i riferimenti remoti
echo  Recupero stato dal server...
git fetch origin >nul 2>nul
echo.

REM Conta i commit di dev non presenti su main
for /f "tokens=*" %%i in ('git rev-list --count origin/main..origin/dev') do set COMMITS_AHEAD=%%i

if "%COMMITS_AHEAD%"=="0" (
    echo  Nessuna modifica da pubblicare: dev e main sono allineati.
    echo.
    pause
    exit /b 0
)

echo  Modifiche da pubblicare in produzione (%COMMITS_AHEAD% commit):
echo  --------------------------------------------------
git log --oneline origin/main..origin/dev
echo  --------------------------------------------------
echo.

REM Conferma esplicita
set /p CONFIRM="Pubblicare queste modifiche su https://visualizza-ft.vercel.app/ ? [s/N] "
if /i not "%CONFIRM%"=="s" (
    echo.
    echo  Annullato. Niente e' stato pubblicato.
    echo.
    pause
    exit /b 0
)

echo.
echo  Passaggio al branch main...
git checkout main
if errorlevel 1 goto :error_restore

echo  Aggiornamento di main dal remote...
git pull --ff-only
if errorlevel 1 goto :error_restore

echo  Merge di dev in main...
git merge --no-edit dev
if errorlevel 1 (
    echo.
    echo  [ERRORE] Merge fallito - probabilmente per un conflitto.
    echo  Risolvi i conflitti manualmente o annulla con:  git merge --abort
    echo.
    pause
    exit /b 1
)

echo  Push su origin/main (Vercel iniziera' il deploy)...
git push
if errorlevel 1 goto :error_restore

REM Torna al branch di partenza
echo.
echo  Ritorno al branch %CURRENT_BRANCH%...
git checkout %CURRENT_BRANCH%

echo.
echo  ============================================
echo   PUBBLICATO!
echo  ============================================
echo.
echo  Vercel iniziera' il deploy entro pochi secondi.
echo  Stato dei deploy: https://vercel.com/dashboard
echo  URL produzione:   https://visualizza-ft.vercel.app/
echo.
timeout /t 5 /nobreak >nul
exit /b 0

:error_restore
echo.
echo  [ERRORE] Operazione interrotta. Provo a riportarti su %CURRENT_BRANCH%...
git checkout %CURRENT_BRANCH% 2>nul
echo.
pause
exit /b 1
