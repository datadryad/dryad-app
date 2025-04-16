#!/bin/bash

SERVICE_NAME="puma"
CPU_LIMIT=90.0
MAX_STRIKES=5
STRIKE_FILE="/tmp/puma_cpu_strikes"

# Get Puma's main PID
MAIN_PID=$(systemctl show -p MainPID --value "$SERVICE_NAME")

if [[ "$MAIN_PID" -eq 0 ]]; then
  echo "$(date) - Puma is not running."
  exit 1
fi

# Get all Puma-related PIDs (main + children)
PIDS=$(pgrep -P "$MAIN_PID")
PIDS="$MAIN_PID $PIDS"

# Calculate total CPU usage
TOTAL_CPU=0
for PID in $PIDS; do
  CPU=$(ps -p "$PID" -o %cpu= | awk '{print $1}')
  TOTAL_CPU=$(echo "$TOTAL_CPU + $CPU" | bc)
done

# Read existing strike count (or default to 0)
STRIKES=$(cat "$STRIKE_FILE" 2>/dev/null || echo 0)

# Compare and update strike logic
if (( $(echo "$TOTAL_CPU > $CPU_LIMIT" | bc -l) )); then
  STRIKES=$((STRIKES + 1))
  echo "$(date) - High CPU: $TOTAL_CPU%. Strike $STRIKES/$MAX_STRIKES."
else
  STRIKES=0
  echo "$(date) - CPU back to normal: $TOTAL_CPU%. Strikes reset."
fi

echo "$STRIKES" > "$STRIKE_FILE"

# Restart if threshold hit
if [[ "$STRIKES" -ge "$MAX_STRIKES" ]]; then
  echo "$(date) - Restarting Puma due to sustained high CPU..."
  sudo systemctl restart "$SERVICE_NAME"
  echo 0 > "$STRIKE_FILE"
fi
