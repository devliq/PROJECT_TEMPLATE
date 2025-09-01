#!/bin/bash

# Development Workspace Setup Script
# Sets up byobu/tmux windows and panes for optimal development workflow

set -euo pipefail  # Exit on any error, undefined variables, or pipe failures

# =============================================================================
# CONFIGURATION
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default configuration
DEFAULT_SESSION_NAME=""
DEFAULT_WINDOWS_CONFIG="editor,server,testing,services,git"
DEFAULT_EDITOR_PANES="file_browser,editor"
DEFAULT_SERVER_PANES="server,logs"
DEFAULT_TESTING_PANES="tests,results"
DEFAULT_SERVICES_PANES="database,docker"
DEFAULT_GIT_PANES="status,log"
DEFAULT_AUTO_ATTACH=true
DEFAULT_KILL_EXISTING=false

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# =============================================================================
# VERSION CHECKING FUNCTIONS
# =============================================================================

check_tmux_version() {
    if ! command -v tmux &> /dev/null && ! command -v byobu &> /dev/null; then
        log_error "Neither tmux nor byobu found"
        return 1
    fi

    local tmux_cmd=""
    if command -v byobu &> /dev/null; then
        tmux_cmd="byobu"
    elif command -v tmux &> /dev/null; then
        tmux_cmd="tmux"
    fi

    local version
    version=$($tmux_cmd -V | sed 's/[^0-9.]*//g')
    local required="2.6"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "tmux/byobu version $version is below required $required"
        return 1
    fi

    log_success "tmux/byobu version: $version"
}

# =============================================================================
# CONFIGURATION FUNCTIONS
# =============================================================================

