# =============================================================================
# WINDOWS DEVELOPMENT ENVIRONMENT SETUP SCRIPT
# =============================================================================
# PowerShell script for setting up direnv and Nix on Windows
# Supports both native Windows and WSL environments

param(
    [switch]$InstallDirenv,
    [switch]$InstallNix,
    [switch]$SetupHooks,
    [switch]$Help,
    [switch]$Uninstall,
    [switch]$Update,
    [switch]$Backup,
    [switch]$Verify
)

# =============================================================================
# CONFIGURATION
# =============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"
$White = "White"

# Backup directory
$BackupDir = "$env:USERPROFILE\WindowsDevSetup_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function Write-Status {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor $Cyan
    Write-Host $Message -ForegroundColor $White
}

function Write-Success {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor $Green
    Write-Host "[SUCCESS] " -NoNewline -ForegroundColor $Green
    Write-Host $Message -ForegroundColor $White
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor $Yellow
    Write-Host "[WARNING] " -NoNewline -ForegroundColor $Yellow
    Write-Host $Message -ForegroundColor $White
}

function Write-Error {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor $Red
    Write-Host "[ERROR] " -NoNewline -ForegroundColor $Red
    Write-Host $Message -ForegroundColor $White
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-WSL {
    try {
        $wslVersion = wsl -l -v 2>$null
        return $true
    } catch {
        return $false
    }
}

function Backup-File {
    param([string]$FilePath)
    if (Test-Path $FilePath) {
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        $backupPath = Join-Path $BackupDir $fileName
        Copy-Item $FilePath $backupPath -Force
        Write-Success "Backed up $fileName to $backupPath"
    }
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

function Install-Direnv {
    Write-Status "Installing direnv..."

    # Check if already installed
    if (Test-Command "direnv") {
        Write-Success "direnv is already installed"
        return
    }

    # Try Scoop first (preferred for Windows)
    if (Test-Command "scoop") {
        Write-Status "Installing direnv via Scoop..."
        try {
            scoop install direnv
            Write-Success "direnv installed via Scoop"
            return
        } catch {
            Write-Warning "Scoop installation failed, trying Chocolatey..."
        }
    }

    # Try Chocolatey
    if (Test-Command "choco") {
        Write-Status "Installing direnv via Chocolatey..."
        try {
            choco install direnv -y
            Write-Success "direnv installed via Chocolatey"
            return
        } catch {
            Write-Warning "Chocolatey installation failed, trying manual installation..."
        }
    }

    # Manual installation
    Write-Status "Installing direnv manually..."
    try {
        $tempDir = [System.IO.Path]::GetTempPath()
        $direnvPath = Join-Path $tempDir "direnv.exe"

        # Download latest release
        $apiUrl = "https://api.github.com/repos/direnv/direnv/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl
        $asset = $release.assets | Where-Object { $_.name -like "*windows*amd64*" -and $_.name -notlike "*.sha256sum" } | Select-Object -First 1

        if ($asset) {
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $direnvPath
            $installPath = "$env:USERPROFILE\bin"
            if (!(Test-Path $installPath)) {
                New-Item -ItemType Directory -Path $installPath | Out-Null
            }
            Move-Item $direnvPath (Join-Path $installPath "direnv.exe") -Force

            # Add to PATH
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($currentPath -notlike "*$installPath*") {
                [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installPath", "User")
                Write-Warning "Added $installPath to PATH - restart PowerShell to take effect"
            }

            Write-Success "direnv installed manually"
        } else {
            throw "Could not find Windows direnv release"
        }
    } catch {
        Write-Error "Failed to install direnv: $($_.Exception.Message)"
        Write-Status "Visit https://direnv.net/docs/installation.html for manual installation"
    }
}

function Install-Nix {
    Write-Status "Installing Nix..."

    # Check if already installed
    if (Test-Command "nix") {
        Write-Success "Nix is already installed"
        return
    }

    # Check if WSL is available
    if (Test-WSL) {
        Write-Status "Installing Nix in WSL..."
        Write-Status "Run this in WSL terminal:"
        Write-Host "  curl -L https://nixos.org/nix/install | sh" -ForegroundColor $Yellow
        Write-Host ""
        Write-Host "Then install nix-direnv:" -ForegroundColor $White
        Write-Host "  nix-env -iA nixpkgs.nix-direnv" -ForegroundColor $Yellow
        return
    }

    # Native Windows installation
    Write-Status "Installing Nix for Windows..."
    try {
        # Download and run Nix installer
        $installerUrl = "https://hydra.nixos.org/job/nix/master/binaryTarball.x86_64-windows/latest/download/1/nix-2.15.0-x86_64-windows.tar.xz"
        $tempDir = [System.IO.Path]::GetTempPath()
        $installerPath = Join-Path $tempDir "nix-installer.tar.xz"

        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

        # Extract and install
        $extractPath = Join-Path $tempDir "nix-installer"
        & tar -xf $installerPath -C $tempDir

        $installerScript = Join-Path $extractPath "install.ps1"
        if (Test-Path $installerScript) {
            & $installerScript
            Write-Success "Nix installed for Windows"
        } else {
            throw "Installer script not found"
        }
    } catch {
        Write-Error "Failed to install Nix: $($_.Exception.Message)"
        Write-Status "Visit https://nixos.org/download.html for manual installation"
    }
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

function Verify-Installation {
    Write-Status "Verifying Installation"

    $verifications = @()

    # Check direnv
    if (Test-Command "direnv") {
        try {
            $direnvVersion = direnv --version
            $verifications += @{Name = "direnv"; Status = "Installed"; Details = $direnvVersion }
        } catch {
            $verifications += @{Name = "direnv"; Status = "Error"; Details = "Cannot get version" }
        }
    } else {
        $verifications += @{Name = "direnv"; Status = "Not Found"; Details = "direnv not installed" }
    }

    # Check Nix
    if (Test-Command "nix") {
        try {
            $nixVersion = nix --version
            $verifications += @{Name = "Nix"; Status = "Installed"; Details = $nixVersion }
        } catch {
            $verifications += @{Name = "Nix"; Status = "Error"; Details = "Cannot get version" }
        }
    } else {
        $verifications += @{Name = "Nix"; Status = "Not Found"; Details = "Nix not installed" }
    }

    # Check WSL
    if (Test-WSL) {
        $verifications += @{Name = "WSL"; Status = "Available"; Details = "WSL is available" }
    } else {
        $verifications += @{Name = "WSL"; Status = "Not Available"; Details = "WSL not available" }
    }

    # Check PowerShell profile
    $profilePath = $PROFILE
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        if ($profileContent -like "*direnv hook pwsh*") {
            $verifications += @{Name = "PowerShell Profile"; Status = "Configured"; Details = "direnv hook configured" }
        } else {
            $verifications += @{Name = "PowerShell Profile"; Status = "Not Configured"; Details = "direnv hook not found" }
        }
    } else {
        $verifications += @{Name = "PowerShell Profile"; Status = "Missing"; Details = "Profile file not found" }
    }

    # Display results
    foreach ($verification in $verifications) {
        if ($verification.Status -eq "Installed" -or $verification.Status -eq "Available" -or $verification.Status -eq "Configured") {
            Write-Success "$($verification.Name): $($verification.Details)"
        } else {
            Write-Warning "$($verification.Name): $($verification.Details)"
        }
    }
}

# =============================================================================
# UNINSTALL FUNCTIONS
# =============================================================================

function Uninstall-Direnv {
    Write-Status "Uninstalling direnv..."

    try {
        # Try Scoop uninstall
        if (Test-Command "scoop") {
            scoop uninstall direnv
            Write-Success "direnv uninstalled via Scoop"
            return
        }

        # Try Chocolatey uninstall
        if (Test-Command "choco") {
            choco uninstall direnv -y
            Write-Success "direnv uninstalled via Chocolatey"
            return
        }

        # Manual uninstall
        $installPath = "$env:USERPROFILE\bin\direnv.exe"
        if (Test-Path $installPath) {
            Remove-Item $installPath -Force
            Write-Success "direnv manually uninstalled"
        } else {
            Write-Warning "direnv installation not found"
        }
    } catch {
        Write-Error "Failed to uninstall direnv: $($_.Exception.Message)"
    }
}

function Uninstall-Nix {
    Write-Status "Uninstalling Nix..."

    try {
        # For Windows native Nix
        $nixPath = "$env:USERPROFILE\.nix"
        if (Test-Path $nixPath) {
            Remove-Item $nixPath -Recurse -Force
            Write-Success "Nix configuration removed"
        }

        # Remove from PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $newPath = $currentPath -replace [regex]::Escape("$env:USERPROFILE\.nix-profile\bin;"), ""
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

        Write-Success "Nix uninstalled from Windows"
    } catch {
        Write-Error "Failed to uninstall Nix: $($_.Exception.Message)"
        Write-Warning "Nix uninstallation may require manual cleanup"
    }
}

# =============================================================================
# UPDATE FUNCTIONS
# =============================================================================

function Update-Direnv {
    Write-Status "Updating direnv..."

    try {
        # Try Scoop update
        if (Test-Command "scoop") {
            scoop update direnv
            Write-Success "direnv updated via Scoop"
            return
        }

        # Try Chocolatey upgrade
        if (Test-Command "choco") {
            choco upgrade direnv -y
            Write-Success "direnv updated via Chocolatey"
            return
        }

        # Manual update
        Write-Status "Checking for direnv updates..."
        $apiUrl = "https://api.github.com/repos/direnv/direnv/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl
        $asset = $release.assets | Where-Object { $_.name -like "*windows*amd64*" -and $_.name -notlike "*.sha256sum" } | Select-Object -First 1

        if ($asset) {
            $tempDir = [System.IO.Path]::GetTempPath()
            $newDirenvPath = Join-Path $tempDir "direnv-new.exe"
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $newDirenvPath

            $installPath = "$env:USERPROFILE\bin\direnv.exe"
            if (Test-Path $installPath) {
                Move-Item $newDirenvPath $installPath -Force
                Write-Success "direnv manually updated"
            } else {
                Write-Warning "direnv installation not found for update"
            }
        } else {
            Write-Warning "Could not find latest direnv release"
        }
    } catch {
        Write-Error "Failed to update direnv: $($_.Exception.Message)"
    }
}

function Update-Nix {
    Write-Status "Updating Nix..."

    try {
        if (Test-Command "nix") {
            # Update Nix channels
            nix-channel --update
            Write-Success "Nix channels updated"

            # Upgrade Nix itself
            nix upgrade-nix
            Write-Success "Nix upgraded"
        } else {
            Write-Warning "Nix not found - cannot update"
        }
    } catch {
        Write-Error "Failed to update Nix: $($_.Exception.Message)"
    }
}

# =============================================================================
# BACKUP FUNCTIONS
# =============================================================================

function Create-Backup {
    Write-Status "Creating Configuration Backup"

    # Create backup directory
    if (!(Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }

    # Backup important files
    $filesToBackup = @(
        "$env:USERPROFILE\.bashrc",
        "$env:USERPROFILE\.zshrc",
        "$env:USERPROFILE\.envrc",
        "$env:USERPROFILE\.env",
        $PROFILE,
        "$env:USERPROFILE\.config\direnv\config.toml"
    )

    foreach ($file in $filesToBackup) {
        Backup-File $file
    }

    # Backup environment variables
    $envBackup = @{
        "DIRENV_CONFIG" = [Environment]::GetEnvironmentVariable("DIRENV_CONFIG", "User")
        "Path" = [Environment]::GetEnvironmentVariable("Path", "User")
    }

    $envBackupPath = Join-Path $BackupDir "environment_backup.json"
    $envBackup | ConvertTo-Json | Out-File $envBackupPath -Encoding UTF8
    Write-Success "Environment variables backed up to $envBackupPath"

    Write-Success "Backup completed in $BackupDir"
}

function Setup-DirenvHooks {
    Write-Status "Setting up direnv shell hooks..."

    # PowerShell profile path
    $profilePath = $PROFILE

    # Check if profile exists
    if (!(Test-Path $profilePath)) {
        Write-Status "Creating PowerShell profile..."
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    # Check if direnv hook is already configured
    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -notlike "*direnv hook pwsh*") {
        Write-Status "Adding direnv hook to PowerShell profile..."

        # Add direnv hook
        $hookScript = @"

# direnv hook for PowerShell
if (Get-Command direnv -ErrorAction SilentlyContinue) {
    Invoke-Expression "$(direnv hook pwsh)"
}
"@

        Add-Content -Path $profilePath -Value $hookScript
        Write-Success "Added direnv hook to PowerShell profile"
        Write-Warning "Restart PowerShell or run '. `$PROFILE' to load the hook"
    } else {
        Write-Success "direnv hook already configured in PowerShell profile"
    }

    # Setup for WSL if available
    if (Test-WSL) {
        Write-Status "Setting up direnv hooks in WSL..."

        try {
            # Try to get the default WSL distribution
            $wslOutput = wsl -l -q 2>$null
            if ($LASTEXITCODE -eq 0) {
                # Get the first available distribution
                $distributions = $wslOutput | Where-Object { $_ -and $_.Trim() -ne "" }
                if ($distributions) {
                    $defaultDist = $distributions[0].Trim()

                    # Convert Windows path to WSL path
                    $currentPath = Get-Location
                    $wslPath = $currentPath.Path -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/' | ForEach-Object { $_.ToLower() }

                    # Setup bash hook in WSL and sync directory
                    $wslCommand = @"
echo 'eval "`$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc
cd '$wslPath' 2>/dev/null || echo "Directory sync may not work if Nix is not installed in WSL"
"@

                    wsl -d $defaultDist -- bash -c $wslCommand
                    Write-Success "Added direnv hook to WSL ($defaultDist) and synced directory"
                } else {
                    Write-Warning "No WSL distributions found"
                }
            } else {
                Write-Warning "WSL command failed - WSL may not be properly installed"
            }
        } catch {
            Write-Warning "WSL setup failed: $($_.Exception.Message)"
        }
    }
}

function Setup-Environment {
    Write-Status "Setting up project environment..."

    # Check for .envrc file
    if (!(Test-Path ".envrc")) {
        Write-Status "Creating .envrc file..."
        $envrcContent = @"
#!/usr/bin/env bash
echo "🔧 Loading development environment..."

# Load .env file if it exists
if [ -f ".env" ]; then
    echo "📋 Loading environment variables from .env"
    set -a
    source .env
    set +a
fi

# Set basic project paths
export PROJECT_ROOT="`$(pwd)"
export PATH="`$PROJECT_ROOT/07_SCRIPT:`$PATH"

echo "✅ Environment loaded!"
"@
        $envrcContent | Out-File -FilePath ".envrc" -Encoding UTF8
        Write-Success ".envrc file created"
    } else {
        Write-Success ".envrc file already exists"
    }

    # Setup direnv configuration directory
    if (Test-Command "direnv") {
        Write-Status "Setting up direnv configuration..."

        # Create direnv config directory if it doesn't exist
        $direnvConfigDir = "$env:USERPROFILE\.config\direnv"
        if (!(Test-Path $direnvConfigDir)) {
            New-Item -ItemType Directory -Path $direnvConfigDir -Force | Out-Null
            Write-Success "Created direnv config directory"
        }

        # Set DIRENV_CONFIG environment variable
        $currentDirenvConfig = [Environment]::GetEnvironmentVariable("DIRENV_CONFIG", "User")
        if (!$currentDirenvConfig) {
            [Environment]::SetEnvironmentVariable("DIRENV_CONFIG", $direnvConfigDir, "User")
            Write-Success "Set DIRENV_CONFIG environment variable"
        }

        # Allow .envrc if direnv is available
        Write-Status "Allowing .envrc file..."
        try {
            $env:DIRENV_CONFIG = $direnvConfigDir
            direnv allow .
            Write-Success ".envrc file allowed"
        } catch {
            Write-Warning "Could not automatically allow .envrc - run 'direnv allow .' manually"
            Write-Status "Error: $($_.Exception.Message)"
        }
    }
}

# =============================================================================
# MAIN SCRIPT LOGIC
# =============================================================================

function Show-Help {
    Write-Host "Windows Development Environment Setup Script" -ForegroundColor $White
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor $White
    Write-Host "  .\setup-windows.ps1 [options]" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor $White
    Write-Host "  -InstallDirenv    Install direnv for automatic environment loading" -ForegroundColor $Cyan
    Write-Host "  -InstallNix       Install Nix for reproducible environments" -ForegroundColor $Cyan
    Write-Host "  -SetupHooks       Setup direnv shell hooks" -ForegroundColor $Cyan
    Write-Host "  -Uninstall        Uninstall direnv and Nix" -ForegroundColor $Cyan
    Write-Host "  -Update          Update direnv and Nix" -ForegroundColor $Cyan
    Write-Host "  -Backup          Create configuration backup" -ForegroundColor $Cyan
    Write-Host "  -Verify          Verify all installations" -ForegroundColor $Cyan
    Write-Host "  -Help            Show this help message" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor $White
    Write-Host "  .\setup-windows.ps1 -InstallDirenv -SetupHooks" -ForegroundColor $Cyan
    Write-Host "  .\setup-windows.ps1 -InstallNix" -ForegroundColor $Cyan
    Write-Host "  .\setup-windows.ps1 -Verify" -ForegroundColor $Cyan
    Write-Host "  .\setup-windows.ps1 -Backup" -ForegroundColor $Cyan
    Write-Host ""
}

# Main execution
Write-Host "🚀 Windows Development Environment Setup" -ForegroundColor $Green
Write-Host "═════════════════════════════════════════" -ForegroundColor $White
Write-Host ""

if ($Help) {
    Show-Help
    exit 0
}

# Create backup if requested
if ($Backup) {
    Create-Backup
    Write-Host ""
}

# Handle uninstall
if ($Uninstall) {
    Uninstall-Direnv
    Write-Host ""
    Uninstall-Nix
    Write-Host ""
    Write-Success "Uninstallation completed"
    exit 0
}

# Handle update
if ($Update) {
    Update-Direnv
    Write-Host ""
    Update-Nix
    Write-Host ""
    Write-Success "Update completed"
    exit 0
}

# Handle verification
if ($Verify) {
    Verify-Installation
    exit 0
}

# Run installations if requested
if ($InstallDirenv) {
    Install-Direnv
    Write-Host ""
}

if ($InstallNix) {
    Install-Nix
    Write-Host ""
}

if ($SetupHooks) {
    Setup-DirenvHooks
    Write-Host ""
}

# Always setup environment
Setup-Environment

Write-Host ""
Write-Success "Setup complete!"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor $White
Write-Host "1. Restart PowerShell to load direnv hooks" -ForegroundColor $Cyan
Write-Host "2. Run 'direnv allow .' if .envrc wasn't automatically allowed" -ForegroundColor $Cyan
Write-Host "3. Copy .env.example from your config directory to .env and configure" -ForegroundColor $Cyan
Write-Host ""
Write-Host "Script Options:" -ForegroundColor $White
Write-Host "• Verify installations: .\setup-windows.ps1 -Verify" -ForegroundColor $Cyan
Write-Host "• Create backup: .\setup-windows.ps1 -Backup" -ForegroundColor $Cyan
Write-Host "• Update tools: .\setup-windows.ps1 -Update" -ForegroundColor $Cyan
Write-Host "• Uninstall all: .\setup-windows.ps1 -Uninstall" -ForegroundColor $Cyan
Write-Host ""
Write-Host "For WSL users:" -ForegroundColor $White
Write-Host "• Install Nix in WSL: curl -L https://nixos.org/nix/install | sh" -ForegroundColor $Cyan
Write-Host "• Install nix-direnv: nix-env -iA nixpkgs.nix-direnv" -ForegroundColor $Cyan
Write-Host ""
Write-Host "Notes:" -ForegroundColor $White
Write-Host "• Backups are saved to: $BackupDir" -ForegroundColor $Yellow
Write-Host "• Script supports both native Windows and WSL environments" -ForegroundColor $Yellow
Write-Host "• For help, see: 00_DOCS/environment-setup.md" -ForegroundColor $White