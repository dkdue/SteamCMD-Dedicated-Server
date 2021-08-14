$Host.UI.RawUI.WindowTitle = "Actualizador SteamCMD Server Manager"
$Config = Get-Content "Config.config" | convertfrom-json
Write-Host "Actualizador del servidor " -ForegroundColor DarkGreen -BackgroundColor Black
write-host "-------------------------------"
Start-Sleep -Seconds 1.5


#Function Start-Server {
#    #Inicia el servidor
#    $Process = get-process $($config.gameserver) -ErrorAction SilentlyContinue
#    if ($Process){
#        write-host "El servidor se está ejecutando.."
#    }else {
#        write-host "Iniciando el servidor $($config.servername).. "
#        $env:SteamAppId="892970"
#        Start-Process "$($config.forceinstalldir)\$($config.gameserver).exe" -ArgumentList "-nographics -batchmode -name $($config.servername) -port $($config.port) -password $($config.password) -public 1"
#    }
#}

#Function Update-Server {
#    #Comienza a actualizar el servidor 
#    $Process = get-process $($config.gameserver) -ErrorAction SilentlyContinue
#   if ($Process){
#        write-host "Detiene primero el servidor del juego: Stop-Server"
#    }else {
#        Write-Host "Actualizando $($config.servername)"
#        Start-Process "$($config.steamcmd)" -ArgumentList "+login anonymous +force_install_dir $($config.forceinstalldir) +app_update $($config.gameid) validate +exit" -wait
#    }
#}

Function Stop-Server {
    #Envía Ctrl + C a la ventana del server, que guarda el servidor primero y se apaga limpiamente
    $Process = get-process MistServer -ErrorAction SilentlyContinue
    if ($Process){
        # asegúrese de configurar $ProcessID correctamente. El envío de la señal CTRL_C_EVENT puede interrumpir o terminar un proceso
        $ProcessID = $Process.Id
        $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("Add-Type -Names 'w' -Name 'k' -M '[DllImport(""kernel32.dll"")]public static extern bool FreeConsole();[DllImport(""kernel32.dll"")]public static extern bool AttachConsole(uint p);[DllImport(""kernel32.dll"")]public static extern bool SetConsoleCtrlHandler(uint h, bool a);[DllImport(""kernel32.dll"")]public static extern bool GenerateConsoleCtrlEvent(uint e, uint p);public static void SendCtrlC(uint p){FreeConsole();AttachConsole(p);GenerateConsoleCtrlEvent(0, 0);}';[w.k]::SendCtrlC($ProcessID)"))
        start-process powershell.exe -argument "-nologo -noprofile -executionpolicy bypass -EncodedCommand $encodedCommand"

    } else {
        write-host "ningun proceso encontrado, no termina nada"
    }
}
Start-Sleep -Seconds 60



Function Get-ServerCurrentVersion {
    ((Get-Content "$($config.forceinstalldir)\steamapps\appmanifest_$($config.gameid).acf" | Where-Object {$_ -like "*buildid*"}).split('"').trim() | Where-Object {$_})[-1]
}
Function Get-ServerLatestVersion {
    Write-Host "Comprobando la API de Steam para la ultima version..."
    $Data = Invoke-WebRequest -Uri "https://api.steamcmd.net/v1/info/$($config.gameid)" -UseBasicParsing
    $json = $data.content | convertfrom-json
    $BuildID = $json.data.$($config.gameid).depots.branches.$($config.branches).buildid
    $Status = $json.status
    
    if ($Status -eq 'success') {
    Write-Host "Estado: Exito!" -ForegroundColor DarkGreen
    } else {
    Write-Host "Error, no puedo contactar con los servicios de Steam. Intentando de nuevo mas tarde.." -ForegroundColor Red    
    }


Return $BuildID

Start-Sleep -Seconds 1.5

}
#Corre cada 900 segundos para siempre
$stop = "$false"
do{
    $BuildID = Get-ServerLatestVersion
    $CurrentBuildID = Get-ServerCurrentVersion
    
    if ($BuildID -ne $CurrentBuildID){
        #Nueva versión detectada. Iniciar parcheo
        Stop-Server
        #Update-Server
    } else {
        Write-host "El servidor tiene la ultima actualizacion: $($BuildID)"
       
    }
    #Esto iniciará el Server después de parchear, e incluso si no está parcheado pero se bloqueó por alguna razón
    #Start-Server
    #Se ejecutará cada 15 minutos (900 segundos)
	#Start-Sleep -Seconds 900
	
$x = 15*60
$length = $x / 100
while($x -gt 0) {
  $min = [int](([string]($x/60)).split('.')[0])
  $text = " " + $min + " minutos " + ($x % 60) + " segundos restantes"
  Write-Progress "El servidor tiene la ultima actualizacion: $($BuildID), Siguiente comprobacion..." -status $text -perc ($x/$length)
  start-sleep -s 1
  $x--
}

} while ($stop)
