#!/bin/bash

# ==============================================================================
#  update.sh - HTTP API URL Updater for Linux
#
#  This script pulls the latest ngrok HTTP URL from Git and updates the
#  Claude Desktop configuration file.
# ==============================================================================

set -e  # Exit on error

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOG_FILE="$HOME/.vm-station-new-api/connected_info.log"
CONFIG_FILE="$HOME/.vm-station-new-api/api_url.txt"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"

echo "==================================================================="
echo "  VM Station New API - HTTP URL Update Script (Linux)"
echo "==================================================================="
echo ""

# Pull latest connection info from Git
echo -e "${BLUE}INFO:${NC} Pulling latest connection info from Git..."
cd "$HOME/.vm-station-new-api" || {
    echo -e "${RED}ERROR:${NC} Directory $HOME/.vm-station-new-api not found!"
    echo "Please clone the repository to $HOME/.vm-station-new-api first."
    exit 1
}

git pull || {
    echo -e "${YELLOW}WARNING:${NC} Git pull failed. Using existing local file."
}
echo ""

# Check if log file exists
echo -e "${BLUE}INFO:${NC} Checking for log file at $LOG_FILE..."
if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}ERROR:${NC} The log file was not found!"
    exit 1
fi

if [[ ! -s "$LOG_FILE" ]]; then
    echo -e "${RED}ERROR:${NC} The log file is empty."
    exit 1
fi
echo -e "${GREEN}SUCCESS:${NC} Log file found and is not empty."
echo ""

# Read HTTP API URL
echo -e "${BLUE}INFO:${NC} Reading HTTP API URL..."
API_URL=$(cat "$LOG_FILE" | tr -d '\r\n')

if [[ -z "$API_URL" ]]; then
    echo -e "${RED}ERROR:${NC} Could not read the API URL."
    exit 1
fi

echo -e "${GREEN}SUCCESS:${NC} API URL retrieved:"
echo ""
echo "  $API_URL"
echo ""

# Save the URL to a config file for easy reference
echo "$API_URL" > "$CONFIG_FILE"
echo -e "${BLUE}INFO:${NC} URL saved to $CONFIG_FILE"
echo ""

# Copy to clipboard if xclip is available
if command -v xclip &> /dev/null; then
    echo "$API_URL" | xclip -selection clipboard 2>/dev/null && {
        echo -e "${GREEN}SUCCESS:${NC} URL copied to clipboard!"
    } || {
        echo -e "${YELLOW}INFO:${NC} Clipboard copy failed."
    }
elif command -v xsel &> /dev/null; then
    echo "$API_URL" | xsel --clipboard 2>/dev/null && {
        echo -e "${GREEN}SUCCESS:${NC} URL copied to clipboard!"
    } || {
        echo -e "${YELLOW}INFO:${NC} Clipboard copy failed."
    }
else
    echo -e "${YELLOW}INFO:${NC} Clipboard tools (xclip/xsel) not available."
fi
echo ""

# Update Claude settings.json
echo -e "${BLUE}INFO:${NC} Updating Claude settings..."

# Create .claude directory if it doesn't exist
if [[ ! -d "$CLAUDE_DIR" ]]; then
    mkdir -p "$CLAUDE_DIR"
    echo -e "${BLUE}INFO:${NC} Created .claude directory"
fi

# Check if settings.json exists
if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
    echo -e "${BLUE}INFO:${NC} settings.json not found, creating new file..."
    cat > "$CLAUDE_SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_API_KEY": "your-api-key",
    "ANTHROPIC_BASE_URL": "$API_URL",
    "API_TIMEOUT_MS": "3000000",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gemini-claude-sonnet-4-5-thinking",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "gemini-claude-opus-4-5-thinking",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gemini-claude-sonnet-4-5",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "0",
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  },
  "autoUpdaterStatus": "disabled",
  "model": "sonnet"
}
EOF
    echo -e "${GREEN}SUCCESS:${NC} Created settings.json with API URL: $API_URL"
    echo ""
    echo -e "${YELLOW}IMPORTANT:${NC} Please edit $CLAUDE_SETTINGS"
    echo "            and replace 'your-api-key' with your actual API key."
else
    echo -e "${BLUE}INFO:${NC} Updating existing settings.json..."
    
    # Check if jq is available for JSON manipulation
    if command -v jq &> /dev/null; then
        # Use jq for proper JSON handling
        TEMP_FILE=$(mktemp)
        jq --arg url "$API_URL" '.env.ANTHROPIC_BASE_URL = $url' "$CLAUDE_SETTINGS" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$CLAUDE_SETTINGS"
        echo -e "${GREEN}SUCCESS:${NC} Updated ANTHROPIC_BASE_URL to: $API_URL"
    else
        # Fallback to sed for text replacement
        echo -e "${YELLOW}WARNING:${NC} jq not found, using sed as fallback..."
        sed -i.bak "s|\"ANTHROPIC_BASE_URL\": \".*\"|\"ANTHROPIC_BASE_URL\": \"$API_URL\"|g" "$CLAUDE_SETTINGS"
        rm -f "$CLAUDE_SETTINGS.bak"
        echo -e "${GREEN}SUCCESS:${NC} Updated ANTHROPIC_BASE_URL using sed"
    fi
fi
echo ""

# Success message
echo "==================================================================="
echo ""
echo -e "${GREEN}SUCCESS:${NC} Script finished!"
echo ""
echo "  API URL: $API_URL"
echo ""
echo "  You can now use this URL to access your HTTP API."
echo ""
echo "==================================================================="
