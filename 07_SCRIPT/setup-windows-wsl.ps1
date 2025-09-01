# =============================================================================
# WINDOWS WSL + DOCKER DEVELOPMENT SETUP
# =============================================================================
# Simple, reliable setup for Windows + WSL + Docker development
# Focuses on getting you up and running quickly

param(
    [switch]$InstallWSL,
    [switch]$InstallDocker,
    [switch]$SetupEnvironment,
    [switch]$Help,
    [switch]$Uninstall,
    [switch]$Update,
    [switch]$Backup,
    [switch]$Verify,
    [string]$WSLDistro = ""
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
$BackupDir = "$env:USERPROFILE\WSLSetup_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor $Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] " -NoNewline -ForegroundColor $Green
    Write-Host $Message -ForegroundColor $White
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] " -NoNewline -ForegroundColor $Yellow
    Write-Host $Message -ForegroundColor $White
}

function Write-Error {
    param([string]$Message)
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

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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

function Select-WSLDistribution {
    Write-Step "Selecting WSL Distribution"

    # Get available distributions
    $distros = wsl -l -q 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "No WSL distributions found"
        Write-Host "Run: wsl --install -d <distro-name> (e.g., kali-linux, ubuntu)"
        return $null
    }

    $availableDistros = $distros | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }

    if ($availableDistros.Count -eq 0) {
        Write-Warning "No WSL distributions available"
        return $null
    }

    # If user specified a distro, validate it
    if ($WSLDistro) {
        if ($availableDistros -contains $WSLDistro) {
            Write-Success "Using specified WSL distribution: $WSLDistro"
            return $WSLDistro
        } else {
            Write-Warning "Specified distribution '$WSLDistro' not found. Available: $($availableDistros -join ', ')"
            return $null
        }
    }

    # If only one distro, use it
    if ($availableDistros.Count -eq 1) {
        $selectedDistro = $availableDistros[0]
        Write-Success "Using only available WSL distribution: $selectedDistro"
        return $selectedDistro
    }

    # Multiple distros - let user choose
    Write-Host "Available WSL distributions:" -ForegroundColor $Cyan
    for ($i = 0; $i -lt $availableDistros.Count; $i++) {
        Write-Host "  $($i + 1). $($availableDistros[$i])" -ForegroundColor $White
    }

    $choice = Read-Host "Select distribution (1-$($availableDistros.Count))"
    $index = [int]$choice - 1

    if ($index -ge 0 -and $index -lt $availableDistros.Count) {
        $selectedDistro = $availableDistros[$index]
        Write-Success "Selected WSL distribution: $selectedDistro"
        return $selectedDistro
    } else {
        Write-Warning "Invalid selection, using default"
        return $availableDistros[0]
    }
}

function Get-DistroSpecificCommands {
    param([string]$Distro, [string]$WSLPath)

    # Detect package manager and distribution for Docker installation
    $detectionCommands = @"
# Detect package manager and distribution
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    UPDATE_CMD="sudo apt update"
    INSTALL_CMD="sudo apt install -y"
    DISTRO_FAMILY="debian"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="sudo dnf check-update || true"
    INSTALL_CMD="sudo dnf install -y"
    DISTRO_FAMILY="fedora"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    UPDATE_CMD="sudo pacman -Sy"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    DISTRO_FAMILY="arch"
else
    echo "Unsupported package manager. Please install Docker manually."
    exit 1
fi

# Get distribution info for Docker repo
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=`$ID`
    DISTRO_VERSION=`$VERSION_CODENAME`
else
    DISTRO_ID="unknown"
    DISTRO_VERSION="unknown"
fi

echo "Detected package manager: `$PKG_MANAGER"
echo "Detected distribution: `$DISTRO_ID"
"@

    # Docker installation commands based on detected distribution
    $dockerCommands = @"
# Install prerequisites
`$UPDATE_CMD
`$INSTALL_CMD ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
if [ "`$DISTRO_FAMILY" = "debian" ] || [ "`$DISTRO_FAMILY" = "ubuntu" ]; then
    # Debian/Ubuntu/Kali
    if [ "`$DISTRO_ID" = "kali" ]; then
        DISTRO_NAME="debian"
        CODENAME="bullseye"  # Kali uses Debian testing/sid, but bullseye works
    else
        DISTRO_NAME="ubuntu"
        CODENAME=`$(lsb_release -cs 2>/dev/null || echo "focal")`
    fi
    curl -fsSL https://download.docker.com/linux/`$DISTRO_NAME/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=`$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/`$DISTRO_NAME `$CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
elif [ "`$DISTRO_FAMILY" = "fedora" ]; then
    # Fedora/RHEL
    `$INSTALL_CMD dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
elif [ "`$DISTRO_FAMILY" = "arch" ]; then
    # Arch Linux
    `$INSTALL_CMD docker
    sudo systemctl enable docker
    sudo systemctl start docker
    # Skip the rest of Docker installation for Arch
    echo "Docker installed on Arch Linux"
    exit 0
fi

# Update package list again
`$UPDATE_CMD

# Install Docker
`$INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker service
if command -v systemctl &> /dev/null; then
    sudo systemctl enable docker
    sudo systemctl start docker
else
    sudo service docker start
fi
"@

    # Combine all commands
    $fullCommands = @"
$($detectionCommands)

# Install basic tools
`$INSTALL_CMD curl wget git

# Install Docker
echo "Installing Docker in WSL..."
$($dockerCommands)

# Add user to docker group (if user exists)
if id -u `$USER > /dev/null 2>&1; then
    sudo usermod -aG docker `$USER
    echo "Added user to docker group. You may need to restart WSL for changes to take effect."
fi

# Install direnv
curl -sfL https://direnv.net/install.sh | bash

# Setup direnv
echo 'eval "`$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc

# Change to project directory
cd '$WSLPath' 2>/dev/null || echo "Directory sync may not work yet"

echo "WSL environment with Docker ready!"
"@

    return $fullCommands
}

