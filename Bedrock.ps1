#######################################
#   Minecraft Bedrock Server Setup    #
#######################################
#   Script by: Jorge L. Pabon Cruz    #
#   https://www.github.com/PREngineer #
#######################################
# This script installs the latest     #
# Minecraft Bedrock Edition in a      #
# Windows 10 environment and sets it  #
# up according to your preferences.   #
#######################################

param (
    [Parameter(Mandatory=$true,
                HelpMessage="Username, This is your computer's account name")]
    [string]$Username,
    [Parameter(Mandatory=$true,
                HelpMessage="Password, This is your computer account's password")]
    [string]$Password
)

#region - Make sure that Firewall port is open

cls

Write-Host "Opening firewall ports, if necessary..." -ForegroundColor Cyan

$rule = Get-NetFirewallRule -DisplayName 'ALLOW Minecraft Ports using UDP' 2> $null;
if ( !$rule )
{ 
    Write-Host "[...] Opening UDP" -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "ALLOW Minecraft Ports using UDP" -Direction Inbound -Profile Any -Action Allow -LocalPort 19132,25565 -Protocol UDP
}
else
{
    Write-Host "[✔] UDP already open!" -ForegroundColor Green
}

$rule = Get-NetFirewallRule -DisplayName 'ALLOW Minecraft Ports using TCP' 2> $null;
if ( !$rule )
{ 
    Write-Host "[...] Opening TCP" -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "ALLOW Minecraft Ports using TCP" -Direction Inbound -Profile Any -Action Allow -LocalPort 25565,19132 -Protocol TCP
}
else
{
    Write-Host "[✔] TCP already open!" -ForegroundColor Green
}

#endregion

#region - Check if Installation Directory exists

Write-Host "Checking Installation Directory..." -ForegroundColor Cyan

# Specify where we will save the server files
$InstallDir = "C:\MCBedrock"

# Get inside that folder, create if doesn't exist
if( Test-Path $InstallDir )
{
    Write-Host "[✔] Folder already exists!" -ForegroundColor Green
    cd $InstallDir
}
else
{
    Write-Host "[...] Creating Installation folder $InstallDir..." -ForegroundColor Yellow
    mkdir $InstallDir
    cd $InstallDir
}

#endregion

#region - Identify latest version of the bedrock server

Write-Host "Identifying latest version from Microsoft..." -ForegroundColor Cyan

Write-Host "Making sure we connect securely..." -ForegroundColor Cyan

# Make sure we use TLS 1.2 when connecting (HTTPS)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "[...] Identifying download URL..." -ForegroundColor Yellow

# Identify the link of the latest version from Microsoft's download website
$result = Invoke-WebRequest -Uri https://www.minecraft.net/en-us/download/server/bedrock
$serverurl = $result.Links | select href | where {$_.href -like "https://minecraft.azureedge.net/bin-win/bedrock-server*"}
$url = $serverurl.href

Write-Host "[✔] I've identified the url of the latest Minecraft version to be: `n$url" -ForegroundColor Green

# Identify the compressed file's name
$filename = $url.Replace("https://minecraft.azureedge.net/bin-win/","")

Write-Host "[✔] The compressed file to download is: `n$filename" -ForegroundColor Green

# Establish the folder destination
$MCZip = "$InstallDir\$filename"

#endregion

#region - Update the server to the latest version

