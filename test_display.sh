D#!/bin/bash

# Test script to debug display_usage_info function

WINDOWS_CONFIG="editor,server,testing,services,git"
TMUX_TYPE="tmux"
SESSION_NAME="test-session"
TMUX_CMD="tmux"

display_usage_info() {
    echo ""
    echo "📋 Workspace Layout:"
    local window_index=0
    IFS=',' read -ra WINDOWS <<< "$WINDOWS_CONFIG"

    echo "DEBUG: WINDOWS_CONFIG='$WINDOWS_CONFIG'"
    echo "DEBUG: Array length: ${#WINDOWS[@]}"

    # Display all windows
    for win in "${WINDOWS[@]}"; do
        echo "DEBUG: Processing '$win'"
        # Trim whitespace
        win="${win#"${win%%[![:space:]]*}"}"
        win="${win%"${win##*[![:space:]]}"}"
        echo "  $window_index: $win"
        ((window_index++))
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

echo "Testing display_usage_info function..."
display_usage_info