load_configuration() {
    # Load environment variables safely
    if [ -f ".env" ]; then
        log_info "Loading environment configuration..."
        set -a
        source .env
        set +a
        log_success "Environment variables loaded"
    fi

    # Load workspace configuration
    local config_file="06_CONFIG/workspace.config"
    if [ -f "$config_file" ]; then
        log_info "Loading workspace configuration..."
        source "$config_file"
        log_success "Workspace configuration loaded"
    else
        log_warning "Workspace config not found at $config_file. Using defaults..."
    fi

    # Set defaults for unset variables
    SESSION_NAME=${SESSION_NAME:-$DEFAULT_SESSION_NAME}
    WINDOWS_CONFIG=${WINDOWS_CONFIG:-$DEFAULT_WINDOWS_CONFIG}
    EDITOR_PANES=${EDITOR_PANES:-$DEFAULT_EDITOR_PANES}
    SERVER_PANES=${SERVER_PANES:-$DEFAULT_SERVER_PANES}
    TESTING_PANES=${TESTING_PANES:-$DEFAULT_TESTING_PANES}
    SERVICES_PANES=${SERVICES_PANES:-$DEFAULT_SERVICES_PANES}
    GIT_PANES=${GIT_PANES:-$DEFAULT_GIT_PANES}
    AUTO_ATTACH=${AUTO_ATTACH:-$DEFAULT_AUTO_ATTACH}
    KILL_EXISTING=${KILL_EXISTING:-$DEFAULT_KILL_EXISTING}

    # Generate session name if not provided
    if [ -z "$SESSION_NAME" ]; then
        SESSION_NAME="dev-$(basename "$(pwd)")"
        # Sanitize session name to replace spaces with underscores
        SESSION_NAME=$(echo "$SESSION_NAME" | tr ' ' '_')
    fi
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_environment() {
    log_step "Validating environment..."

    # Check if we're in the right directory
    if [ ! -f "README.MD" ] && [ ! -f "package.json" ] && [ ! -f "pyproject.toml" ] && [ ! -f "Cargo.toml" ]; then
        log_error "Please run this script from a project root directory"
        log_info "Look for README.MD, package.json, pyproject.toml, or Cargo.toml"
        return 1
    fi

    # Check if already in a tmux/byobu session
    if [ -n "${TMUX:-}" ]; then
        log_error "Already inside a tmux/byobu session"
        log_info "Detach from current session first: Ctrl-b + d"
        return 1
    fi

    log_success "Environment validation passed"
}

# =============================================================================
# TERMINAL MULTIPLEXER FUNCTIONS
# =============================================================================

detect_terminal_multiplexer() {
    if command -v byobu &> /dev/null; then
        TMUX_CMD="byobu"
        TMUX_TYPE="byobu"
        TMUX_VERSION=$(byobu -V 2>/dev/null | sed 's/.*byobu \([0-9.]*\).*/\1/' || echo "unknown")
        log_success "Detected byobu (version: $TMUX_VERSION)"
        # Check if byobu is enabled for this user
        if [ ! -d "$HOME/.byobu" ]; then
            log_warning "Byobu is installed but not enabled for this user. Falling back to tmux."
            TMUX_CMD="tmux"
            TMUX_TYPE="tmux"
            TMUX_VERSION=$(tmux -V | sed 's/tmux \([0-9.]*\).*/\1/')
        fi
    elif command -v tmux &> /dev/null; then
        TMUX_CMD="tmux"
        TMUX_TYPE="tmux"
        TMUX_VERSION=$(tmux -V | sed 's/tmux \([0-9.]*\).*/\1/')
        log_success "Detected tmux (version: $TMUX_VERSION)"
    else
        log_error "Neither byobu nor tmux found"
        log_info "Install instructions:"
        log_info "  Ubuntu/Debian: sudo apt install tmux"
        log_info "  CentOS/RHEL: sudo yum install tmux"
        log_info "  macOS: brew install tmux"
        log_info "  Arch: sudo pacman -S tmux"
        return 1
    fi
}

check_existing_session() {
    if $TMUX_CMD has-session -t "$SESSION_NAME" 2>/dev/null; then
        if [ "$KILL_EXISTING" = "true" ]; then
            log_info "Killing existing session: $SESSION_NAME"
            $TMUX_CMD kill-session -t "$SESSION_NAME"
        else
            log_warning "Session '$SESSION_NAME' already exists"
            log_info "Use '$TMUX_CMD attach -t $SESSION_NAME' to attach"
            log_info "Or run with --kill-existing to replace it"
            return 1
        fi
    fi
}

# =============================================================================
# WORKSPACE SETUP FUNCTIONS
# =============================================================================

setup_workspace_layout() {
    log_step "Setting up development workspace with $TMUX_TYPE..."

    # Create new session
    log_info "Creating new session: $SESSION_NAME"
    $TMUX_CMD new-session -d -s "$SESSION_NAME" -n "editor"

    # Wait for session to be created
    sleep 2

    # Verify session was created
    if ! $TMUX_CMD has-session -t "$SESSION_NAME" 2>/dev/null; then
        log_error "Failed to create tmux session"
        return 1
    fi

    # Setup windows based on configuration
    setup_windows

    # Set default window
    $TMUX_CMD select-window -t "$SESSION_NAME:0"

    log_success "Development workspace created successfully"
}

setup_windows() {
    local window_index=0

    # Parse windows configuration
    IFS=',' read -ra WINDOWS <<< "$WINDOWS_CONFIG"

    for window in "${WINDOWS[@]}"; do
        window=$(echo "$window" | xargs)  # Trim whitespace

        case $window in
            "editor")
                setup_editor_window "$window_index"
                ;;
            "server")
                setup_server_window "$window_index"
                ;;
            "testing")
                setup_testing_window "$window_index"
                ;;
            "services")
                setup_services_window "$window_index"
                ;;
            "git")
                setup_git_window "$window_index"
                ;;
            *)
                log_warning "Unknown window type: $window"
                ;;
        esac

        ((window_index++))
    done
}

