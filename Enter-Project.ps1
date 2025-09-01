# Project Entry Script for PowerShell
# Automatically enters WSL and sets up the development environment

param(
    [switch]$NoWorkspace,
    [switch]$Help,
    [switch]$Debug
)

if ($Help) {
    Write-Host "🚀 Project Entry Script" -ForegroundColor Green
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor White
    Write-Host "  .\Enter-Project.ps1 [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor White
    Write-Host "  -NoWorkspace    Skip development workspace setup" -ForegroundColor Cyan
    Write-Host "  -Debug         Show debug information" -ForegroundColor Cyan
    Write-Host "  -Help          Show this help message" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor White
    Write-Host "  Automatically enters WSL, navigates to project directory," -ForegroundColor White
    Write-Host "  and sets up the complete development environment." -ForegroundColor White
    Write-Host ""
    exit 0
}

Write-Host "🚀 Entering Development Environment" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor White

# Check if WSL is available
try {
    $wslDistros = wsl -l -q 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "WSL not available"
    }
} catch {
    Write-Host "❌ WSL is not installed or not available" -ForegroundColor Red
    Write-Host "Please run: wsl --install" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Get the current Windows directory and convert to WSL path
$winDir = Get-Location
$wslDir = $winDir.Path -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/'

# Convert drive letter to lowercase for WSL
$driveLetter = $wslDir.Substring(5, 1).ToLower()
$wslDir = $wslDir -replace '^/mnt/[A-Z]', "/mnt/$driveLetter"

Write-Host "📁 Project directory: $winDir" -ForegroundColor Blue
Write-Host "🐧 WSL directory: $wslDir" -ForegroundColor Blue

# Get available WSL distributions
Write-Host "🔍 Checking WSL distributions..." -ForegroundColor Gray
$distros = wsl -l -q 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ WSL is not available" -ForegroundColor Red
    Write-Host "Please install WSL first" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Available distributions:" -ForegroundColor Gray
wsl -l -q | ForEach-Object {
    $trimmed = $_.Trim()
    Write-Host "  • $trimmed" -ForegroundColor Gray
}

# Try to get default distribution (marked with *)
$defaultDistro = wsl -l -v 2>$null | Where-Object { $_ -match '\*' } | ForEach-Object {
    $_.Trim().Split()[1]
}

# If no default found, try to find kali-linux specifically
if (-not $defaultDistro) {
    $kaliExists = wsl -l -q 2>$null | Where-Object { $_ -match "kali" }
    if ($kaliExists) {
        $defaultDistro = ($kaliExists | Select-Object -First 1).Trim()
        Write-Host "🐧 Found Kali Linux: $defaultDistro" -ForegroundColor Blue
    }
}

# If still no distro, use first available
if (-not $defaultDistro) {
    $firstDistro = ($distros | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -First 1).Trim()
    if ($firstDistro) {
        $defaultDistro = $firstDistro
        Write-Host "🐧 Using first available: $defaultDistro" -ForegroundColor Blue
    }
}

# Final fallback: use default WSL without specifying distribution
if (-not $defaultDistro) {
    Write-Host "🐧 Using default WSL distribution" -ForegroundColor Blue
    $defaultDistro = $null
} else {
    Write-Host "🐧 Target distribution: $defaultDistro" -ForegroundColor Blue
}

# Prepare WSL commands as single line like batch file
$distroName = if ($defaultDistro) { $defaultDistro } else { "default" }
$wslCommands = "cd '$wslDir' && echo '🐧 Welcome to WSL ($distroName)!' && echo '📁 Successfully entered project directory' && echo '🔧 Environment will load automatically via direnv' && echo '' && echo '💡 Available commands:' && echo '  • ./scripts/setup-dev-workspace.sh  - Create development workspace' && echo '  • npm run dev                        - Start development server' && echo '  • npm test                          - Run tests' && echo '  • docker compose up -d              - Start services' && echo '' && echo '🎯 Your development environment is ready!' && echo ''"

if (-not $NoWorkspace) {
    $wslCommands += " && if [ -f './scripts/setup-dev-workspace.sh' ]; then echo '🔄 Setting up development workspace...'; ./scripts/setup-dev-workspace.sh; else echo '⚠️  Workspace setup script not found. Run manually: ./scripts/setup-dev-workspace.sh'; fi"
}

$wslCommands += " && echo '📂 Returning to project directory...' && cd '$wslDir' && exec bash --rcfile <(echo 'cd '\''$wslDir'\''; source ~/.bashrc')"

Write-Host ""
Write-Host "🔄 Entering WSL and setting up environment..." -ForegroundColor Yellow
Write-Host ""

# Enter WSL with the prepared commands
Write-Host "🔄 Entering WSL..." -ForegroundColor Yellow

if ($Debug) {
    Write-Host "Debug: defaultDistro = $defaultDistro" -ForegroundColor Gray
    Write-Host "Debug: wslDir = $wslDir" -ForegroundColor Gray
}

# Check if kali-linux is available, otherwise use detected distro
if ($defaultDistro -notmatch "kali") {
    $kaliExists = wsl -l -q 2>$null | Where-Object { $_ -match "kali" }
    if ($kaliExists) {
        $defaultDistro = ($kaliExists | Select-Object -First 1).Trim()
        Write-Host "🐧 Using Kali Linux: $defaultDistro" -ForegroundColor Blue
    }
}

# Execute WSL command directly with proper argument handling
try {
    $bashCommand = "cd '$wslDir' && echo 'Welcome to WSL!' && echo 'Project directory: $wslDir' && echo 'Setup complete - starting shell...' && exec bash --login"

    if ($defaultDistro -and $defaultDistro.Trim() -ne "") {
        if ($Debug) {
            Write-Host "Executing: wsl -d $defaultDistro -- bash -c '$bashCommand'" -ForegroundColor Gray
        }
        & wsl -d $defaultDistro -- bash -c $bashCommand
    } else {
        Write-Host "⚠️ No specific WSL distribution found, using default" -ForegroundColor Yellow
        if ($Debug) {
            Write-Host "Executing: wsl -- bash -c '$bashCommand'" -ForegroundColor Gray
        }
        & wsl -- bash -c $bashCommand
    }
} catch {
    Write-Host "❌ Failed to enter WSL" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    # Fallback
    if ($defaultDistro -and $defaultDistro.Trim() -ne "") {
        wsl -d $defaultDistro
    } else {
        wsl
    }
}

Write-Host ""
Write-Host "💡 To return to this setup later, run: .\Enter-Project.ps1" -ForegroundColor Cyan