#Deploy Script for V2 VM Page
try {
    Write-Host "Starting Server Setup..."

    # Define paths
    $scriptPath = "C:\Scripts1"
    $sharePath = "D:\RDP_Button\V2"
    $htmlPath = "$sharePath\VMs.html"
    $taskName = "Update_VM_HTML"
    $taskScriptPath = "$scriptPath\GenerateHTML.ps1"
    $protocol = "mstsc-launch"
    $launchRdpPath = "$scriptPath\launch-rdp.ps1"
    


# Ensure Scripts directory exists #######################################################################################
    try {
        if (-not (Test-Path $scriptPath)) {
            Write-Host "Creating Scripts directory..." -ForegroundColor Green
            New-Item -Path $scriptPath -ItemType Directory -ErrorAction Stop
        }
    } catch {
        Write-Host "ERROR: Failed to create Scripts directory." -ForegroundColor Red
    }

    # Ensure SMB share exists
    if (-not (Test-Path $sharePath)) {
        Write-Host "ERROR: Network share path does not exist. Ensure D:\RDP_Button\V2 is configured." -ForegroundColor Red
    }

# Generate Registry to launch the powershell script ####################################################################
    try {
        # Ensure the PowerShell script is called with the correct argument
        $command = "powershell.exe -ExecutionPolicy Bypass -File `"$launchRdpPath`" `"%1`""

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
    } catch {
        Write-Host "ERROR: Could not set up the registry" -ForegroundColor Red
    }

# End Generate Registry to launch the powershell script ################################################################


# Create GenerateHTML.ps1 - Directly fetch VM list######################################################################
    try {
        Write-Host "Creating GenerateHTML.ps1..." -ForegroundColor Green
        # Check if the file exists
        if (Test-Path -Path $taskScriptPath -PathType Leaf) {
            Write-Host "File '$taskScriptPath' exists. Attempting to delete..." -ForegroundColor Yellow
            # Delete the file
            Remove-Item -Path $taskScriptPath -Force -ErrorAction SilentlyContinue
            # Verify if the deletion was successful
            if (-not (Test-Path -Path $taskScriptPath -PathType Leaf)) {
                Write-Host "Existing File '$taskScriptPath' successfully deleted." -ForegroundColor Green
            } else {
                Write-Host "Failed to delete file existing '$taskScriptPath'." -ForegroundColor Red
            }
        } else {
            Write-Host "File '$taskScriptPath' does not exist. Creating one now" -ForegroundColor Green
        }

        @'
$htmlPath = "D:\RDP_Button\V2\VMs.html" ########%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Update this path

# Get live Hyper-V VM list
$vms = Get-VM | Select-Object -ExpandProperty Name

$html = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <title>Remote Desktop Launcher</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; }
        table { border-collapse: collapse; width: 60%; margin: auto; }
        th, td { border: 1px solid black; padding: 10px; }
        th { background-color: #f2f2f2; }
        button { padding: 8px 12px; background-color: #0078D7; color: white; border: none; border-radius: 5px; cursor: pointer; }
        button:hover { background-color: #005A9E; }
        input { width: 200px; padding: 5px; }
    </style>
    <script>
        function launchRDP(target) {
            window.location.href = 'mstsc-launch://' + target;
        }
    </script>
</head>
<body>

    <h2>Remote Desktop Connection</h2>

    <!-- Free Input Section -->
    <h3>Connect to Any Computer</h3>
    <input type="text" id="customTarget" placeholder="Enter IP or hostname">
    <button onclick="launchRDP(document.getElementById('customTarget').value)">Connect</button>

    <!-- Host Server Connection -->
    <h3>Connect to Host Server</h3>
    <button onclick="launchRDP('$env:COMPUTERNAME')">Connect to $env:COMPUTERNAME</button>

    <!-- VM List Section -->
    <h3>Available Virtual Machines</h3>
    <table>
        <tr><th>VM Name</th><th>Connect</th></tr>
"@

foreach ($vm in $vms) {
    $html += "<tr><td>$vm</td><td><button onclick=`"launchRDP('$vm')`">Connect</button></td></tr>"
}

$html += "</table></body></html>"

$html | Out-File -Encoding utf8 -FilePath $htmlPath
'@ | Set-Content $taskScriptPath -ErrorAction Stop
    } catch {
        Write-Host "ERROR: Failed to create GenerateHTML.ps1 script." -ForegroundColor Red
    }

################# End Generating html #########################################################################################



#################### Generate launch-rdp powershell ###########################################################################
    try { 
        # Check if the file exists
        if (Test-Path -Path $launchRdpPath -PathType Leaf) {
            Write-Host "File '$launchRdpPath' exists. Attempting to delete..." -ForegroundColor Yellow
    
            # Delete the file
            Remove-Item -Path $launchRdpPath -Force -ErrorAction SilentlyContinue
    
            # Verify if the deletion was successful
            if (-not (Test-Path -Path $launchRdpPath -PathType Leaf)) {
                Write-Host "Existing File '$launchRdpPath' successfully deleted." -ForegroundColor Green
            } else {
                Write-Host "Failed to delete file existing '$launchRdpPath'." -ForegroundColor Red
            }
        } else {
            Write-Host "File '$launchRdpPath' does not exist. Creating one now" -ForegroundColor Green
        }
@'
param (
    [string]$rdpInput
)

# Remove 'mstsc-launch://' prefix and any trailing slashes
$cleanIP = $rdpInput -replace "^mstsc-launch://", "" -replace "/$", ""

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

'@| Set-Content $launchRdpPath -ErrorAction Stop
    } catch {
        Write-Host "Failed to create '$launchRdpPath'." -ForegroundColor Red
    }
#################### end Generate launch-rdp powershell ########################################################################




# Remove existing scheduled task (if it exists) ###############################################################################
    try {
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Write-Host "Removing existing scheduled task..." -ForegroundColor Green
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
    } catch {
        Write-Host "ERROR: Failed to remove old scheduled task. It might not exist." -ForegroundColor Red
    }

# Run GenerateHTML.ps1 Immediately to Create First HTML File ##################################################################
    try {
        Write-Host "Generating the initial HTML file..." -ForegroundColor Green
        Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$taskScriptPath`"" -Wait
    } catch {
        Write-Host "ERROR: Failed to generate initial HTML file." -ForegroundColor Red
    }

# Register Scheduled Task to update HTML every 10 minutes ######################################################################
    try {
        Write-Host "Creating Scheduled Task..." -ForegroundColor Green
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$taskScriptPath`""
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10)

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest

        Write-Host "Scheduled Task Created! HTML will update every 10 minutes." -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to create Scheduled Task." -ForegroundColor Red
    }

    Write-Host "Server Setup Complete! Clients can now use the shared HTML interface to connect to VMs." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Unexpected issue encountered: $($_.Exception.Message)" -ForegroundColor Red
}
# End Register Scheduled Task to update HTML every 10 minutes ##################################################################