setup_editor_window() {
    local window_index=$1

    if [ "$window_index" -eq 0 ]; then
        # First window is already created
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "cd '\$\(pwd\)' && clear" C-m
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo '📝 Main Editor Window'" C-m
    else
        $TMUX_CMD new-window -t "$SESSION_NAME:$window_index" -n "editor"
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "cd '\$\(pwd\)' && clear" C-m
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo '📝 Editor Window'" C-m
    fi

    # Setup panes based on configuration
    IFS=',' read -ra PANES <<< "$EDITOR_PANES"
    if [ ${#PANES[@]} -gt 1 ]; then
        # Split window for file browser
        $TMUX_CMD split-window -h -t "$SESSION_NAME:$window_index"
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index.1" "cd '\$\(pwd\)' && ls -la" C-m
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index.1" "echo '📁 File Browser'" C-m
    fi
}

setup_server_window() {
    local window_index=$1

    $TMUX_CMD new-window -t "$SESSION_NAME:$window_index" -n "server"
    $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "cd '\$\(pwd\)' && clear" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo '🚀 Development Server Window'" C-m

    # Setup panes based on configuration
    IFS=',' read -ra PANES <<< "$SERVER_PANES"
    if [ ${#PANES[@]} -gt 1 ]; then
        $TMUX_CMD split-window -v -t "$SESSION_NAME:$window_index"
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index.1" "cd '\$\(pwd\)' && echo '📊 Logs & Monitoring'" C-m
    fi

    # Try to detect and setup common development commands
    if [ -f "package.json" ]; then
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo 'Available commands: npm run dev, npm start'" C-m
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo 'Available commands: python manage.py runserver'" C-m
    fi
}

setup_testing_window() {
    local window_index=$1

    $TMUX_CMD new-window -t "$SESSION_NAME:$window_index" -n "testing"
    $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "cd '\$\(pwd\)' && clear" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo '🧪 Testing & Debugging Window'" C-m

    # Setup panes based on configuration
    IFS=',' read -ra PANES <<< "$TESTING_PANES"
    if [ ${#PANES[@]} -gt 1 ]; then
        $TMUX_CMD split-window -v -t "$SESSION_NAME:$window_index"
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index.1" "cd '\$\(pwd\)' && echo '📈 Test Results'" C-m
    fi

    # Setup test commands
    if [ -f "package.json" ]; then
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo 'Available commands: npm test, npm run test:watch'" C-m
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo 'Available commands: python -m pytest, python -m unittest'" C-m
    fi
}

setup_services_window() {
    local window_index=$1

    $TMUX_CMD new-window -t "$SESSION_NAME:$window_index" -n "services"
    $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "cd '\$\(pwd\)' && clear" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo '🐳 Database & Services Window'" C-m

    # Setup panes based on configuration
    IFS=',' read -ra PANES <<< "$SERVICES_PANES"
    if [ ${#PANES[@]} -gt 1 ]; then
        $TMUX_CMD split-window -v -t "$SESSION_NAME:$window_index"
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index.1" "cd '\$\(pwd\)' && echo '🔧 Docker Services'" C-m
    fi

    # Check for docker-compose
    if [ -f "docker-compose.yml" ]; then
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo 'Available commands: docker-compose up, docker-compose logs'" C-m
    fi
}

setup_git_window() {
    local window_index=$1

    $TMUX_CMD new-window -t "$SESSION_NAME:$window_index" -n "git"
    $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "cd '\$\(pwd\)' && clear" C-m

    if [ -d ".git" ]; then
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "git status" C-m
    else
        $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index" "echo '⚠️  Not a git repository'" C-m
    fi

    # Setup panes based on configuration
    IFS=',' read -ra PANES <<< "$GIT_PANES"
    if [ ${#PANES[@]} -gt 1 ]; then
        $TMUX_CMD split-window -v -t "$SESSION_NAME:$window_index"
        if [ -d ".git" ]; then
            $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index.1" "cd '\$\(pwd\)' && git log --oneline -10" C-m
        else
            $TMUX_CMD send-keys -t "$SESSION_NAME:$window_index.1" "cd '\$\(pwd\)' && echo 'No git history available'" C-m
        fi
    fi
}

# Setup development workspace layout
setup_dev_workspace() {
    log_info "Setting up development workspace with $TMUX_TYPE..."

    # Check if session already exists
    if $TMUX_CMD has-session -t "$SESSION_NAME" 2>/dev/null; then
        log_info "Session '$SESSION_NAME' already exists"
        log_info "Attaching to existing session..."
        attach_session
        return 0
    fi

    # Create new session with first window
    log_info "Creating new session: $SESSION_NAME"
    $TMUX_CMD new-session -d -s "$SESSION_NAME" -n "editor"

    # Wait for session to be created
    sleep 1

    # Verify session was created
    if ! $TMUX_CMD has-session -t "$SESSION_NAME" 2>/dev/null; then
        log_error "Failed to create tmux session"
        return 1
    fi

    # Window 0: Main Editor (split for file browsing and editing)
    log_info "Setting up editor window..."
    $TMUX_CMD send-keys -t "$SESSION_NAME:0" "cd '\$\(pwd\)' && clear" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:0" "echo '📝 Main Editor Window'" C-m

    # Split window vertically for file browser
    $TMUX_CMD split-window -h -t "$SESSION_NAME:0"
    $TMUX_CMD send-keys -t "$SESSION_NAME:0.1" "cd '\$\(pwd\)' && ls -la" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:0.1" "echo '📁 File Browser'" C-m

    # Window 1: Development Server & Commands
    log_info "Setting up server window..."
    $TMUX_CMD new-window -t "$SESSION_NAME:1" -n "server"
    $TMUX_CMD send-keys -t "$SESSION_NAME:1" "cd '\$\(pwd\)' && clear" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:1" "echo '🚀 Development Server Window'" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:1" "echo 'Use: npm run dev'" C-m

    # Split for logs/monitoring
    $TMUX_CMD split-window -v -t "$SESSION_NAME:1"
    $TMUX_CMD send-keys -t "$SESSION_NAME:1.1" "cd '\$\(pwd\)' && echo '📊 Logs & Monitoring'" C-m

    # Window 2: Testing & Debugging
    log_info "Setting up testing window..."
    $TMUX_CMD new-window -t "$SESSION_NAME:2" -n "testing"
    $TMUX_CMD send-keys -t "$SESSION_NAME:2" "cd '\$\(pwd\)' && clear" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:2" "echo '🧪 Testing & Debugging Window'" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:2" "echo 'Use: npm test'" C-m

    # Split for test watching
    $TMUX_CMD split-window -v -t "$SESSION_NAME:2"
    $TMUX_CMD send-keys -t "$SESSION_NAME:2.1" "cd '\$\(pwd\)' && echo '📈 Test Results'" C-m

    # Window 3: Database & Services
    log_info "Setting up services window..."
    $TMUX_CMD new-window -t "$SESSION_NAME:3" -n "services"
    $TMUX_CMD send-keys -t "$SESSION_NAME:3" "cd '\$\(pwd\)' && clear" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:3" "echo '🐳 Database & Services Window'" C-m

    # Split for Docker services
    $TMUX_CMD split-window -v -t "$SESSION_NAME:3"
    $TMUX_CMD send-keys -t "$SESSION_NAME:3.1" "cd '\$\(pwd\)' && echo '🔧 Docker Services'" C-m

    # Window 4: Git & Version Control
    log_info "Setting up git window..."
    $TMUX_CMD new-window -t "$SESSION_NAME:4" -n "git"
    $TMUX_CMD send-keys -t "$SESSION_NAME:4" "cd '\$\(pwd\)' && clear" C-m
    $TMUX_CMD send-keys -t "$SESSION_NAME:4" "git status 2>/dev/null || echo '⚠️  Not a git repository'" C-m

    # Split for git log
    $TMUX_CMD split-window -v -t "$SESSION_NAME:4"
    $TMUX_CMD send-keys -t "$SESSION_NAME:4.1" "cd '\$\(pwd\)' && (git log --oneline -10 2>/dev/null || echo '⚠️  No git history available')" C-m

    # Set default window
    $TMUX_CMD select-window -t "$SESSION_NAME:0"

    log_success "Development workspace created!"
    echo ""
    echo "📋 Workspace Layout:"
    echo "  0: editor    - Main editing (split: files + editor)"
    echo "  1: server    - Development server (split: server + logs)"
    echo "  2: testing   - Testing & debugging (split: tests + results)"
    echo "  3: services  - Database & services (split: db + docker)"
    echo "  4: git       - Version control (split: status + log)"
    echo ""
    echo "🔧 Useful $TMUX_TYPE commands:"
    echo "  Switch windows: Ctrl-b + [0-4]"
    echo "  Switch panes: Ctrl-b + [arrow keys]"
    echo "  Detach: Ctrl-b + d"
    echo "  Reattach: $TMUX_CMD attach -t $SESSION_NAME"
    echo ""
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

verify_workspace_setup() {
    log_step "Verifying workspace setup..."

    local issues=0

    # Check if session exists
    if ! $TMUX_CMD has-session -t "$SESSION_NAME" 2>/dev/null; then
        log_error "Session '$SESSION_NAME' was not created"
        ((issues++))
    fi

    # Check windows
    IFS=',' read -ra WINDOWS <<< "$WINDOWS_CONFIG"
    for window in "${WINDOWS[@]}"; do
        window=$(echo "$window" | xargs)
        if ! $TMUX_CMD list-windows -t "$SESSION_NAME" | grep -q "$window"; then
            log_warning "Window '$window' not found"
        fi
    done

    if [ $issues -eq 0 ]; then
        log_success "Workspace verification passed"
        return 0
    else
        log_error "Workspace verification failed with $issues issues"
        return 1
    fi
}

# =============================================================================
# SESSION MANAGEMENT FUNCTIONS
# =============================================================================

attach_session() {
    if [ -n "${TMUX:-}" ]; then
        log_warning "Already inside a tmux/byobu session"
        log_info "Use Ctrl-b + d to detach, then run this script again"
        return 1
    fi

    log_info "Attaching to development workspace..."
    $TMUX_CMD attach-session -t "$SESSION_NAME"
}

display_usage_info() {
    echo ""
    echo "📋 Workspace Layout:"
    local window_index=0
    IFS=',' read -ra WINDOWS <<< "$WINDOWS_CONFIG" || true

    # Display all windows
    for win in "${WINDOWS[@]}"; do
        # Trim whitespace
        win="${win#"${win%%[![:space:]]*}"}" || true
        win="${win%"${win##*[![:space:]]}"}" || true
        echo "  $window_index: $win"
        ((window_index++)) || true
    done

    echo ""
    echo "🔧 Useful $TMUX_TYPE commands:"
    echo "  Switch windows: Ctrl-b + [0-$((${#WINDOWS[@]} - 1))]"
    echo "  Switch panes: Ctrl-b + [arrow keys]"
    echo "  Detach: Ctrl-b + d"
    echo "  List sessions: $TMUX_CMD list-sessions"
    echo "  Kill session: $TMUX_CMD kill-session -t $SESSION_NAME"
    echo ""
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    log_info "🚀 Setting up Development Workspace"
    echo "══════════════════════════════════════"

    # Load configuration
    load_configuration

    # Validate environment
    validate_environment || exit 1

    # Detect terminal multiplexer
    detect_terminal_multiplexer || exit 1

    # Check version
    check_tmux_version || exit 1

    # Handle existing session (kill if requested, or attach if it exists)
    if $TMUX_CMD has-session -t "$SESSION_NAME" 2>/dev/null; then
        if [ "$KILL_EXISTING" = "true" ]; then
            log_info "Killing existing session: $SESSION_NAME"
            $TMUX_CMD kill-session -t "$SESSION_NAME"
        else
            log_info "Session '$SESSION_NAME' already exists, attaching automatically..."
            display_usage_info
            attach_session
            exit 0
        fi
    fi

    # Setup workspace
    setup_workspace_layout || exit 1

    # Verify setup
    verify_workspace_setup

    # Display usage information
    display_usage_info

    # Attach to session
    attach_session
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --session)
                SESSION_NAME="$2"
                shift 2
                ;;
            --windows)
                WINDOWS_CONFIG="$2"
                shift 2
                ;;
            --no-attach)
                AUTO_ATTACH=false
                shift
                ;;
            --kill-existing)
                KILL_EXISTING=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Development Workspace Setup Script"
                echo ""
                echo "Options:"
                echo "  --session NAME     Session name (default: dev-<project-name>)"
                echo "  --windows LIST     Comma-separated list of windows"
                echo "                     (default: editor,server,testing,services,git)"
                echo "  --no-attach        Don't auto-attach to session"
                echo "  --kill-existing    Kill existing session if it exists"
                echo "  --help             Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --session my-project"
                echo "  $0 --windows editor,server,git --no-attach"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

# Parse command line arguments
parse_arguments "$@"

# Run main function
main