if( Test-Path $InstallDir )
{
    # For auditing purposes
    Start-Transcript -Path "C:\MCBedrock\Update_Log.txt"
    # Identify the backup folder date
    $Now = Get-Date -Format 'yyyy-MM-dd'
    
    # Stop the service before updating, or just for a refresh
    if( Get-Process -Name "bedrock_server" -ErrorAction Ignore )
    {
        Write-Host "[...] Stopping the Minecraft service..." -ForegroundColor Yellow

        Stop-Process -Name "bedrock_server"

        Write-Host "[✔] Minecraft Bedrock has been stopped." -ForegroundColor Green
    }
    else
    {
        Write-Host "[✔] Minecraft Bedrock is currently not running!" -ForegroundColor Yellow
    }

    # Do we need to update?

    Write-Host "Identifying currently installed version from previous run..." -ForegroundColor Cyan

    if( Test-Path "C:\MCBedrock\version.txt" )
    {
        $CurrentVersion = Get-Content "C:\MCBedrock\version.txt" -Raw
    }
    else
    {
        $CurrentVersion = "0.0.0"
    }
    
    # Yes
    if( $CurrentVersion.Replace("`r`n","") -ne $filename )
    {
        Write-Host "[!] We need to update the server from "$CurrentVersion.Replace(".zip`r`n","")" to "$filename.Replace(".zip","") -ForegroundColor Yellow
    }
    # No
    else
    {
        Write-Host "[✔] There's nothing to update!" -ForegroundColor Green
        
        Write-Host "[✔] Restarting the server..." -ForegroundColor Green
        if( !(Get-Process -Name "bedrock_server" -ErrorAction Ignore) )
        {
            Start-Process -FilePath bedrock_server.exe
        }

        Write-Host "[✔] Exiting..." -ForegroundColor Cyan
        Exit
    }

    # Backup the server configuration as we need to restore it later
    Write-Host "[...] Backing up configuration files..." -ForegroundColor Yellow

    if( !(Test-Path "C:\MCBedrock\backups") )
    {
        mkdir backups
    }

    if( !(Test-Path "C:\MCBedrock\backups\$Now") )
    {
        mkdir .\backups\$Now
    }

    Copy-Item -Path "server.properties" -Force -Destination ".\backups\$now\"
    Copy-Item -Path "whitelist.json" -Force -Destination ".\backups\$now\"
    Copy-Item -Path "permissions.json" -Force -Destination ".\backups\$now\"
    Copy-Item -Path "worlds" -Recurse -Force -Destination ".\backups\$now\"


    # Download the latest version
    Write-Host "[...] Downloading the latest Minecraft version..." -ForegroundColor Yellow
    
    Invoke-WebRequest -Uri $url -OutFile $MCZip

    Write-Host "[...] Updating to latest version..." -ForegroundColor Yellow
    
    Expand-Archive -LiteralPath $MCZip -DestinationPath C:\MCBedrock -Force
    rm $MCZip
    
    Write-Host "[...] Restoring configuration files..." -ForegroundColor Yellow

    # Restore configuration
    Copy-Item -Path ".\backups\$now\server.properties" -Force -Destination .\
    Copy-Item -Path ".\backups\$now\whitelist.json" -Force -Destination .\
    Copy-Item -Path ".\backups\$now\permissions.json" -Force -Destination .\
    Copy-Item -Path ".\backups\$now\worlds" -Recurse -Force -Destination .\
}

#endregion

#region - Install the latest server version

else
{
    Start-Transcript -Path "Install_Log.txt"
    
    # Install the server
    Write-Host "[...] Downloading the latest version..." -ForegroundColor Yellow
    
    Invoke-WebRequest -Uri $url -OutFile $MCZip

    Write-Host "[...] Installing the latest version..." -ForegroundColor Yellow

    Expand-Archive -LiteralPath $MCZip -DestinationPath C:\MCBedrock -Force
    rm $MCZip

    Write-Host "[...] Adding server to auto start folder..." -ForegroundColor Yellow

    # Auto start the service on boot
    $Shell = New-Object -comObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut("$HOME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Minecraft.lnk")
    $Shortcut.TargetPath = "C:\MCBedrock\bedrock_server.exe"
    $Shortcut.Save()

    # Copy this script to the installation folder
    Write-Host "Copying this script to Minecraft Installation Directory: $InstallDir" -ForegroundColor Cyan

    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $InstallDir
    $Time = New-ScheduledTaskTrigger -At 4:00AM -Daily -DaysInterval 1
    $Action = New-ScheduledTaskAction -Execute PowerShell.exe -WorkingDirectory $InstallDir -Argument “$InstallDir\Bedrock.ps1 -UserName $Username -Password $Password”
    
    Write-Host "[...] Registering Maintenance Scheduled Task..." -ForegroundColor Yellow

    # Registering the daily scheduled task
    Register-ScheduledTask -TaskName "Minecraft\Maintenance" -Trigger $Time -Action $Action -RunLevel Highest
}

#endregion

#region - Start the service

if( !(Get-Process -Name "bedrock_server" -ErrorAction Ignore) )
{
    Write-Host "[...] Starting the server..." -ForegroundColor Yellow
    Start-Process -FilePath bedrock_server.exe
}

#endregion

#region - Make sure we know the version we updated to

Write-Host "Storing version for future reference..." -ForegroundColor Cyan

Set-Content -Path "version.txt" $filename

Write-Host "[✔] We are done!" -ForegroundColor Green

#endregion

Stop-Transcript