# =============================================================================
# WSL FUNCTIONS
# =============================================================================

function Install-WSL {
    Write-Step "Installing WSL"

    # Check if WSL is already installed
    if (Test-Command "wsl") {
        Write-Success "WSL is already installed"
        return
    }

    # Enable WSL feature
    Write-Host "Enabling WSL Windows feature..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

    # Enable Virtual Machine Platform
    Write-Host "Enabling Virtual Machine Platform..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

    # Install WSL2
    Write-Host "Installing WSL2..."
    wsl --install

    Write-Success "WSL installed. Please restart your computer and run this script again."
    Write-Host "After restart, install your preferred distribution with: wsl --install -d <distro-name>"
    Write-Host "Example: wsl --install -d kali-linux"
    exit 0
}

function Setup-WSLDistribution {
    Write-Step "Setting up WSL Distribution"

    # Select distribution
    $selectedDistro = Select-WSLDistribution
    if (-not $selectedDistro) {
        return
    }

    Write-Success "Using WSL distribution: $selectedDistro"

    # Convert Windows path to WSL path for current directory
    $currentPath = Get-Location
    $wslPath = $currentPath.Path -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/' | ForEach-Object { $_.ToLower() }

    Write-Host "WSL path: $wslPath"

    # Detect package manager and set up commands
    $wslCommands = Get-DistroSpecificCommands -Distro $selectedDistro -WSLPath $wslPath

    Write-Host "Setting up WSL environment..."
    wsl -d $selectedDistro -- bash -c $wslCommands

    Write-Success "WSL environment configured"
}

# =============================================================================
# DOCKER FUNCTIONS
# =============================================================================

function Install-Docker {
    Write-Step "Installing Docker in WSL"

    # Check if WSL is available
    if (!(Test-Command "wsl")) {
        Write-Warning "WSL not available. Install WSL first."
        return
    }

    # Select distribution for Docker installation
    $selectedDistro = Select-WSLDistribution
    if (-not $selectedDistro) {
        return
    }

    # Check if Docker is already installed
    $dockerCheck = wsl -d $selectedDistro -- docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Docker is already installed in WSL ($selectedDistro)"
        return
    }

    Write-Host "Installing Docker in WSL distribution: $selectedDistro"

    # Convert Windows path to WSL path for current directory
    $currentPath = Get-Location
    $wslPath = $currentPath.Path -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/' | ForEach-Object { $_.ToLower() }

    # Get Docker installation commands
    $dockerCommands = Get-DistroSpecificCommands -Distro $selectedDistro -WSLPath $wslPath

    Write-Host "Setting up Docker in WSL..."
    wsl -d $selectedDistro -- bash -c $dockerCommands

    Write-Success "Docker installed in WSL ($selectedDistro)"
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

