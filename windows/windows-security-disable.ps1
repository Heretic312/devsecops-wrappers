
# Create the required keys if they don't exist
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force

# Disable Windows Defender
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1

# Disable Real-Time Monitoring
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1

# Turn off firewall for Domain, Private, and Public profiles
netsh advfirewall set allprofiles state off

# Set UAC to Never Notify
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0

# Enable SMBv1 in the registry
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1

# Enable the SMB server
Start-Process -FilePath "sc.exe" -ArgumentList "config lanmanserver start=auto"
Start-Process -FilePath "sc.exe" -ArgumentList "start lanmanserver"

# Enable the SMB client
Start-Process -FilePath "sc.exe" -ArgumentList "config lanmanworkstation start=auto"
Start-Process -FilePath "sc.exe" -ArgumentList "start lanmanworkstation"


#Creating Users with Weak Passwords 
net user user password123 /add
net user Admin2 admin /add
net user osuser 123456 /add

# Optionally, add users to the Administrators group
net localgroup administrators user /add
net localgroup administrators Admin2 /add
net localgroup administrators osuser /add

# Modify Registry to Enable RDP
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0

# Enable RDP Service
Set-Service -Name "TermService" -StartupType Automatic
Start-Service -Name "TermService"

# Open RDP Port in Firewall
Write-Host "Opening RDP port in the firewall..."
netsh advfirewall firewall add rule name="Remote Desktop" dir=in action=allow protocol=TCP localport=3389

# Install FTP Server via IIS (Manual Step Required on Windows 7)
Write-Host "Ensure FTP Server is installed via Control Panel > Programs > Turn Windows Features On or Off > IIS > FTP Server."

# Open FTP Port in Firewall
Write-Host "Opening FTP port in the firewall..."
netsh advfirewall firewall add rule name="FTP Server" dir=in action=allow protocol=TCP localport=21
