# Augment Free Trial Reset Tool for Windows

This tool helps you reset the Augment free trial by cleaning VS Code databases and modifying telemetry IDs. It consists of two PowerShell scripts that work together to ensure a complete reset.

## Prerequisites

Before using this tool, make sure you have the following installed:

1. **PowerShell 5.1 or later**
   - Check your version by running: `$PSVersionTable.PSVersion`
   - If you need to update, download from [Microsoft's website](https://www.microsoft.com/en-us/download/details.aspx?id=54616)

2. **SQLite3**
   - Install using Chocolatey: `choco install sqlite`
   - Or download from [SQLite website](https://www.sqlite.org/download.html)

## Installation

1. Download both PowerShell scripts:
   - `clean_code_db.ps1`
   - `id_modifier.ps1`

2. Place them in a folder of your choice (e.g., `C:\augment-reset`)

## Usage

### Step 1: Close VS Code
Make sure to close VS Code completely before running the scripts.

### Step 2: Run the Scripts
Open PowerShell as Administrator and navigate to the folder containing the scripts:

```powershell
cd C:\augment-reset  # or your chosen folder
```

Run the scripts in this order:

1. First, clean the VS Code databases:
```powershell
.\clean_code_db.ps1
```

2. Then, modify the telemetry IDs:
```powershell
.\id_modifier.ps1
```

### What the Scripts Do

1. **clean_code_db.ps1**:
   - Finds all VS Code database files
   - Creates backups of the databases
   - Removes all Augment-related entries
   - Cleans both user and workspace storage

2. **id_modifier.ps1**:
   - Creates a backup of your VS Code storage
   - Generates new random machine and device IDs
   - Updates all telemetry IDs in VS Code

## Troubleshooting

### Common Issues

1. **"sqlite3.exe not found"**
   - Solution: Install SQLite3 using Chocolatey: `choco install sqlite`

2. **"Access Denied"**
   - Solution: Run PowerShell as Administrator

3. **"No VS Code database locations found"**
   - Solution: Make sure VS Code is installed and you've used it at least once

4. **Script Execution Policy Error**
   - Solution: Run this command in PowerShell as Administrator:
     ```powershell
     Set-ExecutionPolicy RemoteSigned
     ```

### Backup Files

The scripts create backup files with `.backup` extension. If something goes wrong, you can restore from these backups:
- Database backups: `*.db.backup`
- Storage backup: `storage.json.backup`

## Safety Features

- Automatic backups before any changes
- Color-coded output for easy status tracking
- Detailed logging of all operations
- Safe database cleaning with transaction support

## Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Make sure all prerequisites are installed
3. Verify you're running PowerShell as Administrator
4. Check the backup files if you need to restore

## Note

This tool is designed for Windows systems only. For other operating systems, please refer to the main README.md file. 