function Verify-Installation {
    Write-Step "Verifying Installation"

    $verifications = @()

    # Check WSL
    if (Test-Command "wsl") {
        $verifications += @{Name = "WSL"; Status = "Installed"; Details = "WSL available" }
    } else {
        $verifications += @{Name = "WSL"; Status = "Not Found"; Details = "WSL not installed" }
    }

    # Check WSL distributions
    if (Test-Command "wsl") {
        $distros = wsl -l -q 2>$null
        if ($LASTEXITCODE -eq 0) {
            $availableDistros = $distros | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
            $verifications += @{Name = "WSL Distributions"; Status = "Found"; Details = "$($availableDistros.Count) distributions: $($availableDistros -join ', ')" }
        } else {
            $verifications += @{Name = "WSL Distributions"; Status = "None"; Details = "No distributions found" }
        }
    }

    # Check Docker in WSL
    if (Test-Command "wsl") {
        $selectedDistro = Select-WSLDistribution
        if ($selectedDistro) {
            $dockerCheck = wsl -d $selectedDistro -- docker --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                $dockerVersion = wsl -d $selectedDistro -- docker --version
                $verifications += @{Name = "Docker in WSL"; Status = "Installed"; Details = $dockerVersion }
            } else {
                $verifications += @{Name = "Docker in WSL"; Status = "Not Found"; Details = "Docker not installed in $selectedDistro" }
            }
        }
    }

    # Display results
    foreach ($verification in $verifications) {
        if ($verification.Status -eq "Installed" -or $verification.Status -eq "Found") {
            Write-Success "$($verification.Name): $($verification.Details)"
        } else {
            Write-Warning "$($verification.Name): $($verification.Details)"
        }
    }
}

# =============================================================================
# UNINSTALL FUNCTIONS
# =============================================================================

function Uninstall-WSL {
    Write-Step "Uninstalling WSL"

    try {
        # Stop all running distributions
        wsl -l -q | ForEach-Object {
            if ($_ -and $_.Trim() -ne "") {
                wsl -t $_.Trim() 2>$null
            }
        }

        # Disable WSL features
        dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
        dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart

        # Remove WSL
        wsl --uninstall

        Write-Success "WSL uninstalled"
    } catch {
        Write-Error "Failed to uninstall WSL: $($_.Exception.Message)"
    }
}

function Uninstall-Docker {
    Write-Step "Uninstalling Docker from WSL"

    if (!(Test-Command "wsl")) {
        Write-Warning "WSL not available"
        return
    }

    $selectedDistro = Select-WSLDistribution
    if (-not $selectedDistro) {
        return
    }

    try {
        # Remove Docker from WSL
        $uninstallCommands = @"
# Stop Docker service
sudo systemctl stop docker 2>/dev/null || sudo service docker stop 2>/dev/null || true

# Remove Docker packages
if command -v apt &> /dev/null; then
    sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
elif command -v dnf &> /dev/null; then
    sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
elif command -v pacman &> /dev/null; then
    sudo pacman -Rns --noconfirm docker
fi

# Remove Docker group
sudo groupdel docker 2>/dev/null || true

echo "Docker uninstalled from WSL"
"@

        wsl -d $selectedDistro -- bash -c $uninstallCommands
        Write-Success "Docker uninstalled from WSL ($selectedDistro)"
    } catch {
        Write-Error "Failed to uninstall Docker: $($_.Exception.Message)"
    }
}

# =============================================================================
# UPDATE FUNCTIONS
# =============================================================================

function Update-Docker {
    Write-Step "Updating Docker in WSL"

    if (!(Test-Command "wsl")) {
        Write-Warning "WSL not available"
        return
    }

    $selectedDistro = Select-WSLDistribution
    if (-not $selectedDistro) {
        return
    }

    try {
        $updateCommands = @"
# Update package list
if command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install -y --only-upgrade docker-ce docker-ce-cli containerd.io docker-compose-plugin
elif command -v dnf &> /dev/null; then
    sudo dnf check-update
    sudo dnf update -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
elif command -v pacman &> /dev/null; then
    sudo pacman -Sy
    sudo pacman -S --noconfirm docker
fi

echo "Docker updated in WSL"
"@

        wsl -d $selectedDistro -- bash -c $updateCommands
        Write-Success "Docker updated in WSL ($selectedDistro)"
    } catch {
        Write-Error "Failed to update Docker: $($_.Exception.Message)"
    }
}

# =============================================================================
# BACKUP FUNCTIONS
# =============================================================================

