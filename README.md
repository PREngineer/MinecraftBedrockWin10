# MinecraftBedrockWin10
Script to install and update Minecraft Bedrock Edition in Windows 10

# Notes:

**Pre-Requisites**

1. Make sure to have configured Internet Explorer if it is a new installation of Windows 10.
  Open it and when prompted, select "Don't use recommended settings."  Then click OK.
2. Make sure that the ExecutionPolicy is set to Bypass in PowerShell so that you can execute scripts.
  Open PowerShell as Admin.  Run the following command:  Set-ExecutionPolicy Bypass, then type A and Enter.
3. Make sure to install the latest Visual C++ Redistributable from Microsoft, as it is a requirement for Minecraft BE.

**How to Run**

1. Open PowerShell as Administrator
2. Call the PowerShell script and pass it your account credentials like this:

  ./path/to/script/bedrock.ps1 -Username <username> -Password <password>
  
There you go!  Enjoy your Minecraft Bedrock Edition server.
  
It will patch/update itself every day at 4am.
