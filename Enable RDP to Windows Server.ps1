#enable RDP access to Windows server.
Set-ItemProperty ‘HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\‘ -Name “fDenyTSConnections” -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"