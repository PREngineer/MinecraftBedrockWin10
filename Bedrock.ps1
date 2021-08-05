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

cls

#region - Make sure that Firewall port is open

Write-Host "Opening firewall ports..." -ForegroundColor Cyan
$rule = Get-NetFirewallRule -DisplayName 'ALLOW Minecraft Ports using UDP' 2> $null;
if ( !$rule )
{ 
    Write-Host "Opening UDP" -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "ALLOW Minecraft Ports using UDP" -Direction Inbound -Profile Any -Action Allow -LocalPort 19132,25565 -Protocol UDP
}

$rule = Get-NetFirewallRule -DisplayName 'ALLOW Minecraft Ports using TCP' 2> $null;
if ( !$rule )
{ 
    Write-Host "Opening TCP" -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "ALLOW Minecraft Ports using TCP" -Direction Inbound -Profile Any -Action Allow -LocalPort 25565,19132 -Protocol TCP
}

#endregion

#region - Check if Installation Directory exists

# Specify where we will save the server files
$InstallDir = "C:\MCBedrock"

# Get inside that folder, create if doesn't exist
if( Test-Path $InstallDir )
{
    cd $InstallDir
}
else
{
    Write-Host "Creating Installation folder $InstallDir..." -ForegroundColor Cyan
    mkdir $InstallDir
    cd $InstallDir
}

#endregion

#region - Identify latest version of the bedrock server

# Make sure we use TLS 1.2 when connecting (HTTPS)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Identify the link of the latest version from Microsoft's download website
$result = Invoke-WebRequest -Uri https://www.minecraft.net/en-us/download/server/bedrock
$serverurl = $result.Links | select href | where {$_.href -like "https://minecraft.azureedge.net/bin-win/bedrock-server*"}
$url = $serverurl.href
Write-Host "We've identified the url of the latest version of Minecraft to be: `n$url" -ForegroundColor Cyan

# Identify the compressed file's name
$filename = $url.Replace("https://minecraft.azureedge.net/bin-win/","")
Write-Host "The compressed file to download is: `n$filename" -ForegroundColor Cyan

# Establish the folder destination
$destination = "$InstallDir\$filename"

#endregion

#region - Update the server to the latest version

if( Test-Path $InstallDir )
{
    Start-Transcript -Path "Update_Log.txt"
    $Now = Get-Date -Format 'yyyy-MM-dd'
    
    # Stop the service before updating, or just for a refresh
    if( Get-Process -Name "bedrock_server" )
    {
        Write-Host "Stopping the Minecraft service..." -ForegroundColor Cyan
        Stop-Process -Name "bedrock_server"
    }

    # Do we need to update?

    $CurrentVersion = Get-Content "version.txt" -Raw
    
    # Yes
    if( $CurrentVersion.Replace("`r`n","") -ne $filename )
    {
        Write-Host "We need to update the server from "$CurrentVersion.Replace(".zip`r`n","")" to "$filename.Replace(".zip","") -ForegroundColor Yellow
    }
    # No
    else
    {
        Write-Host "There's nothing to update!" -ForegroundColor Green
        
        Write-Host "Restarting the server..." -ForegroundColor Green
        if( !(Get-Process -Name bedrock_server) )
        {
            Start-Process -FilePath bedrock_server.exe
        }

        Write-Host "Exiting..." -ForegroundColor Cyan
        Exit
    }

    # Backup the server configuration as we need to restore it later
    Write-Host "Backing up configuration files..." -ForegroundColor Cyan
    if( !(Test-Path "backups") )
    {
        mkdir backups
    }
    mkdir .\backups\$Now
    Copy-Item -Path "server.properties" -Destination ".\backups\$now\"
    Copy-Item -Path "whitelist.json" -Destination ".\backups\$now\"
    Copy-Item -Path "permissions.json" -Destination ".\backups\$now\"
    Copy-Item -Path "worlds" -Recurse -Destination ".\backups\$now\"


    # Download the latest version
    Write-Host "Downloading the latest Minecraft version..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $destination
    Write-Host "Updating to latest version..." -ForegroundColor Cyan
    Expand-Archive -LiteralPath $destination -DestinationPath C:\MCBedrock -Force
    rm $destination
    
    # Restore configuration
    Copy-Item -Path ".\backups\$now\server.properties" -Destination .\
    Copy-Item -Path ".\backups\$now\whitelist.json" -Destination .\
    Copy-Item -Path ".\backups\$now\permissions.json" -Destination .\
    Copy-Item -Path ".\backups\$now\worlds" -Recurse -Destination .\
}

#endregion

#region - Install the latest server version

else
{
    Start-Transcript -Path "Install_Log.txt"
    
    # Install the server
    Write-Host "Downloading the latest version..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $destination

    Write-Host "Installing the latest version..." -ForegroundColor Cyan
    Expand-Archive -LiteralPath $destination -DestinationPath C:\MCBedrock -Force
    rm $destination

    # Auto start the service on boot
    $Shell = New-Object -comObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut("$HOME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Minecraft.lnk")
    $Shortcut.TargetPath = "bedrock_server.exe"
    $Shortcut.Save()

    # Copy this script to the installation folder
    Write-Host "Copying this script to Minecraft Installation Directory: $InstallDir" -ForegroundColor Cyan
    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $InstallDir
    $Time = New-ScheduledTaskTrigger -At 4:00AM -Daily -DaysInterval 1
    $Action = New-ScheduledTaskAction -Execute PowerShell.exe -WorkingDirectory $InstallDir -Argument “$InstallDir\Bedrock.ps1 -UserName $Username -Password $Password”
    # Registering the daily scheduled task
    Register-ScheduledTask -TaskName "Minecraft\Maintenance" -Trigger $Time -Action $Action -RunLevel Highest
}

#endregion

#region - Start the service

if( !(Get-Process -Name bedrock_server) )
{
    Start-Process -FilePath bedrock_server.exe
}

#endregion

#region - Make sure we know the version we updated to

Set-Content -Path "version.txt" $filename

#endregion

Stop-Transcript
