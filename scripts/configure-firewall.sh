#!/bin/bash
# Configure firewall for ROFL node security
# This script prevents ROFL apps from accessing local network

set -e

echo "==> Configuring Firewall for ROFL Node Security"
echo ""
echo "This will prevent processes owned by the 'oasis' user from accessing"
echo "the local network (except the gateway)."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Get gateway IP (adjust for your network)
GATEWAY_IP="${GATEWAY_IP:-192.168.0.1}"
LAN_NETWORK="${LAN_NETWORK:-192.168.0.0/16}"

# Check if oasis user exists
if ! id "oasis" &>/dev/null; then
    echo "Warning: 'oasis' user does not exist. Creating..."
    useradd -r -s /bin/false oasis
fi

OASIS_UID=$(id -u oasis)

echo "Configuration:"
echo "  Gateway IP: $GATEWAY_IP"
echo "  LAN Network: $LAN_NETWORK"
echo "  Oasis User UID: $OASIS_UID"
echo ""

read -p "Continue with these settings? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Add iptables rules
echo "==> Adding iptables rules..."

# Allow access to gateway
iptables -A OUTPUT -d "$GATEWAY_IP/32" -m owner --uid-owner $OASIS_UID -j ACCEPT

# Block access to LAN
iptables -A OUTPUT -d "$LAN_NETWORK" -m owner --uid-owner $OASIS_UID -j DROP

echo "    ✓ Firewall rules added"
echo ""

# Save rules (Debian/Ubuntu)
if command -v iptables-save &> /dev/null; then
    echo "==> Saving iptables rules..."
    
    # Install iptables-persistent if not installed
    if ! dpkg -l | grep -q iptables-persistent; then
        echo "Installing iptables-persistent..."
        apt-get update && apt-get install -y iptables-persistent
    fi
    
    # Save rules
    iptables-save > /etc/iptables/rules.v4
    
    # Enable service
    systemctl enable netfilter-persistent
    
    echo "    ✓ Rules saved and will persist across reboots"
else
    echo "Warning: Could not find iptables-save. Rules will not persist across reboots."
fi

echo ""
echo "==> Firewall configuration complete!"
echo ""
echo "To verify rules, run: sudo iptables -L OUTPUT -v -n"
echo "To remove rules later:"
echo "  sudo iptables -D OUTPUT -d $GATEWAY_IP/32 -m owner --uid-owner $OASIS_UID -j ACCEPT"
echo "  sudo iptables -D OUTPUT -d $LAN_NETWORK -m owner --uid-owner $OASIS_UID -j DROP"
echo ""
