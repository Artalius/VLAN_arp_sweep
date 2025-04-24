# ARP Sweep Script

This script performs a dynamic ARP scan on your local network based on your interface's CIDR range. It's designed to warm up the ARP/neighbor cache so devices (e.g., printers, IoT devices) are immediately reachable after boot.

### ✅ What It Does

- Detects your default network interface
- Calculates the IP range from your subnet
- Sends ARP requests (`arping`) in parallel
- Optionally follows up with `ping` to ensure ARP entries are refreshed
- Logs everything to `/var/log/arp_sweep.log`

### 📌 Example Use Case

I couldn't reach printers or OctoPi from OctoApp (unless using ETH device) until this ARP sweep ran on boot.
> Granted, I might have self-inflicted this by having
> - ge4 /24 VLANS
> - ge5 wi-fi networks
> - mixed 2.4GHz/5GHz/ETH devices on same VLAN

But all devices involved in testing were on a single non-ad-hoc VLAN

### 🔁 Boot Integration

Run automatically on boot with:

#### systemd (Preferred)

After moving all 3 files to the target system(s)
Run the installer, if issues read `./arp_sweep_install.log`

```sh
sudo chmod +x ./install.sh
./install.sh
```

#### Crontab (Additional for announcing)

This addition is not covered by the above `install.sh`

`crontab -e` entry for ARP presence on boot:

```sh
@reboot arping -c 1 -w 2 -I $(ip route | awk '/default/ {print $5; exit}') $(ip addr show $(ip route | awk '/default/ {print $5; exit}') | grep -oP 'inet \K[\d.]+') >/dev/null 2>&1
```

### 🛠 Requirements

- `arping`
  - This is not included/installed during the `install.sh`
- `ip` (from `iproute2`)
- Bash

---

### 🔧 How `arping` and `ping` Work in This Script

This combination of `arping` and `ping`, along with running checks in parallel, helps quickly update the network's device list, ensuring everything is reachable without taking too long.

- **`arping`**: The script uses `arping` to check if devices on the local network are responding. It sends out a request to each device's IP address and waits to see if it gets a reply. If a device replies, it means the device is on the network and can be reached.

- **`ping`**: After finding a device with `arping`, the script uses `ping` to double-check that the device is actually reachable and responding to network requests. This step helps ensure that the device is fully online and working while updating `ip neigh`.

- **Speeding Things Up (Threading)**: To make the process faster, the script checks multiple devices at the same time (instead of one by one). It does this by running several checks in parallel, making the whole process quicker. If too many checks are happening at once, it waits for some to finish before continuing. Currently set to 86, so that after 3 batches it is done with a /24 network ( this clocked in at about 46 seconds on an RPiZeroW2).

---

Simple, effective, and ideal for devices on networks where ARP discovery delays cause connectivity issues.
