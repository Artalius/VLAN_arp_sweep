#!/bin/bash

# ===============================================================
# ARP Sweep Script
# Performs dynamic (CIDR-derived) ARP scans
# Intended to run as a service (no arguments required)
# ===============================================================

LOG_FILE="/var/log/arp_sweep.log"
echo "Starting ARP Sweep - $(date)" > "$LOG_FILE"

# Maximum concurrent arping processes before wait
MAX_PARALLEL_PROCESSES=86
current_processes=0

# ---------------------------------------------------------------
# Utility: Get Default Network Interface
# ---------------------------------------------------------------
get_default_interface() {
    ip route | awk '/default/ {print $5; exit}'
}

# ---------------------------------------------------------------
# Utility: Convert IP <-> Integer
# ---------------------------------------------------------------
ip2int() {
    local IFS=.
    read -r i1 i2 i3 i4 <<< "$1"
    echo $(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
}

int2ip() {
    local ip=$1
    echo "$(( (ip >> 24) & 255 )).$(( (ip >> 16) & 255 )).$(( (ip >> 8) & 255 )).$(( ip & 255 ))"
}

# ---------------------------------------------------------------
# Function: Perform ARP sweep over calculated CIDR host range
# ---------------------------------------------------------------
dynamic_arp_sweep() {
    local iface=$1

    echo "==========================" | tee -a "$LOG_FILE"
    echo "Sweep Type: Dynamic | Interface: $iface | Time: $(date)" | tee -a "$LOG_FILE"
    echo "==========================" | tee -a "$LOG_FILE"
    echo "Starting dynamic ARP sweep..." | tee -a "$LOG_FILE"


    # Capture start time
    start_time=$(date +%s)

    cidr=$(ip -o -f inet addr show "$iface" | awk '{print $4}')
    if [[ -z "$cidr" ]]; then
        echo "Error: CIDR not found for $iface" | tee -a "$LOG_FILE"
        return 1
    fi

    ip_base=$(echo "$cidr" | cut -d/ -f1)
    prefix=$(echo "$cidr" | cut -d/ -f2)
    ip_int=$(ip2int "$ip_base")
    netmask=$(( 0xFFFFFFFF << (32 - prefix) & 0xFFFFFFFF ))
    network=$(( ip_int & netmask ))
    start=$((network + 1))
    end=$((network + (2 ** (32 - prefix)) - 2))

    echo "CIDR: $cidr (Base: $ip_base /$prefix)" | tee -a "$LOG_FILE"
    echo "Scanning dynamic range: $(int2ip $start) to $(int2ip $end)" | tee -a "$LOG_FILE"
    echo "Dynamic ARP Sweep results:" >> "$LOG_FILE"

    for ((ip=start; ip<=end; ip++)); do
        current_ip=$(int2ip "$ip")
        echo "Scanning IP: $current_ip" | tee -a "$LOG_FILE"

        (
            arping_output=$(arping -c 3 -I "$iface" "$current_ip" 2>&1)
            echo "arping output for $current_ip: $arping_output" | tee -a "$LOG_FILE"

            if echo "$arping_output" | grep -q "Unicast reply"; then
                echo "  Responded: $current_ip" >> "$LOG_FILE"
                
                # Trigger ARP table update with a ping (only if arping was successful)
                ping -c 3 -W 4 "$current_ip" >/dev/null 2>&1
            fi

            arping -c 1 -w 2 -I "$iface" "$current_ip" >/dev/null 2>&1
        ) &

        ((current_processes++))
        if ((current_processes >= MAX_PARALLEL_PROCESSES)); then
            wait
            current_processes=0
        fi
    done

    wait
    echo "Dynamic ARP sweep complete." | tee -a "$LOG_FILE"
    echo "==========================" | tee -a "$LOG_FILE"
    # Capture end time and calculate duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    echo "Dynamic ARP Sweep completed in $((duration / 60)) minutes and $((duration % 60)) seconds." | tee -a "$LOG_FILE"
    echo "==========================" | tee -a "$LOG_FILE"
}

# ---------------------------------------------------------------
# Main Function: Initialize and trigger both sweep methods
# ---------------------------------------------------------------
main() {
    iface=$(get_default_interface)
    if [[ -z "$iface" ]]; then
        echo "Error: No default interface found" | tee -a "$LOG_FILE"
        exit 1
    fi

    echo "Using interface: $iface" | tee -a "$LOG_FILE"

    if ! command -v arping &>/dev/null; then
        echo "Error: arping command not found. Please install it." | tee -a "$LOG_FILE"
        exit 1
    fi

    echo "Dynamic ARP Sweep started at $(date)" | tee -a "$LOG_FILE"
    dynamic_arp_sweep "$iface"

    echo "Waiting for all background processes to finish..." | tee -a "$LOG_FILE"
    wait

    echo "ARP Sweep completed at $(date)" | tee -a "$LOG_FILE"
    echo "Results logged to $LOG_FILE"
    echo "==========================" | tee -a "$LOG_FILE"
    echo "Current ARP table:" | tee -a "$LOG_FILE"
    ip neigh | tee -a "$LOG_FILE"  
    echo "==========================" | tee -a "$LOG_FILE"
    echo "ARP Sweep script completed successfully." | tee -a "$LOG_FILE"
}

# ---------------------------------------------------------------
# Script Entry Point
# ---------------------------------------------------------------
main
# End of script