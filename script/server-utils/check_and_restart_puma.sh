#!/bin/bash

SERVICE_NAME="puma"
CPU_LIMIT=95.0
MAX_STRIKES=5
STRIKE_FILE="/tmp/puma_cpu_strikes"

# Get Puma's main PID
MAIN_PID=$(systemctl show -p MainPID --value "$SERVICE_NAME")

if [[ "$MAIN_PID" -eq 0 ]]; then
  echo "$(date) - Puma is not running."
  exit 1
fi

#TOTAL_CPU=$(top -b -n1 | grep '[b]undle' | awk 'NR==1 {print $9}')

while [[ -z "$max_pid" || -z "$max_cpu" || -z "$total_cpu" ]]; do
  read max_pid max_cpu total_cpu< <(
    top -b -H -p "$MAIN_PID" -n 1 | awk -v main_pid="$MAIN_PID" '
      /^[ ]*[0-9]/ {
        pid=$1; cpu=$9;
        if (tid != main_pid) {
          total += cpu
          if (cpu > max_cpu) {
            max_cpu = cpu;
            max_pid = pid;
          }
        }
      }
      END { if (max_pid != "") print max_pid, max_cpu, total }
    '
  )

  # Optional: small delay to avoid spamming CPU
  sleep 0.5
done

# Read existing strike count (or default to 0)
STRIKES=$(cat "$STRIKE_FILE" 2>/dev/null || echo 0)

# Compare and update strike logic
if (( $(echo "$max_cpu > $CPU_LIMIT" | bc -l) )); then
  STRIKES=$((STRIKES + 1))
  echo "$(date) - High CPU: max $max_cpu% on PID: $max_pid of $total_cpu% total. Strike $STRIKES/$MAX_STRIKES."
else
  STRIKES=0
  echo "$(date) - CPU back to normal: max $max_cpu% on PID: $max_pid of $total_cpu% total. Strikes reset."
fi

echo "$STRIKES" > "$STRIKE_FILE"

# Restart if threshold hit
if [[ "$STRIKES" -ge "$MAX_STRIKES" ]]; then
  echo "$(date) - Restarting Puma due to sustained high CPU..."
  sudo systemctl restart "$SERVICE_NAME"
  echo 0 > "$STRIKE_FILE"
fi
