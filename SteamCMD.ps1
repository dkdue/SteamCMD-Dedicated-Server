$Config = Get-Content ".\server.config" | convertfrom-json
$host.UI.RawUI.WindowTitle = "SteamCMD Dedicated Server ..:: $($config.servername) ::.."
$ErrorActionPreference= 'silentlycontinue'
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
write-host "Installing or Updating WriteAscii module...."
Install-Module -Name WriteAscii -Scope CurrentUser
write-host "Starting WriteAscii module...."
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
powershell.exe /wait "$Dir\SteamCMD\steamcmd.exe" +login anonymous +force_install_dir $($config.forceinstalldir) +app_update $($config.gameid) $($config.branches) validate +exit 
}
########################################################################################################################################################

Function Start-Server {
    #Starts the Server
    $Process = get-process $($config.PIDname) -ErrorAction SilentlyContinue
    if ($Process){
        write-host "Server is running..."
    }else {
		
        write-host "Starting the server $($config.servername)... "
		#Discord Alert
		$webHookUrl = "$($config.webHookUrl)"
		[System.Collections.ArrayList]$embedArray = @()
		$color = '4289797'
		$title = 'Server Status!'
		$description = '@everyone Starting the server, Wait a few minutes until the server is completely online.'
		$embedObject = [PSCustomObject]@{
			color = $color
			title = $title
			description = $description
		}
		$embedArray.Add($embedObject)
		$payload = [PSCustomObject]@{
		embeds = $embedArray
		}
		Invoke-RestMethod -Uri $webHookUrl -Body ($payload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'application/json'
		#Discord Alert
		Start-Process "$($config.forceinstalldir)\$($config.Win64)\$($config.ExeName)" -ArgumentList "$($config.ArgumentList)"
		
		
    }
}
	

Function Update-Server {
    #Starts updating the Server
    $Process = get-process $($config.PIDname) -ErrorAction SilentlyContinue
    if ($Process){
        write-host "Stop the game server first: Stop-Server"
    }else {
        Write-Host "Updating $($config.servername)"
		#Discord Alert
		$webHookUrl = "$($config.webHookUrl)"
		[System.Collections.ArrayList]$embedArray = @()
		$color = '1065911'
		$title = 'Server Status!'
		$description = '@everyone Updating the server.'
		$embedObject = [PSCustomObject]@{
			color = $color
			title = $title
			description = $description
		}
		$embedArray.Add($embedObject)
		$payload = [PSCustomObject]@{
		embeds = $embedArray
		}
		Invoke-RestMethod -Uri $webHookUrl -Body ($payload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'application/json'
		#Discord Alert		
        Start-Process "$($config.steamcmd)" "+login anonymous +force_install_dir $($config.forceinstalldir) +app_update $($config.gameid) $($config.branches) validate +exit" -wait
    }
}

Function Stop-Server {
    #Sends Ctrl+C to the Server window, which saves the server first and shuts down cleanly
    $Process = get-process $($config.PIDname) -ErrorAction SilentlyContinue
    if ($Process){
        # be sure to set $ProcessID properly. Sending CTRL_C_EVENT signal can disrupt or terminate a process
        $ProcessID = $Process.Id
        $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("Add-Type -Names 'w' -Name 'k' -M '[DllImport(""kernel32.dll"")]public static extern bool FreeConsole();[DllImport(""kernel32.dll"")]public static extern bool AttachConsole(uint p);[DllImport(""kernel32.dll"")]public static extern bool SetConsoleCtrlHandler(uint h, bool a);[DllImport(""kernel32.dll"")]public static extern bool GenerateConsoleCtrlEvent(uint e, uint p);public static void SendCtrlC(uint p){FreeConsole();AttachConsole(p);GenerateConsoleCtrlEvent(0, 0);}';[w.k]::SendCtrlC($ProcessID)"))
        start-process powershell.exe -argument "-nologo -noprofile -executionpolicy bypass -EncodedCommand $encodedCommand"
        write-host "Waiting for Process $($ProcessID) to stop"
		#Discord Alert
		$webHookUrl = "$($config.webHookUrl)"
		[System.Collections.ArrayList]$embedArray = @()
		$color = '12534533'
		$title = 'Server Status!'
		$description = '@everyone Stoping the server.'
		$embedObject = [PSCustomObject]@{
			color = $color
			title = $title
			description = $description
		}
		$embedArray.Add($embedObject)
		$payload = [PSCustomObject]@{
		embeds = $embedArray
		}
		Invoke-RestMethod -Uri $webHookUrl -Body ($payload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'application/json'
		#Discord Alert			
        Wait-Process -id $ProcessID		

	} else {
        write-host "No process found, not terminating anything"
    }
}

Function Get-ServerCurrentVersion {
    ((Get-Content "$($config.forceinstalldir)\steamapps\appmanifest_$($config.gameid).acf" | Where-Object {$_ -like "*buildid*"}).split('"').trim() | Where-Object {$_})[-1]
}
Function Get-ServerLatestVersion {
    Write-Host "Checking Steam API for latest version..."
    $Data = Invoke-WebRequest -Uri "https://api.steamcmd.net/v1/info/$($config.gameid)" -UseBasicParsing 
    $json = $data.content | convertfrom-json
    $BuildID = $json.data.$($config.gameid).depots.branches.$($config.branches).buildid
    $Status = $json.status
    
    if ($Status -eq 'success') {
    Write-Host "Status: Success!" -ForegroundColor DarkGreen
    } else {
    Write-Host "Error, unable to contact the Steam services. Trying again later..." -ForegroundColor Red    
    }


Return $BuildID

Start-Sleep -Seconds 1.5

}
#Run every 300 seconds forever
$stop = "$false"
do{
    $BuildID = Get-ServerLatestVersion
    $CurrentBuildID = Get-ServerCurrentVersion
    
    if ( ($BuildID -ne $CurrentBuildID) -and ($BuildID -ne "NotAvailable") ) {
        #New version detected. Initiating patching
        write-host "New version found. Stopping in 10 min and updating $($config.servername)..."
		#Discord Alert
		$webHookUrl = "$($config.webHookUrl)"
		[System.Collections.ArrayList]$embedArray = @()
		$color = '16768083'
		$title = 'Server Status!'
		$description = '@everyone New version found. Stopping in 10 min and updating...'
		$embedObject = [PSCustomObject]@{
			color = $color
			title = $title
			description = $description
		}
		$embedArray.Add($embedObject)
		$payload = [PSCustomObject]@{
		embeds = $embedArray
		}
		Invoke-RestMethod -Uri $webHookUrl -Body ($payload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'application/json'
		#Discord Alert
		timeout /t 600
		
		write-host "New version found. Stopping in 5 min and updating $($config.servername)..."
		#Discord Alert
		$webHookUrl = "$($config.webHookUrl)"
		[System.Collections.ArrayList]$embedArray = @()
		$color = '16768083'
		$title = 'Server Status!'
		$description = '@everyone New version found. Stopping in 5 min and updating...'
		$embedObject = [PSCustomObject]@{
			color = $color
			title = $title
			description = $description
		}
		$embedArray.Add($embedObject)
		$payload = [PSCustomObject]@{
		embeds = $embedArray
		}
		Invoke-RestMethod -Uri $webHookUrl -Body ($payload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'application/json'
		#Discord Alert		
		timeout /t 240
		
		write-host "New version found. Stopping in 1 min and updating $($config.servername)..."
		#Discord Alert
		$webHookUrl = "$($config.webHookUrl)"
		[System.Collections.ArrayList]$embedArray = @()
		$color = '16768083'
		$title = 'Server Status!'
		$description = '@everyone New version found. Stopping in 1 min and updating...'
		$embedObject = [PSCustomObject]@{
			color = $color
			title = $title
			description = $description
		}
		$embedArray.Add($embedObject)
		$payload = [PSCustomObject]@{
		embeds = $embedArray
		}
		Invoke-RestMethod -Uri $webHookUrl -Body ($payload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'application/json'
		#Discord Alert		
		timeout /t 60
		
		write-host "New version found. Stopping and updating $($config.servername) now..."
		#Discord Alert
		$webHookUrl = "$($config.webHookUrl)"
		[System.Collections.ArrayList]$embedArray = @()
		$color = '16768083'
		$title = 'Server Status!'
		$description = '@everyone New version found. Stopping and updating now...'
		$embedObject = [PSCustomObject]@{
			color = $color
			title = $title
			description = $description
		}
		$embedArray.Add($embedObject)
		$payload = [PSCustomObject]@{
		embeds = $embedArray
		}
		Invoke-RestMethod -Uri $webHookUrl -Body ($payload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'application/json'
		#Discord Alert		
		
        Stop-Server
        Update-Server
    } else {
        Write-host "The server has the latest update: $($BuildID)"
       
    }
    #This will start Server after patching, and even if it's not patched but crashed for some reason
    Start-Server
    #Will run every 5 minutes (300 seconds)
    #Start-Sleep -Seconds 300
	
$x = 5*60
$length = $x / 100
while($x -gt 0) {
  $min = [int](([string]($x/60)).split('.')[0])
  $text = " " + $min + " minutes " + ($x % 60) + " seconds remaining"
  Write-Progress "The server has the latest update: $($BuildID), Next check ..." -status $text -perc ($x/$length)
  start-sleep -s 1
  $x--
}


} while ($stop)
