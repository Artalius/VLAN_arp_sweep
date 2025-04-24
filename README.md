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
> - four /24 VLANS
> - 7 wi-fi networks
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
- `ip` (from `iproute2`)
- Bash

---

Simple, effective, and ideal for devices on networks where ARP discovery delays cause connectivity issues.
