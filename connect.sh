#!/bin/bash

# ==============================================================================
#  connect.sh
#
#  This script automates the process of:
#  1. Stopping the old ngrok instance started by this script (if any).
#  2. Starting a new ngrok HTTP tunnel on port 2009.
#  3. Using the ngrok API to get the public URL.
#  4. Saving the URL to a file named 'connected_info.log'.
#  5. Committing the file to Git with a timestamped message.
#  6. Pushing the commit to the 'origin' remote.
# ==============================================================================

set -euo pipefail

NGROK_PORT="2009"
NGROK_API_HOST="127.0.0.1"
NGROK_API_PORT="4042"
NGROK_PID_FILE=".ngrok_http_${NGROK_PORT}.pid"

stop_previous() {
    if [[ -f "$NGROK_PID_FILE" ]]; then
        local old_pid
        old_pid="$(cat "$NGROK_PID_FILE" 2>/dev/null || true)"
        if [[ -n "${old_pid}" ]] && kill -0 "$old_pid" 2>/dev/null; then
            if ps -p "$old_pid" -o cmd= 2>/dev/null | rg -q "ngrok http ${NGROK_PORT}\\b"; then
                echo "INFO: Stopping previous ngrok (pid=${old_pid}) started by this script..."
                kill "$old_pid" 2>/dev/null || true
                sleep 1
            fi
        fi
        rm -f "$NGROK_PID_FILE"
    fi
}

stop_previous

# Start the new ngrok tunnel in the background
echo "INFO: Starting new ngrok tunnel for HTTP (port 2009)..."
ngrok http "$NGROK_PORT" --log=stdout --log-format=logfmt > connecting_details.log &
echo $! > "$NGROK_PID_FILE"

# Give ngrok a moment to establish the connection and start its API
echo "INFO: Waiting for tunnel to establish..."
sleep 4

# Query the local ngrok API to get the tunnel's public URL
# The 'jq' tool is required to parse the JSON response
echo "INFO: Fetching public URL from ngrok API..."
PUBLIC_URL=$(curl -s "http://${NGROK_API_HOST}:${NGROK_API_PORT}/api/tunnels" | jq -r '.tunnels[0].public_url')

# Check if the URL was successfully retrieved
if [[ -z "$PUBLIC_URL" || "$PUBLIC_URL" == "null" ]]; then
    echo "ERROR: Failed to fetch ngrok URL. Please check if ngrok is running correctly."
    stop_previous # Clean up only the ngrok started by this script (if any)
    exit 1
fi

# Save the public URL to the log file
echo "$PUBLIC_URL" > connected_info.log
echo "SUCCESS: Connection info saved to connected_info.log:"
cat connected_info.log
echo ""

# --- Git Automation ---

# Add the updated connection file to the staging area
echo "INFO: Staging connected_info.log for commit..."
git add connected_info.log
git add connecting_details.log

# Create a dynamic commit message with the current time and date
COMMIT_MESSAGE=$(date +"connection info at %T, %d/%m/%Y")
echo "INFO: Committing with message: \"$COMMIT_MESSAGE\""
git commit -m "$COMMIT_MESSAGE"

# Push the commit to the 'origin' remote.
# 'HEAD' refers to the current branch, so you don't need to specify the branch name.
echo "INFO: Pushing changes to origin..."
git push origin HEAD

echo ""
echo "SUCCESS: Script finished. Your connection info is now in your Git repository."
