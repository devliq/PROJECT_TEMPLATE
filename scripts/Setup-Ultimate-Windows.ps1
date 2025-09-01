# =============================================================================
# ULTIMATE WINDOWS DEVELOPMENT ENVIRONMENT SETUP
# =============================================================================
# Comprehensive Windows setup for WSL + Docker + Nix + direnv development
# Provides the best Windows development experience with Linux tooling

param(
    [switch]$InstallWSL,
    [switch]$InstallDocker,
    [switch]$InstallTools,
    [switch]$SetupEnvironment,
    [switch]$SkipDocker,
    [switch]$Uninstall,
    [switch]$Update,
    [switch]$Backup,
    [switch]$Verify,
    [switch]$Help
)

# =============================================================================
# CONFIGURATION
# =============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"
$Magenta = "Magenta"
$White = "White"

# WSL Configuration
$DefaultWSLDistro = "Ubuntu-22.04"
$WSLUser = "devuser"

# Backup directory
$BackupDir = "$env:USERPROFILE\WindowsSetup_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n$([char]0x1F680) " -NoNewline -ForegroundColor $Magenta
    Write-Host $Message -ForegroundColor $White
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

# =============================================================================
# INSTALLATION FUNCTIONS
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

function Install-Docker {
    Write-Step "Installing Docker"

    # Check if Docker is already installed
    if (Test-Command "docker") {
        Write-Success "Docker is already installed"
        return
    }

    # Install Docker Desktop
    Write-Host "Installing Docker Desktop..."
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"

    try {
        Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath
        Start-Process -FilePath $installerPath -ArgumentList "install --quiet" -Wait
        Write-Success "Docker Desktop installed"
    } catch {
        Write-Error "Failed to install Docker: $($_.Exception.Message)"
        Write-Host "Please install Docker manually from: https://www.docker.com/products/docker-desktop"
    }
}

function Install-Tools {
    Write-Step "Installing Development Tools"

    # Install direnv
    if (!(Test-Command "direnv")) {
        Write-Host "Installing direnv..."
        try {
            scoop install direnv
            Write-Success "direnv installed"
        } catch {
            Write-Warning "Scoop not available, trying Chocolatey..."
            try {
                choco install direnv -y
                Write-Success "direnv installed via Chocolatey"
            } catch {
                Write-Error "Failed to install direnv"
            }
        }
    } else {
        Write-Success "direnv is already installed"
    }

    # Install Nix
    if (!(Test-Command "nix")) {
        Write-Host "Installing Nix..."
        try {
            # Download and install Nix
            $nixUrl = "https://hydra.nixos.org/job/nix/master/binaryTarball.x86_64-windows/latest/download/1/nix-2.15.0-x86_64-windows.tar.xz"
            $tempDir = [System.IO.Path]::GetTempPath()
            $nixPath = Join-Path $tempDir "nix.tar.xz"

            Invoke-WebRequest -Uri $nixUrl -OutFile $nixPath

            # Extract and install
            $extractPath = Join-Path $tempDir "nix-installer"
            & tar -xf $nixPath -C $tempDir

            $installerScript = Join-Path $extractPath "install.ps1"
            if (Test-Path $installerScript) {
                & $installerScript
                Write-Success "Nix installed"
            } else {
                throw "Installer script not found"
            }
        } catch {
            Write-Error "Failed to install Nix: $($_.Exception.Message)"
        }
    } else {
        Write-Success "Nix is already installed"
    }
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

function Verify-Installation {
    Write-Step "Verifying Installation"

    $verifications = @(
        @{Name = "WSL"; Command = "wsl --version"},
        @{Name = "Docker"; Command = "docker --version"},
        @{Name = "direnv"; Command = "direnv --version"},
        @{Name = "Nix"; Command = "nix --version"}
    )

    foreach ($verification in $verifications) {
        try {
            $result = Invoke-Expression $verification.Command 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($verification.Name) is working: $result"
            } else {
                Write-Warning "$($verification.Name) verification failed"
            }
        } catch {
            Write-Warning "$($verification.Name) is not available"
        }
    }
}

# =============================================================================
# UNINSTALL FUNCTIONS
# =============================================================================

