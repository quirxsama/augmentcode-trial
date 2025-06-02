# id_modifier.ps1
#
# Description: Script to modify VS Code telemetry IDs
# This script is designed to work on Windows systems

# Text formatting
$BOLD = "`e[1m"
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$RESET = "`e[0m"

# Log functions
function Log-Info {
    param([string]$message)
    Write-Host "$BLUE[INFO]$RESET $message"
}

function Log-Success {
    param([string]$message)
    Write-Host "$GREEN[SUCCESS]$RESET $message"
}

function Log-Warning {
    param([string]$message)
    Write-Host "$YELLOW[WARNING]$RESET $message"
}

function Log-Error {
    param([string]$message)
    Write-Host "$RED[ERROR]$RESET $message"
}

# Generate random hex string
function Get-RandomHexString {
    param(
        [int]$length
    )
    
    $bytes = New-Object byte[] $length
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    return [System.BitConverter]::ToString($bytes).Replace("-", "").ToLower()
}

# Generate random UUID v4
function Get-RandomUUID {
    return [guid]::NewGuid().ToString()
}

# Get VS Code storage.json location
function Get-VSCodeStorageLocation {
    $appData = [Environment]::GetFolderPath('ApplicationData')
    $paths = @(
        (Join-Path $appData "Code\User\storage.json"),
        (Join-Path $appData "Code\User\globalStorage\storage.json")
    )
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

# Create backup of a file
function Backup-File {
    param(
        [string]$filePath
    )
    
    $backupPath = "$filePath.backup"
    if (-not (Test-Path $backupPath)) {
        Copy-Item -Path $filePath -Destination $backupPath
        Log-Success "Created backup: $backupPath"
    } else {
        Log-Warning "Backup already exists: $backupPath"
    }
}

function Set-TelemetryIDs-Recursive {
    param(
        [Parameter(ValueFromPipeline=$true)] $obj,
        [string]$newMachineId,
        [string]$newDevDeviceId
    )
    if ($null -eq $obj) { return }
    if ($obj -is [System.Collections.IDictionary]) {
        foreach ($key in $obj.Keys) {
            if ($key -eq 'machineId') {
                $obj[$key] = $newMachineId
            } elseif ($key -eq 'devDeviceId') {
                $obj[$key] = $newDevDeviceId
            } else {
                Set-TelemetryIDs-Recursive -obj $obj[$key] -newMachineId $newMachineId -newDevDeviceId $newDevDeviceId
            }
        }
    } elseif ($obj -is [System.Collections.IEnumerable] -and -not ($obj -is [string])) {
        foreach ($item in $obj) {
            Set-TelemetryIDs-Recursive -obj $item -newMachineId $newMachineId -newDevDeviceId $newDevDeviceId
        }
    }
}

function Modify-TelemetryIDs {
    param(
        [string]$storagePath
    )
    try {
        # Create backup
        Backup-File -filePath $storagePath
        # Read the current storage.json
        $storage = Get-Content $storagePath -Raw | ConvertFrom-Json
        # Generate new IDs
        $newMachineId = Get-RandomHexString -length 32
        $newDevDeviceId = Get-RandomUUID
        # Recursively update all machineId and devDeviceId properties
        Set-TelemetryIDs-Recursive -obj $storage -newMachineId $newMachineId -newDevDeviceId $newDevDeviceId
        # Save the modified storage.json
        $storage | ConvertTo-Json -Depth 10 | Set-Content $storagePath
        Log-Success "Updated telemetry IDs in: $storagePath"
        Log-Info "New machineId: $newMachineId"
        Log-Info "New devDeviceId: $newDevDeviceId"
    } catch {
        Log-Error "Failed to modify telemetry IDs: $_"
    }
}

# Main function
function Main {
    Log-Info "Starting VS Code telemetry ID modification process..."
    
    # Get VS Code storage.json location
    $storagePath = Get-VSCodeStorageLocation
    
    if (-not $storagePath) {
        Log-Warning "VS Code storage.json not found"
        return
    }
    
    # Modify telemetry IDs
    Modify-TelemetryIDs -storagePath $storagePath
}

# Run the main function
Main 