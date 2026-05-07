@echo off
chcp 65001 >nul
title VisualizzaFT - Aggiornamento
cd /d "%~dp0"

echo.
echo  ==========================================
echo   VisualizzaFT - Aggiornamento da GitHub
echo  ==========================================
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
    echo  Eseguire prima:  git clone https://github.com/Danielproject7/VisualizzaFT.git
    echo.
    pause
    exit /b 1
)

REM Pull degli aggiornamenti
echo  Recupero ultimi aggiornamenti...
echo.
git pull --ff-only
set PULL_EXIT=%errorlevel%
echo.

if %PULL_EXIT% neq 0 (
    echo  [ATTENZIONE] L'aggiornamento non e' andato a buon fine.
    echo  Possibili cause: modifiche locali non committate, conflitti, problemi di rete.
    echo.
    set /p RUN_ANYWAY="Vuoi aprire comunque l'applicazione con la versione attuale? [s/N] "
    if /i not "%RUN_ANYWAY%"=="s" (
        exit /b 1
    )
)

REM Mostra l'ultimo commit per dare conferma
echo  Versione corrente:
git log -1 --pretty=format:"  %%h - %%s (%%cr)"
echo.
echo.

REM Apri l'applicazione nel browser predefinito
echo  Apertura applicazione nel browser...
start "" "%~dp0index.html"

REM Chiudi automaticamente dopo 3 secondi
timeout /t 3 /nobreak >nul
exit /b 0