function Create-Backup {
    Write-Step "Creating Configuration Backup"

    # Create backup directory
    if (!(Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }

    # Backup important files
    $filesToBackup = @(
        "$env:USERPROFILE\.bashrc",
        "$env:USERPROFILE\.zshrc",
        "$env:USERPROFILE\.envrc",
        "$env:USERPROFILE\.env"
    )

    foreach ($file in $filesToBackup) {
        Backup-File $file
    }

    # Backup WSL configurations if available
    if (Test-Command "wsl") {
        $selectedDistro = Select-WSLDistribution
        if ($selectedDistro) {
            try {
                # Export WSL distribution
                $exportPath = Join-Path $BackupDir "$selectedDistro.tar"
                wsl --export $selectedDistro $exportPath
                Write-Success "WSL distribution backed up to $exportPath"
            } catch {
                Write-Warning "Failed to backup WSL distribution: $($_.Exception.Message)"
            }
        }
    }

    Write-Success "Backup completed in $BackupDir"
}

# =============================================================================
# DOCKER CONTEXT FUNCTIONS
# =============================================================================

function Setup-DockerContext {
    Write-Step "Setting up Docker Context"

    if (!(Test-Command "wsl")) {
        Write-Warning "WSL not available for Docker context setup"
        return
    }

    $selectedDistro = Select-WSLDistribution
    if (-not $selectedDistro) {
        return
    }

    try {
        # Check if Docker is running in WSL
        $dockerCheck = wsl -d $selectedDistro -- docker --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Docker not available in WSL distribution $selectedDistro"
            return
        }

        # Create Docker context for WSL
        $contextName = "wsl-$selectedDistro"
        $dockerHost = "unix:///mnt/wsl/$selectedDistro/var/run/docker.sock"

        # Check if context already exists
        $existingContexts = docker context ls --format "{{.Name}}" 2>$null
        if ($existingContexts -and $existingContexts -contains $contextName) {
            Write-Success "Docker context '$contextName' already exists"
        } else {
            # Create new context
            docker context create $contextName --docker "host=$dockerHost" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Created Docker context '$contextName'"
            } else {
                Write-Warning "Failed to create Docker context"
            }
        }

        # Set as default context
        docker context use $contextName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Set '$contextName' as default Docker context"
        }

    } catch {
        Write-Error "Failed to setup Docker context: $($_.Exception.Message)"
    }
}

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