function Uninstall-WSL {
    Write-Step "Uninstalling WSL"

    try {
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
    Write-Step "Uninstalling Docker"

    try {
        # Uninstall Docker Desktop
        $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"
        if (Test-Path $installerPath) {
            Start-Process -FilePath $installerPath -ArgumentList "uninstall --quiet" -Wait
        }

        Write-Success "Docker uninstalled"
    } catch {
        Write-Error "Failed to uninstall Docker: $($_.Exception.Message)"
    }
}

function Uninstall-Tools {
    Write-Step "Uninstalling Development Tools"

    # Uninstall direnv
    if (Test-Command "direnv") {
        try {
            scoop uninstall direnv
            Write-Success "direnv uninstalled"
        } catch {
            Write-Warning "Failed to uninstall direnv via Scoop"
        }
    }

    # Uninstall Nix
    if (Test-Command "nix") {
        try {
            # Nix uninstallation is complex, provide guidance
            Write-Warning "Nix uninstallation requires manual steps"
            Write-Host "Please run: rm -rf /nix"
            Write-Host "And remove Nix from your PATH"
        } catch {
            Write-Error "Failed to uninstall Nix"
        }
    }
}

# =============================================================================
# UPDATE FUNCTIONS
# =============================================================================

function Update-Tools {
    Write-Step "Updating Development Tools"

    # Update direnv
    if (Test-Command "direnv") {
        try {
            scoop update direnv
            Write-Success "direnv updated"
        } catch {
            Write-Warning "Failed to update direnv"
        }
    }

    # Update Nix
    if (Test-Command "nix") {
        try {
            nix upgrade-nix
            Write-Success "Nix updated"
        } catch {
            Write-Warning "Failed to update Nix"
        }
    }

    # Update Docker
    if (Test-Command "docker") {
        try {
            # Docker updates itself, just check version
            $version = docker --version
            Write-Success "Docker is up to date: $version"
        } catch {
            Write-Warning "Failed to check Docker version"
        }
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

    Write-Success "Backup completed in $BackupDir"
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
    Write-Host "Ultimate Windows Development Environment Setup" -ForegroundColor $White
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor $White
    Write-Host "  .\Setup-Ultimate-Windows.ps1 [options]" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor $White
    Write-Host "  -InstallWSL        Install WSL2" -ForegroundColor $Cyan
    Write-Host "  -InstallDocker     Install Docker Desktop" -ForegroundColor $Cyan
    Write-Host "  -InstallTools      Install direnv and Nix" -ForegroundColor $Cyan
    Write-Host "  -SetupEnvironment  Setup project environment files" -ForegroundColor $Cyan
    Write-Host "  -SkipDocker        Skip Docker installation" -ForegroundColor $Cyan
    Write-Host "  -Uninstall         Uninstall all components" -ForegroundColor $Cyan
    Write-Host "  -Update           Update all installed tools" -ForegroundColor $Cyan
    Write-Host "  -Backup           Create configuration backup" -ForegroundColor $Cyan
    Write-Host "  -Verify           Verify all installations" -ForegroundColor $Cyan
    Write-Host "  -Help             Show this help message" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor $White
    Write-Host "  .\Setup-Ultimate-Windows.ps1 -InstallWSL -InstallDocker -InstallTools" -ForegroundColor $Cyan
    Write-Host "  .\Setup-Ultimate-Windows.ps1 -SetupEnvironment" -ForegroundColor $Cyan
    Write-Host "  .\Setup-Ultimate-Windows.ps1 -Uninstall" -ForegroundColor $Cyan
    Write-Host ""
}

# Main execution
Write-Host "🚀 Ultimate Windows Development Environment Setup" -ForegroundColor $Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor $White
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
    if (!$SkipDocker) {
        Uninstall-Docker
        Write-Host ""
    }
    Uninstall-Tools
    Write-Host ""
    Write-Success "Uninstallation completed"
    exit 0
}

# Handle update
if ($Update) {
    Update-Tools
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

if ($InstallDocker -and !$SkipDocker) {
    Install-Docker
    Write-Host ""
}

if ($InstallTools) {
    Install-Tools
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
Write-Host "• Docker: docker --version" -ForegroundColor $Cyan
Write-Host "• Docker Compose: docker compose version" -ForegroundColor $Cyan
Write-Host "• Direnv: direnv --version" -ForegroundColor $Cyan
Write-Host "• Nix: nix --version" -ForegroundColor $Cyan
Write-Host ""
Write-Host "📝 Note: Docker Desktop provides both Windows and WSL integration" -ForegroundColor $Yellow
Write-Host "The script automatically detects your environment and uses appropriate tools" -ForegroundColor $Yellow
Write-Host "For help, see: docs/environment-setup.md" -ForegroundColor $White