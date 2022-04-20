$Config = Get-Content ".\server.config" | convertfrom-json
$host.UI.RawUI.WindowTitle = "SteamCMD Dedicated Server ..:: $($config.servername) ::.."
Start-Sleep -Seconds 1.5
######### - Space reserved so as not to collapse the counter with the title of the server
write-host
write-host
write-host
write-host
write-host
write-host
write-host
write-host
########## - Space reserved so as not to collapse the counter with the title of the server
powershell.exe Install-Module -Name WriteAscii -Scope CurrentUser
Write-Ascii -InputObject "$($config.Title)" -Fore Cyan          
########################################################################################################################################################
if (-not (Test-Path ".\SteamCMD")) {
#Creating Server Folder
write-host "Creating Server Folder"
$Dir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
New-item $Dir -type Directory -ErrorAction SilentlyContinue

#Creating Steam Folder and Downloading SteamCMD
Write-Host "Downloading SteamCMD"
$url = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
New-item "$Dir\SteamCMD" -type Directory -ErrorAction SilentlyContinue
$output =  "$Dir\SteamCMD\steamcmd.zip"
$start_time = Get-Date
Invoke-WebRequest -Uri $url -OutFile $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

#Expanding SteamCMD.zip (Open the zip file and extract)
$SteamZip = "$Dir\SteamCMD\steamcmd.zip" #the file name to extract
$SteamDestination = "$Dir\SteamCMD" #the path to extract the file to
Remove-Item $Dir\SteamCMD\steamcmd.exe -ErrorAction SilentlyContinue #Just in cases this was alredy run once, I don´t want to flood the uers text
Add-Type -assembly "system.io.compression.filesystem" #Required class to unzip the file
[io.compression.zipfile]::ExtractToDirectory($SteamZip, $SteamDestination) #unzip the file

Write-Host "The Server is going to be installed to $Dir" -ForegroundColor Yellow
Write-Host "Giving you 5 seconds to change your mind" -ForegroundColor Yellow
sleep -Seconds 5

#Installing the Server
Write-Host "Installing The Server. This will take a WHILE..." -ForegroundColor Yellow
powershell.exe "$Dir\SteamCMD\steamcmd.exe" +login anonymous +force_install_dir $($config.forceinstalldir) +app_update $($config.gameid) validate +exit 
}
########################################################################################################################################################

Function Start-Server {
    #Starts the Server Server
    $Process = get-process $($config.PIDname) -ErrorAction SilentlyContinue
    if ($Process){
        write-host "Server is running.."
    }else {
		
        write-host "Starting the server $($config.servername).. "
		Start-Process "$($config.forceinstalldir)\$($config.ExeName)" -ArgumentList "$($config.ArgumentList)" 
    }
}

Function Update-Server {
    #Starts updating the Server Server
    $Process = get-process $($config.PIDname) -ErrorAction SilentlyContinue
    if ($Process){
        write-host "Stop the game server first: Stop-Server"
    }else {
        Write-Host "Updating $($config.servername)"
        Start-Process "$($config.steamcmd)" -ArgumentList "+login anonymous +force_install_dir $($config.forceinstalldir) +app_update $($config.gameid) validate +exit" -wait
		
    }
}

Function Stop-Server {
    #Sends Ctrl+C to the Server window, which saves the server first and shuts down cleanly
    $Process = get-process $($config.PIDname) -ErrorAction SilentlyContinue
    if ($Process){
        $MemberDefinition = '
        [DllImport("kernel32.dll")]public static extern bool FreeConsole();
        [DllImport("kernel32.dll")]public static extern bool AttachConsole(uint p);
        [DllImport("kernel32.dll")]public static extern bool GenerateConsoleCtrlEvent(uint e, uint p);
        public static void SendCtrlC(uint p) {
            FreeConsole();
            AttachConsole(p);
            GenerateConsoleCtrlEvent(0, p);
            FreeConsole();
            AttachConsole(uint.MaxValue);
        }'
        Add-Type -Name 'dummyName' -Namespace 'dummyNamespace' -MemberDefinition $MemberDefinition
        [dummyNamespace.dummyName]::SendCtrlC($Process.ID)
    } else {
        write-host "no process found, not terminating anything"
    }
}

Function Get-ServerCurrentVersion {
    ((Get-Content "$($config.forceinstalldir)\steamapps\appmanifest_$($config.gameid).acf" | Where-Object {$_ -like "*buildid*"}).split('"').trim() | Where-Object {$_})[-1]
}
Function Get-ServerLatestVersion {
    Write-Host "Checking Steam API for latest version..."
    $Data = Invoke-WebRequest -Uri "https://api.steamcmd.net/v1/info/$($config.gameid)" -UseBasicParsing
    $json = $data.content | convertfrom-json
    $BuildID = $json.data.$($config.gameid).depots.branches.public.buildid
    $Status = $json.status
    
    if ($Status -eq 'success') {
    Write-Host "Status: Success!" -ForegroundColor DarkGreen
    } else {
    Write-Host "Error, unable to contact the Steam services. Trying again later.." -ForegroundColor Red    
    }


Return $BuildID

Start-Sleep -Seconds 1.5

}
#Run every 300 seconds forever
$stop = "$false"
do{
    $BuildID = Get-ServerLatestVersion
    $CurrentBuildID = Get-ServerCurrentVersion
    
    if ($BuildID -ne $CurrentBuildID){
        #New version detected. Initiating patching
        Stop-Server
        Update-Server
    } else {
        Write-host "The server has the latest update: $($BuildID)"
       
    }
    #This will start Server after patching, and even if it's not patched but crashed for some reason
    Start-Server
    #Will run every 5 minutes (300 seconds)
    #Start-Sleep -Seconds 900
	
$x = 15*60
$length = $x / 100
while($x -gt 0) {
  $min = [int](([string]($x/60)).split('.')[0])
  $text = " " + $min + " minutes " + ($x % 60) + " seconds remaining"
  Write-Progress "The server has the latest update: $($BuildID), Next check ..." -status $text -perc ($x/$length)
  start-sleep -s 1
  $x--
}

} while ($stop)

