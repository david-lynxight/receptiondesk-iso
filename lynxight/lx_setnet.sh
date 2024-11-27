#!/bin/bash

# Function to get the active network interface
get_active_interface() {
    active_interface=$(ip -o link show | awk -F ': ' '$2 !~ /^(lo|vir|docker)[0-9]*$/{print $2; exit}')
    echo "$active_interface"
}

# Function to convert subnet mask to CIDR notation
subnet_to_cidr() {
    local subnet_mask=$1
    local IFS
    IFS=.
    set -- $subnet_mask
    local cidr=0
    for octet in $1 $2 $3 $4; do
        while [ $octet -ne 0 ]; do
            cidr=$((cidr + $((octet % 2))))
            octet=$((octet / 2))
        done
    done
    echo $cidr
}
# Function to set a static IP
set_static_ip() {
    local interface=$(get_active_interface)
    read -p "Enter the static IP address (e.g., 192.168.0.235): " static_ip
    read -p "Enter the subnet mask (e.g., 255.255.255.0): " subnet_mask
    subnet_cidr=$(subnet_to_cidr $subnet_mask)
    read -p "Enter the gateway (e.g., 192.168.0.1): " gateway

    if [[ ! $static_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP address format. Please enter a valid IP address."
        set_static_ip
        return
    fi

    if [[ ! $gateway =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid gateway format. Please enter a valid gateway."
        set_static_ip
        return
    fi

    # Create Netplan configuration file with static IP settings
    rm -rf /etc/netplan/*
    cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $interface:
      addresses:
        - $static_ip/$subnet_cidr
      routes:
        - to: default
          via: $gateway
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
chmod 400 /etc/netplan/01-netcfg.yaml
    # Apply the new configuration
    netplan apply || { echo "Failed to apply Netplan configuration."; exit 1; }
systemctl restart systemd-networkd
    echo "Static IP configuration has been set for interface $interface."
}

# Function to set DHCP configuration
set_dhcp_config() {
    local interface=$(get_active_interface)
    
    # Create Netplan configuration file for DHCP
    cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $interface:
      dhcp4: true
EOF

    # Apply the new configuration
    chmod 400 /etc/netplan/01-netcfg.yaml
     netplan apply || { echo "Failed to apply Netplan configuration."; exit 1; }
    systemctl restart systemd-networkd
    echo "DHCP configuration has been set for interface $interface."
}

# Main script
check_ip_configuration() {
    local interface=$(get_active_interface)
    if [[ -z $interface ]]; then
        echo "No active network interface found."
        exit 1
    fi

    read -p "The host is configured with DHCP. Do you want to continue with DHCP? (y/n): " choice
    if [[ $choice == "n" ]]; then
        set_static_ip
    else
        echo "Continuing with DHCP."
        set_dhcp_config
    fi
}
display_network_summary() {
    local interface=$(get_active_interface)
    local ip_config=$(ip addr show dev $interface | awk '/inet / {print $2}')
    local gateway=$(ip route show | grep default | awk '{print $3}')
local dns_servers=$(cat /etc/resolv.conf | awk '/nameserver/ {print $2}' | xargs)
    echo "-------------------------------------------------------------"
    echo "Current Network Configuration Summary:"
    echo "-------------------------------------------------------------"
    echo ""
    echo ""
    echo "Active Interface: $interface"

#    if [[ $(cat /etc/netplan/01-netcfg.yaml) == *"dhcp4: true"* ]]; then
#        echo "IP Configuration: DHCP"
#    else
#        local static_ip=$(grep 'addresses:' /etc/netplan/01-netcfg.yaml | awk '{print $2}')
#        echo "IP Configuration: Static"
#        echo "Static IP Address: $static_ip"
#    fi
    echo "IP: $ip_config"
    
    echo "Gateway: $gateway"

    echo "DNS Servers: $dns_servers"
    echo ""
    echo "-------------------------------------------------------------"
}

# Execute the main script
display_network_summary
check_ip_configuration
