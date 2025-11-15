#!/bin/bash
# View ROFL app logs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NODE_DIR="$PROJECT_ROOT/node"
LOG_FILE="$NODE_DIR/data/node.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found at $LOG_FILE"
    echo "Make sure the node has been started at least once."
    exit 1
fi

# Check if an app ID was provided
APP_ID="${1:-}"

if [ -z "$APP_ID" ]; then
    echo "Usage: $0 <rofl-app-id>"
    echo ""
    echo "Example: $0 rofl1qrqw99h0f7az3hwt2cl7yeew3wtz0fxunu7luyfg"
    echo ""
    echo "Common ROFL app IDs:"
    echo "  Scheduler: rofl.rofl1qrqw99h0f7az3hwt2cl7yeew3wtz0fxunu7luyfg"
    echo ""
    echo "To view all logs: tail -f $LOG_FILE"
    exit 1
fi

echo "==> Viewing logs for ROFL app: $APP_ID"
echo "    Press Ctrl+C to exit"
echo ""

# Follow logs for the specified app ID
tail -f "$LOG_FILE" | grep --line-buffered "$APP_ID" | while read -r line; do
    # Try to parse as JSON and extract msg field
    if echo "$line" | jq -e . >/dev/null 2>&1; then
        echo "$line" | jq -r '.msg'
    else
        echo "$line"
    fi
done
