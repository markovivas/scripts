@echo off
setlocal enabledelayedexpansion

:: ==================================================
:: INSTALADOR DE PROGRAMAS - CHOCOLATEY
:: ==================================================
::
:: 💡 COMO INSTALAR O CHOCOLATEY (caso ainda não tenha instalado):
::
:: 1. Abra o PowerShell como **Administrador**.
:: 2. Execute o comando abaixo:
::
:: Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
::
:: 3. Aguarde a instalação terminar.
:: 4. Feche e abra novamente o Prompt de Comando ou PowerShell.
:: 5. Execute este script (.bat) normalmente.
::
:: ==================================================
echo.
echo ==================================================
echo INSTALADOR DE PROGRAMAS - CHOCOLATEY
echo ==================================================
echo.
echo.

:: ================== FERRAMENTAS DE SISTEMA E DIAGNOSTICO ==================
choco install 7zip -y
choco install crystaldiskinfo -y
choco install cpu-z.install -y
choco install directx -y
choco install dotnet -y
choco install everything -y
choco install hwinfo -y
choco install openal -y
choco install powershell -y
choco install powertoys -y
choco install fontbase -y
choco install sagethumbs -y
choco install vcredist-all -y
choco install xcp-ng-center -y

:: ================== DESENVOLVIMENTO E PROGRAMADORES ==================
choco install composer -y
choco install dbeaver -y
choco install git -y
choco install github-desktop -y
choco install nodejs.install -y
choco install notepadplusplus.install -y
choco install putty -y
choco install python -y
choco install vscode -y
choco install microsoft-windows-terminal -y

:: ================== MULTIMIDIA, AUDIO E VIDEO ==================
choco install handbrake -y
choco install obs-studio.install -y
choco install obs-move-transition -y
choco install droidcam-obs-plugin -y
choco install vlc -y

:: ================== INTERNET E REDES ==================
choco install firefox -y
choco install openssh -y
choco install qbittorrent -y
choco install whatsapp -y
choco install winscp.install -y
choco install xampp-81 -y

:: ================== SEGURANCA E PRIVACIDADE ==================
choco install keepass.install -y

:: ================== PRODUTIVIDADE E ESCRITORIO ==================
choco install onlyoffice -y
choco install thunderbird -y

:: ================== UTILITARIOS DIVERSOS ==================
choco install imageresizerapp -y
choco install gcompris -y
choco install haroopad -y
choco install itunes -y
choco install ffmpeg-full -y
choco install yt-dlp --pre -y

:: ================== GAMES ==================
:: choco install steam -y
:: choco install epicgameslauncher -y
choco install valorant -y

echo.
echo ==================================================
echo INSTALACAO CONCLUIDA!
echo ==================================================
echo TUDO PRONTO: Reinicie o computador para aplicar as configuracoes.
echo ==================================================
pause
