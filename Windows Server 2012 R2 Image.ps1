# This powershell script was used to Create the Windows Server 2016 Image for mixp04 and mixp05.
# Only thing done manually was installing Xen-tools and the sysprep command at the very bottom of this script

#Variables
$bgInfoFolder = "C:\BgInfo"
$bgInfoFolderContent = $bgInfoFolder + "\*"
$itemType = "Directory"
$bgInfoUrl = "https://download.sysinternals.com/files/BGInfo.zip"
$logonBgiUrl = "https://tinyurl.com/yxlxbgun"
$bgInfoZip = "C:\BgInfo\BgInfo.zip"
$bgInfoEula = "C:\BgInfo\Eula.txt"
$logonBgiZip = "C:\BgInfo\LogonBgi.zip"
$bgInfoRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$bgInfoRegkey = "BgInfo"
$bgInfoRegType = "String"
$bgInfoRegkeyValue = "C:\BgInfo\Bginfo.exe C:\BgInfo\logon.bgi /timer:0 /nolicprompt"
$regKeyExists = (Get-Item $bgInfoRegPath -EA Ignore).Property -contains $bgInfoRegkey
$writeEmptyLine = "`n"
$writeSeperator = " - "
$time = Get-Date
$foregroundColor1 = "Yellow"
$foregroundColor2 = "Red"

#Enable Remote connections
Write-Host ($writeEmptyLine + "# Enable Remote Desktop connections" + $writeSeperator + $time)`
Invoke-Command –ScriptBlock {Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" –Value 0}
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

#IPv4 Allow incoming ICMP traffic (Allow Pings)
Write-Host ($writeEmptyLine + "# Allow Ping traffic through host firewall" + $writeSeperator + $time)`
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow

# Activate Windows Server 2012 R2 **** waiting for license****
#Write-Host ($writeEmptyLine + "# Activating Windows" + $writeSeperator + $time)`
#cscript C:\Windows\System32\slmgr.vbs -upk
#Start-Sleep -Seconds 5
#cscript C:\Windows\System32\slmgr.vbs /ipk ##################
#Start-Sleep -Seconds 5
#cscript C:\Windows\System32\slmgr.vbs /ato

# Set Time-zone to EST - Didnt work
#Write-Host ($writeEmptyLine + "# Setting timezone to EST" + $writeSeperator + $time)`
#Set-TimeZone "Eastern Standard Time"

################################################################################################################################
# didnt work :( (windows updates)
###################################################################################################################################
# Install BGPinfo
#-----------------------------------------------
## Write Download started
 
Write-Host ($writeEmptyLine + "# BgInfo download started" + $writeSeperator + $time)`
-foregroundcolor $foregroundColor1 $writeEmptyLine
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Create BgInfo folder on C: if not exists
 
If (!(Test-Path -Path $bgInfoFolder)){New-Item -ItemType $itemType -Force -Path $bgInfoFolder
    Write-Host ($writeEmptyLine + "# BgInfo folder created" + $writeSeperator + $time)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
 }Else{Write-Host ($writeEmptyLine + "# BgInfo folder already exists" + $writeSeperator + $time)`
    -foregroundcolor $foregroundColor2 $writeEmptyLine
    Remove-Item $bgInfoFolderContent -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host ($writeEmptyLine + "# Content existing BgInfo folder deleted" + $writeSeperator + $time)`
    -foregroundcolor $foregroundColor2 $writeEmptyLine}
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Download, save and extract latest BgInfo software to C:\BgInfo
 
Import-Module BitsTransfer
Start-BitsTransfer -Source $bgInfoUrl -Destination $bgInfoZip
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
[System.IO.Compression.ZipFile]::ExtractToDirectory($bgInfoZip, $bgInfoFolder)
Remove-Item $bgInfoZip
Remove-Item $bgInfoEula
Write-Host ($writeEmptyLine + "# bginfo.exe available" + $writeSeperator + $time)`
-foregroundcolor $foregroundColor1 $writeEmptyLine
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Download, save and extract logon.bgi file to C:\BgInfo
 
Invoke-WebRequest -Uri $logonBgiUrl -OutFile $logonBgiZip
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
[System.IO.Compression.ZipFile]::ExtractToDirectory($logonBgiZip, $bgInfoFolder)
Remove-Item $logonBgiZip
Write-Host ($writeEmptyLine + "# logon.bgi available" + $writeSeperator + $time)`
-foregroundcolor $foregroundColor1 $writeEmptyLine
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Create BgInfo Registry Key to AutoStart
 
If ($regKeyExists -eq $True){Write-Host ($writeEmptyLine + "BgInfo regkey exists, script wil go on" + $writeSeperator + $time)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
}Else{
New-ItemProperty -Path $bgInfoRegPath -Name $bgInfoRegkey -PropertyType $bgInfoRegType -Value $bgInfoRegkeyValue
Write-Host ($writeEmptyLine + "# BgInfo regkey added" + $writeSeperator + $time)`
-foregroundcolor $foregroundColor1 $writeEmptyLine}
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Run BgInfo
 
C:\BgInfo\Bginfo.exe C:\BgInfo\logon.bgi /timer:0 /nolicprompt
Write-Host ($writeEmptyLine + "# BgInfo has run" + $writeSeperator + $time)`
-foregroundcolor $foregroundColor1 $writeEmptyLine
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Finished
 
Write-Host ($writeEmptyLine + "# Script completed, BGP info should be installed" + $writeSeperator + $time)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
Start-Sleep 5
 
##--------------------------------------------------------------------------------------------------------------------------------------------

# Sysprep this image after a restart:
#
# C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /quiet /shutdown