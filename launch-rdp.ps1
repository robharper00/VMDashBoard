#######################
param (
    [string]$rdpInput
)

# Remove 'mstsc-launch://' prefix and any trailing slashes
$cleanIP = $rdpInput -replace '^mstsc-launch://', '' -replace '/$', ''

# Get the current logged-in username (DOMAIN\USERNAME format)
$currentUser = "$env:USERDOMAIN\$env:USERNAME"

# Validate the extracted IP or hostname
if ($cleanIP -match "^[\d\.]+$|^[a-zA-Z0-9\.-]+$") {
    Write-Host "Opening MSTSC settings with: $cleanIP and username: $currentUser"

    # Create a temporary RDP file with IP and username pre-filled
    $rdpFile = "$env:TEMP\custom.rdp"

    @"
full address:s:$cleanIP
username:s:$currentUser
"@ | Set-Content -Path $rdpFile -Encoding ASCII

    # Open MSTSC in settings mode with the IP and username pre-filled
    Start-Process "mstsc.exe" -ArgumentList "/edit", "$rdpFile"

} else {
    Write-Host "Invalid IP or hostname: $cleanIP"
    exit 1
}
#######################