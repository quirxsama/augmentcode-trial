# clean_code_db.ps1
#
# Description: Script to clean VS Code databases by removing Augment-related entries
# This script is designed to work on Windows systems

# Log functions with color
function Log-Info {
    param([string]$message)
    Write-Host "[INFO] $message" -ForegroundColor Blue
}

function Log-Success {
    param([string]$message)
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Log-Warning {
    param([string]$message)
    Write-Host "[WARNING] $message" -ForegroundColor Yellow
}

function Log-Error {
    param([string]$message)
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

# Check if sqlite3.exe is available
function Check-SQLite3 {
    $sqlitePath = (Get-Command sqlite3.exe -ErrorAction SilentlyContinue).Source
    if (-not $sqlitePath) {
        Log-Error "sqlite3.exe not found in PATH. Please install SQLite3 and add it to your PATH."
        exit 1
    }
}

# Get VS Code database locations
function Get-VSCodeDatabaseLocations {
    $locations = @()
    # Get the user's AppData directory
    $appData = [Environment]::GetFolderPath('ApplicationData')
    $vscodePath = Join-Path $appData "Code"
    # Check for User Data directory
    $userDataPath = Join-Path $vscodePath "User"
    if (Test-Path $userDataPath) {
        $locations += $userDataPath
    }
    # Check for Workspace Storage directory
    $workspaceStoragePath = Join-Path $vscodePath "workspaceStorage"
    if (Test-Path $workspaceStoragePath) {
        $locations += $workspaceStoragePath
    }
    # Check for globalStorage directory
    $globalStoragePath = Join-Path $userDataPath "globalStorage"
    if (Test-Path $globalStoragePath) {
        $locations += $globalStoragePath
    }
    return $locations
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

# Clean SQLite database
function Clean-SQLiteDatabase {
    param(
        [string]$dbPath
    )
    try {
        # Create backup
        Backup-File -filePath $dbPath
        # Get list of tables
        $tables = & sqlite3.exe $dbPath ".tables"
        foreach ($table in $tables -split '\s+') {
            if ($table) {
                # Get column names for the table
                $columns = & sqlite3.exe $dbPath "PRAGMA table_info($table)"
                # Find columns that might contain text
                $textColumns = @()
                foreach ($column in $columns -split "`n") {
                    if ($column -match 'TEXT') {
                        $columnName = ($column -split '\|')[1]
                        $textColumns += $columnName
                    }
                }
                # Build and execute DELETE query for each text column
                foreach ($column in $textColumns) {
                    $query = "DELETE FROM $table WHERE $column LIKE '%augment%'"
                    & sqlite3.exe $dbPath $query
                }
            }
        }
        Log-Success "Cleaned database: $dbPath"
    } catch {
        Log-Error "Failed to clean database $dbPath : $_"
    }
}

# Main function
function Main {
    Log-Info "Starting VS Code database cleaning process..."
    Check-SQLite3
    # Get VS Code database locations
    $locations = Get-VSCodeDatabaseLocations
    if ($locations.Count -eq 0) {
        Log-Warning "No VS Code database locations found"
        return
    }
    # Find and clean SQLite databases
    $dbCount = 0
    foreach ($location in $locations) {
        # Search for both .db and .vscdb files
        Get-ChildItem -Path $location -Recurse -Include *.db,*.vscdb -File | ForEach-Object {
            $dbCount++
            Log-Info "Found database: $($_.FullName)"
            Clean-SQLiteDatabase -dbPath $_.FullName
        }
    }
    if ($dbCount -eq 0) {
        Log-Warning "No database files found"
    } else {
        Log-Success "Cleaned $dbCount database files"
    }
}

# Run the main function
Main 