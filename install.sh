#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Initialize logging
LOG_FILE="$SCRIPT_DIR/arp_sweep_install.log"
echo "INIT Arp_Sweep Installation - $(date)" > "$LOG_FILE"

# Step 1: Check if the required files exist
if [[ ! -f $SCRIPT_DIR/arp_sweep.sh ]]; then
  echo "Error: arp_sweep.sh not found!" | tee -a "$LOG_FILE"
  exit 1
fi

if [[ ! -f $SCRIPT_DIR/arp_sweep.service ]]; then
  echo "Error: arp_sweep.service not found!" | tee -a "$LOG_FILE"
  exit 1
fi

# Step 2: Copy arp_sweep.sh to the system's bin directory
echo "Copying arp_sweep.sh to /usr/local/bin..." | tee -a "$LOG_FILE"
cp $SCRIPT_DIR/arp_sweep.sh /usr/local/bin/arp_sweep.sh
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to copy arp_sweep.sh" | tee -a "$LOG_FILE"
  exit 1
fi

# Step 3: Make arp_sweep.sh executable
echo "Setting execute permissions for arp_sweep.sh..." | tee -a "$LOG_FILE"
sudo chmod +x /usr/local/bin/arp_sweep.sh
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to set execute permissions for arp_sweep.sh" | tee -a "$LOG_FILE"
  exit 1
fi

# Step 4: Copy arp_sweep.service to systemd directory
echo "Copying arp_sweep.service to /etc/systemd/system/..." | tee -a "$LOG_FILE"
cp $SCRIPT_DIR/arp_sweep.service /etc/systemd/system/arp-sweep.service
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to copy arp_sweep.service" | tee -a "$LOG_FILE"
  exit 1
fi

# Step 5: Reload systemd, enable, and start the service
echo "Reloading systemd daemon..." | tee -a "$LOG_FILE"
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to reload systemd daemon" | tee -a "$LOG_FILE"
  exit 1
fi

echo "Enabling arp-sweep service..." | tee -a "$LOG_FILE"
sudo systemctl enable arp-sweep.service
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to enable arp-sweep service" | tee -a "$LOG_FILE"
  exit 1
fi

echo "Starting arp-sweep service..." | tee -a "$LOG_FILE"
sudo systemctl start arp-sweep.service
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to start arp-sweep service" | tee -a "$LOG_FILE"
  exit 1
fi

# Final status
echo "Arp_Sweep installation and service setup completed successfully!" | tee -a "$LOG_FILE"
