$protocol = "mstsc-launch"
$ps1Path = "C:\Scripts\launch-rdp.ps1"  # <-- Update this path if needed

# Ensure the PowerShell script is called with the correct argument
$command = "powershell.exe -ExecutionPolicy Bypass -File `"$ps1Path`" `"%1`""

# Remove old registry entry (if exists)
Remove-Item -Path "HKCU:\Software\Classes\$protocol" -Recurse -Force -ErrorAction SilentlyContinue

# Create registry entries
New-Item -Path "HKCU:\Software\Classes\$protocol" -Force
Set-ItemProperty -Path "HKCU:\Software\Classes\$protocol" -Name "(Default)" -Value "URL:MSTSC Launcher"
Set-ItemProperty -Path "HKCU:\Software\Classes\$protocol" -Name "URL Protocol" -Value ""

New-Item -Path "HKCU:\Software\Classes\$protocol\shell" -Force
New-Item -Path "HKCU:\Software\Classes\$protocol\shell\open" -Force
New-Item -Path "HKCU:\Software\Classes\$protocol\shell\open\command" -Force

# Set the command to call the PowerShell script
Set-ItemProperty -Path "HKCU:\Software\Classes\$protocol\shell\open\command" -Name "(Default)" -Value $command
#######################