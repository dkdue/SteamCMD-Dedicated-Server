:: ****** STEAMCMD DEDICATED SERVER *****
:: ****** FOR ALL STEAM SERVERS *********
:: ****** BY KESSEF *********************
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Config_SteamCMD
set appid=412680 -beta evrima
set login=anonymous
set steamcmd_path=C:\Servers\TheIsle\SteamCMD\steamcmd.exe
set steamcmd_dir=C:\Servers\TheIsle\SteamCMD
set install_server=C:\Servers\TheIsle
set server_exe=TheIsleServer.exe
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:IP
::IPv4 IP Localhost
for /f "delims=[] tokens=2" %%a in ('ping -4 -n 1 %ComputerName% ^| findstr [') do set NetworkIP=%%a
echo Network IP: %NetworkIP%

::IP External
::for /f %%a in ('powershell Invoke-RestMethod api.ipify.org') do set PublicIP=%%a
::echo Public IP: %PublicIP%  

:Starting_Server
@echo off
cls
title ..::SteamCMD Dedicated Server::..IPV4:%NetworkIP% ..::WATCHDOG::....::by Kessef::..

echo "       :::    :::       ::::::::::       ::::::::       ::::::::       ::::::::::       :::::::::: ";
echo "      :+:   :+:        :+:             :+:    :+:     :+:    :+:      :+:              :+: ";
echo "     +:+  +:+         +:+             +:+            +:+             +:+              +:+ ";
echo "    +#++:++          +#++:++#        +#++:++#++     +#++:++#++      +#++:++#         :#::+::# ";
echo "   +#+  +#+         +#+                    +#+            +#+      +#+              +#+ ";
echo "  #+#   #+#        #+#             #+#    #+#     #+#    #+#      #+#              #+# ";
echo " ###    ###       ##########       ########       ########       ##########       ### ";

echo (%time%) Protegiendo el Servidor de los Crasheos...

:Carpetas
echo (%time%) Comprobando Carpeta de SteamCMD...
setlocal EnableExtensions DisableDelayedExpansion

md "%steamcmd_dir%" 2>nul
if not exist "%steamcmd_dir%\*" (
    echo  ALERTA!!!!!!! No se pudo crear el directorio "%steamcmd_dir%"
    pause
    goto :SteamCMD_Existe
)

:SteamCMD_Existe
echo (%time%) Comprobando si SteamCMD esta Instalado...
if exist %steamcmd_path% echo (%time%) SteamCMD Instalado... && goto Updater
if not exist %steamcmd_path% goto SteamCMD_Auto


:SteamCMD_Auto
echo (%time%) Descargando SteamCMD...
powershell.exe -Command $ErrorActionPreference= 'silentlycontinue'; "Invoke-WebRequest https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip -OutFile %steamcmd_dir%\steamcmd.zip"

echo (%time%) Instalando SteamCMD...
powershell.exe -command $ErrorActionPreference= 'silentlycontinue'; "Expand-Archive -Force '%steamcmd_dir%\steamcmd.zip' '%steamcmd_dir%\'"


:Updater
echo (%time%) Iniciando Actualizador...
start powershell.exe -file Updater.ps1
goto Initial_Server


:Initial_Server
echo (%time%) Comprobando Actualizaciones del Servidor...
start /wait %steamcmd_path% +login %login% +force_install_dir %install_server% +app_update %appid% +quit

echo (%time%) Servidor Iniciado...
start /wait %install_server%\%server_exe% MultiHome=%NetworkIP%?Port=7777?QueryPort=7778 -nosteamclient -game -server -log | set /P "="


:Crash_Server
echo (%time%) PELIGRO!: El Servidor ha cerrado por Actualizacion o ha crasheado, Reiniciando en 10 Segundos.
timeout /t 10
goto Initial_Server







