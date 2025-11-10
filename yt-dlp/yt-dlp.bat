@echo off
setlocal enabledelayedexpansion
title yt-dlp Downloader - Windows 10
color 0a

:: Configurações principais
set "SCRIPT_DIR=%~dp0"
set "YTDLP=%SCRIPT_DIR%yt-dlp.exe"
set "OUTPUT_DIR=%SCRIPT_DIR%Downloads"
set "LOG_FILE=%OUTPUT_DIR%\download_log.txt"

:: Verificar se yt-dlp existe
if not exist "%YTDLP%" (
    echo [ERRO] yt-dlp.exe nao encontrado!
    echo.
    echo Coloque o yt-dlp.exe nesta pasta:
    echo %SCRIPT_DIR%
    echo.
    pause
    exit /b 1
)

:: Criar pasta de downloads
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%" >nul 2>&1
)

:MAIN_MENU
cls
echo ==================================
echo        yt-dlp DOWNLOADER
echo ==================================
echo.
echo Selecione o tipo de download:
echo.
echo 1 - Baixar VIDEO + AUDIO (MP4)
echo 2 - Baixar apenas AUDIO (M4A)
echo 3 - Baixar PLAYLIST completa (MP4)
echo 4 - Sair
echo.

choice /C 1234 /N /M "Escolha uma opcao: "
set "OPTION=%ERRORLEVEL%"

if "%OPTION%"=="1" goto GET_URL_VIDEO
if "%OPTION%"=="2" goto GET_URL_AUDIO
if "%OPTION%"=="3" goto GET_URL_PLAYLIST
if "%OPTION%"=="4" goto EXIT

goto MAIN_MENU

:GET_URL_VIDEO
cls
echo ================================
echo    DOWNLOAD: VIDEO + AUDIO (MP4)
echo ================================
echo.
set "URL="
set /p "URL=Digite a URL do video: "
if "!URL!"=="" (
    echo.
    echo [ERRO] URL nao pode estar vazia!
    timeout /t 2 >nul
    goto GET_URL_VIDEO
)
call :DOWNLOAD_VIDEO
goto MAIN_MENU

:GET_URL_AUDIO
cls
echo ================================
echo      DOWNLOAD: APENAS AUDIO (M4A)
echo ================================
echo.
set "URL="
set /p "URL=Digite a URL do video: "
if "!URL!"=="" (
    echo.
    echo [ERRO] URL nao pode estar vazia!
    timeout /t 2 >nul
    goto GET_URL_AUDIO
)
call :DOWNLOAD_AUDIO
goto MAIN_MENU

:GET_URL_PLAYLIST
cls
echo ================================
echo    DOWNLOAD: PLAYLIST (MP4)
echo ================================
echo.
set "URL="
set /p "URL=Digite a URL da playlist: "
if "!URL!"=="" (
    echo.
    echo [ERRO] URL nao pode estar vazia!
    timeout /t 2 >nul
    goto GET_URL_PLAYLIST
)
call :DOWNLOAD_PLAYLIST
goto MAIN_MENU

:DOWNLOAD_VIDEO
echo.
echo Iniciando download de VIDEO + AUDIO...
echo.

:: Log
echo [%date% %time%] VIDEO: !URL! >> "%LOG_FILE%"

:: Comando yt-dlp para video + audio
"%YTDLP%" ^
    -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" ^
    --merge-output-format mp4 ^
    --newline ^
    --progress ^
    --console-title ^
    --no-overwrites ^
    --restrict-filenames ^
    -o "%OUTPUT_DIR%\%%(title)s.%%(ext)s" ^
    "!URL!"

if !errorlevel! neq 0 (
    echo [ERRO] Download falhou! Codigo: !errorlevel!
    echo [%date% %time%] ERRO: !URL! >> "%LOG_FILE%"
) else (
    echo [SUCESSO] Download concluido!
    echo [%date% %time%] SUCESSO: !URL! >> "%LOG_FILE%"
)

echo.
pause
exit /b

:DOWNLOAD_AUDIO
echo.
echo Iniciando download de AUDIO...
echo.

:: Log
echo [%date% %time%] AUDIO: !URL! >> "%LOG_FILE%"

:: Comando yt-dlp para audio apenas
"%YTDLP%" ^
    -f "bestaudio[ext=m4a]/bestaudio" ^
    --extract-audio ^
    --audio-format m4a ^
    --audio-quality 0 ^
    --newline ^
    --progress ^
    --console-title ^
    --no-overwrites ^
    --restrict-filenames ^
    -o "%OUTPUT_DIR%\%%(title)s.%%(ext)s" ^
    "!URL!"

if !errorlevel! neq 0 (
    echo [ERRO] Download falhou! Codigo: !errorlevel!
    echo [%date% %time%] ERRO: !URL! >> "%LOG_FILE%"
) else (
    echo [SUCESSO] Download concluido!
    echo [%date% %time%] SUCESSO: !URL! >> "%LOG_FILE%"
)

echo.
pause
exit /b

:DOWNLOAD_PLAYLIST
echo.
echo Iniciando download de PLAYLIST...
echo.

:: Log
echo [%date% %time%] PLAYLIST: !URL! >> "%LOG_FILE%"

:: Comando yt-dlp para playlist
"%YTDLP%" ^
    -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" ^
    --merge-output-format mp4 ^
    --yes-playlist ^
    --newline ^
    --progress ^
    --console-title ^
    --no-overwrites ^
    --restrict-filenames ^
    -o "%OUTPUT_DIR%\%%(playlist_title)s\%%(playlist_index)s - %%(title)s.%%(ext)s" ^
    "!URL!"

if !errorlevel! neq 0 (
    echo [ERRO] Download falhou! Codigo: !errorlevel!
    echo [%date% %time%] ERRO: !URL! >> "%LOG_FILE%"
) else (
    echo [SUCESSO] Download da playlist concluido!
    echo [%date% %time%] SUCESSO: !URL! >> "%LOG_FILE%"
)

echo.
pause
exit /b

:EXIT
cls
echo Obrigado por usar o yt-dlp Downloader!
echo.
timeout /t 2 >nul
exit /b 0