function Setup-Environment {
    Write-Step "Setting up Project Environment"

    # Create .envrc if it doesn't exist
    if (!(Test-Path ".envrc")) {
        Write-Host "Creating .envrc file..."
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

echo "✅ Environment loaded!"
"@

        $envrcContent | Out-File -FilePath ".envrc" -Encoding UTF8
        Write-Success ".envrc created"
    } else {
        Write-Success ".envrc already exists"
    }

    # Create .env if it doesn't exist
    if (!(Test-Path ".env")) {
        # Find config directory dynamically
        $configDir = Get-ChildItem -Directory | Where-Object { Test-Path "$($_.Name)\.env.example" } | Select-Object -First 1

        if ($configDir) {
            Write-Host "Creating .env from $($configDir.Name)\.env.example..."
            Copy-Item "$($configDir.Name)\.env.example" ".env"
            Write-Success ".env created - please update with your values"
        } else {
            Write-Warning "No .env.example found - create .env manually"
        }
    } else {
        Write-Success ".env already exists (preserved existing file)"
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

function Show-Help {
    Write-Host "Windows WSL + Docker Development Setup" -ForegroundColor $White
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor $White
    Write-Host "  .\setup-windows-wsl.ps1 [options]" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor $White
    Write-Host "  -InstallWSL       Install WSL2" -ForegroundColor $Cyan
    Write-Host "  -InstallDocker    Install Docker in WSL" -ForegroundColor $Cyan
    Write-Host "  -SetupEnvironment Setup project environment files" -ForegroundColor $Cyan
    Write-Host "  -WSLDistro <name> Specify WSL distribution to use" -ForegroundColor $Cyan
    Write-Host "  -Uninstall        Uninstall WSL and Docker" -ForegroundColor $Cyan
    Write-Host "  -Update          Update Docker in WSL" -ForegroundColor $Cyan
    Write-Host "  -Backup          Create configuration backup" -ForegroundColor $Cyan
    Write-Host "  -Verify          Verify all installations" -ForegroundColor $Cyan
    Write-Host "  -Help            Show this help message" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor $White
    Write-Host "  .\setup-windows-wsl.ps1 -InstallWSL -InstallDocker" -ForegroundColor $Cyan
    Write-Host "  .\setup-windows-wsl.ps1 -WSLDistro Ubuntu-22.04 -InstallDocker" -ForegroundColor $Cyan
    Write-Host "  .\setup-windows-wsl.ps1 -Verify" -ForegroundColor $Cyan
    Write-Host "  .\setup-windows-wsl.ps1 -Backup" -ForegroundColor $Cyan
    Write-Host ""
}

# Main execution
Write-Host "🚀 Windows WSL + Docker Development Setup" -ForegroundColor $Green
Write-Host "══════════════════════════════════════════" -ForegroundColor $White
Write-Host ""

if ($Help) {
    Show-Help
    exit 0
}

# Check for admin rights if needed
if (($InstallWSL -or $Uninstall) -and !(Test-Admin)) {
    Write-Error "Administrator privileges required for WSL installation/uninstallation"
    Write-Host "Please run PowerShell as Administrator and try again"
    exit 1
}

# Create backup if requested
if ($Backup) {
    Create-Backup
    Write-Host ""
}

# Handle uninstall
if ($Uninstall) {
    Uninstall-WSL
    Write-Host ""
    Uninstall-Docker
    Write-Host ""
    Write-Success "Uninstallation completed"
    exit 0
}

# Handle update
if ($Update) {
    Update-Docker
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
if ($InstallWSL) {
    Install-WSL
    Write-Host ""
}

if ($InstallDocker) {
    Install-Docker
    Write-Host ""
    # Setup Docker context after installation
    Setup-DockerContext
    Write-Host ""
}

# Always setup WSL distribution if WSL is available
if (Test-Command "wsl") {
    Setup-WSLDistribution
    Write-Host ""
}

if ($SetupEnvironment) {
    Setup-Environment
    Write-Host ""
}

# Final instructions
Write-Host "🎉 Setup Complete!" -ForegroundColor $Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor $White
Write-Host "1. Restart your computer (if WSL was just installed)" -ForegroundColor $Cyan
Write-Host "2. Open WSL terminal: wsl" -ForegroundColor $Cyan
Write-Host "3. In WSL, run: direnv allow" -ForegroundColor $Cyan
Write-Host "4. Update .env with your configuration" -ForegroundColor $Cyan
Write-Host "5. Test Docker: docker --version" -ForegroundColor $Cyan
Write-Host ""
Write-Host "🔧 Useful Commands:" -ForegroundColor $White
Write-Host "• Open WSL: wsl" -ForegroundColor $Cyan
Write-Host "• List WSL distros: wsl -l -v" -ForegroundColor $Cyan
Write-Host "• Set default distro: wsl -s <distro-name>" -ForegroundColor $Cyan
Write-Host "• Docker: docker --version (in WSL)" -ForegroundColor $Cyan
Write-Host "• Docker Compose: docker compose version (in WSL)" -ForegroundColor $Cyan
Write-Host "• Direnv: direnv --version" -ForegroundColor $Cyan
Write-Host "• Switch Docker context: docker context use wsl-<distro>" -ForegroundColor $Cyan
Write-Host ""
Write-Host "🔧 Script Options:" -ForegroundColor $White
Write-Host "• Verify installations: .\setup-windows-wsl.ps1 -Verify" -ForegroundColor $Cyan
Write-Host "• Create backup: .\setup-windows-wsl.ps1 -Backup" -ForegroundColor $Cyan
Write-Host "• Update Docker: .\setup-windows-wsl.ps1 -Update" -ForegroundColor $Cyan
Write-Host "• Uninstall all: .\setup-windows-wsl.ps1 -Uninstall" -ForegroundColor $Cyan
Write-Host "• Specify distro: .\setup-windows-wsl.ps1 -WSLDistro Ubuntu-22.04 -InstallDocker" -ForegroundColor $Cyan
Write-Host ""
Write-Host "📝 Notes:" -ForegroundColor $White
Write-Host "• Docker runs inside WSL, not Docker Desktop" -ForegroundColor $Yellow
Write-Host "• Script auto-detects WSL distribution and package manager" -ForegroundColor $Yellow
Write-Host "• Docker contexts are automatically configured for WSL integration" -ForegroundColor $Yellow
Write-Host "• Backups are saved to: $BackupDir" -ForegroundColor $Yellow
Write-Host "• For help, see: 00_DOCS/environment-setup.md" -ForegroundColor $White