#!/bin/bash
# Lynxight Reception Desk Auto Configurator
# By David Melnikov 11/27/2014
# Version 1.1 for ISO lx-reception.iso

logo() {
clear
echo " _                      _       _     _   ";
echo "| |                    (_)     | |   | |  ";
echo "| |    _   _ _ __ __  ___  __ _| |__ | |_ ";
echo "| |   | | | | '_ \\ \/ / |/ _\` | '_ \| __|";
echo "| |___| |_| | | | |>  <| | (_| | | | | |_ ";
echo "\_____/\__, |_| |_/_/\_\_|\__, |_| |_|\__|";
echo "        __/ |              __/ |          ";
echo "       |___/              |___/           ";
echo ""
echo "-------------------------------------------------------"
echo "Welcome to the Lynxight Reception Monitor Station Setup"
echo "-------------------------------------------------------"
echo ""
}

# Function check the script is ran with elevated permissions (sudo)

check_sudo() {

if [ "$EUID" -eq 0 ]; then
    echo "---------------------------------------"
    echo "Please do not run this script with sudo"
    echo "---------------------------------------"
    exit 1
fi
}
set_server_name() {
   
    local new_hostname

    while true; do
        read -p "Enter the server name (lowercase letters, numbers, and hyphens only): " new_hostname

        # Check if input is empty
        
        if [[ -z "$new_hostname" ]]; then
            echo "Hostname cannot be empty. Please enter a valid hostname."
            continue
        fi

        # Validate hostname format

        if [[ "$new_hostname" =~ ^[a-z0-9-]+$ ]]; then
            break
        else
            echo "Invalid hostname. Please use only lowercase letters, numbers, and hyphens."
        fi
    done

            sudo hostnamectl set-hostname $new_hostname
            echo ""
            echo "---------------------------------------"
            echo "Server name set to: $new_hostname"
            echo "---------------------------------------"
            echo ""
}
update_gdm_conf() {
    local file="/etc/gdm3/custom.conf"

    # Enable Automatic unattended login
    echo ""
    echo "---------------------------------------"
    echo "Enabling Automatic unattended login"
    echo "---------------------------------------"
    echo""

    sudo awk '{
        # Uncomment lines
        if ($0 ~ /^# *AutomaticLoginEnable/) {
            sub(/^# */, "", $0)
        } else if ($0 ~ /^# *AutomaticLogin/) {
            sub(/^# */, "", $0)
        } else if ($0 ~ /^# *TimedLoginEnable/) {
            sub(/^# */, "", $0)
        } else if ($0 ~ /^# *TimedLogin/) {
            sub(/^# */, "", $0)
        } else if ($0 ~ /^# *TimedLoginDelay/) {
            sub(/^# */, "", $0)
        }

        # Change AutomaticLogin from user1 to ubuntu
        if ($0 ~ /^AutomaticLogin *= *user1/) {
            sub(/user1/, "ubuntu", $0)
        }

        print
    }' "$file" > /tmp/uncommented_file && sudo mv /tmp/uncommented_file "$file"

    # Disable ScreenSaver section already exists
    
    if ! sudo grep -q '\[ScreenSaver\]' "$file"; then
        {
            echo ""
            echo "[ScreenSaver]"
            echo "InactiveTime=0"
        } >> "$file"
    else
        echo "[ScreenSaver] section already exists in $file."
    fi
}

set_language() {
    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
    sudo dpkg-reconfigure locales --frontend noninteractive
}
install_tailscale() {
    sudo rm -f /var/lib/tailscale/tailscaled.state
    sudo curl -fsSL https://tailscale.com/install.sh | sh
    sudo /usr/bin/tailscale up --authkey=tskey-auth-kAkox76LFh11CNTRL-bexCQCqcADiXTVQXgWSUAiQBerguSAFFZ --advertise-tags=tag:prod
    echo "Tailscale installed with the IP address: $(tailscale ip -4)"
}
install_realvnc() {
    sudo apt remove -y realvnc-vnc-server
    sudo curl -L -o VNC.deb https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-Latest-Linux-x64.deb
    sudo dpkg -i VNC.deb
    sudo apt-get install -y -f
    sudo vnclicense -add eyJhbGciOiJSUzI1NiJ9.eyJtYXhTZXJ2ZXJzIjoxNTAsInN1YiI6IktzQk9Vb3BzWm5BUVFpYlRUZVMiLCJtYXhVc2VycyI6MjE0NzQ4MzY0NywiZmVhdHVyZXMiOlsiQ09SRSIsIlJFTU9URV9SRUJPT1QiLCJBVURJT19PVVRQVVQiLCJVU0VSX01BTkFHRU1FTlQiLCJSRU1PVEVfUFJJTlQiLCJWSVJUVUFMX01PREUiLCJHUk9VUF9NQU5BR0VNRU5UIiwiTVVMVElQTEVfVVNFUlMiLCJTQ1JFRU5fQkxBTktJTkdfTU9ERSIsIlNZU1RFTV9BVVRIX1NTTyIsIldFQl9DT05TT0xFIiwiU0VTU0lPTl9SRUNPUkRJTkciLCJNVUxUSV9UT19NVUxUSV9NT05JVE9SIiwiTVVMVElfTEFOR1VBR0VfU1VQUE9SVCIsIkRJUkVDVF9DT05ORUNUSU9OIiwiRklMRV9UUkFOU0ZFUiIsIlVOQVRURU5ERURfQUNDRVNTIiwiTUFOREFURURfMkZBIiwiR1JPVVBfUE9MSUNZIiwiMjU2X0JJVF9BRVMiLCJBVVRPX0xPQ0siLCJJRExFX1RJTUVPVVQiLCJISUdIX1NQRUVEX1NUUkVBTUlORyIsIkdSQU5VTEFSX1BFUk1JU1NJT05TIiwiTUFOQUdFRF9ERVZJQ0VTIiwiSU5fU0VTU0lPTl9DSEFUIiwiT0ZGTElORV9ERVBMT1lNRU5UIiwiQUREUkVTU19CT09LIiwiQUREX0NMSUVOVCIsIldJTkRPV1NfTElOVVhfTUFDX1JBU1BCRVJSWV9QSSIsIk1VTFRJX0ZBQ1RPUl9BVVRIIiwiQU5EUk9JRF9JT1MiLCJNQVNTX0RFUExPWU1FTlQiLCJTWVNURU1fQVVUSCIsIlZJRVdfT05MWV9NT0RFIiwiUFVCS0VZX0FVVEgiLCJEWU5BTUlDX1JFU09MVVRJT04iXSwibWF4VGVjaG5pY2lhbnMiOjAsImxhYmVsIjoiRW50ZXJwcmlzZSIsImV4cCI6MTczNjcyNjQwMCwiaWF0IjoxNzE0NTUyOTQwLCJ0cmlhbCI6ZmFsc2UsInVzaWQiOiI4YjM5NzFlYS0zMWVlLTRhZjAtYjVkYS02ZGVkMzRkMWRlYmEiLCJjb25jdXJyZW50Q29ubmVjdGlvbnMiOjB9.UY_5JQMSXqWNuHiR8mVH_yicWsmJiUFuPQHkRF56GGNsTG3nfLs3FofW_VPYGsTjzs5WRLExF11qB46T7h0guizNhxXcZ-VBCYwx0QmnOIbImsTDVXKCUS0UYwIyNoC-HxVIwxIDTjVccvNJGSSsX0bYwfcsc5p90XbTu-ObzNwPfhlmuBbV1XK8U_DuDWq8T8AlKbro9vfbGjJMIh0ltPipQINE4Sp0u5dMaCaw19O8enP4VXdTm5fEpp4Qb-CQCCoLC0Zw-_FzN6YZGu2rDhZ-SPRxwjk1ea0Nth88wBz9NpdEGbJuYOuY-FykMke5WnjroLfPkQzeEuQQZrFjvQ
    vncserver-x11 -service -joinCloud eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJLc0JPVW9wc1puQVFRaWJUVGVTIiwiYXVkIjoiY3JlYXRlLXNlcnZlciIsImlzcyI6InBsYXRmb3JtLWVudGVycHJpc2UtcG9ydGFsOnhmRlVBQTRaRUNuczgxM01SY1oiLCJpZCI6Ijl2c3VqdHZSVlU4SFRxNnRBTWRtIiwiaWF0IjoxNjI1NjcwMDQ5fQ.2mVi1przPqzC3qUAv8A1fmYOH5RrWlBUSJ8ABAYJ5wo
    sudo systemctl start vncserver-x11-serviced.service
    sudo systemctl enable vncserver-x11-serviced.service
    echo "RealVNC was installed: $(systemctl status vncserver-x11-serviced.service) systemctl status vncserver-x11-serviced.service)"
}

pkg_mgmt(){
    sudo snap install chromium
    sudo apt remove -y --purge unattended-upgrades
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    sudo apt install -y evtest
    sudo apt install -y python3-evdev
    sudo apt install -y python3-uinput
    sudo modprobe uinput
    sudo usermod -aG input ubuntu
    sudo touch /etc/udev/rules.d/99-uinput.rules
    sudo chmod 777 /etc/udev/rules.d/99-uinput.rules
    sudo echo 'KERNEL=="uinput", MODE="0666"' > /etc/udev/rules.d/99-uinput.rules
    sudo chmod 644 /etc/udev/rules.d/99-uinput.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    sudo systemctl daemon-reload
    sudo systemctl enable backlight_monitor.service
    sudo systemctl start backlight_monitor.service
    sudo mv /usr/bin/gnome-keyring-daemon /usr/bin/gnome-keyring-daemon.old
}

set_application_configuration(){
echo "--------------------------------------------------"
echo "Reception Station Application Configuration "
echo "--------------------------------------------------"
echo ""

# Read the current URL from the configuration file
current_url=$(grep -o 'http://[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}:[0-9]\{1,5\}/[a-zA-Z0-9_/]*' /opt/lynxight/lynxight_start.sh)

# Check if the URL was found
if [ -z "$current_url" ]; then
    echo "No URL found in the configuration file."
else
    echo "The current configured URL is: $current_url"
    echo ""
fi

# Prompt for user input
read -p "Please Enter Lynxight Server IP Address: " ip_address
read -p "Please Enter Lynxight Site Name        : " sitename
read -p "Please Enter Lynxight Pool Name        : " poolname

# Construct the new URL
url="http://$ip_address:51000/$sitename/$poolname"

# Replace the old URL in the specified file with the new URL

# check URL connectivity
if ! curl --output /dev/null --silent --head --fail --max-time 5 "$url"; then
    echo "---------------------------------------------------------------------------"
    echo ""
    echo "The URL $url is not reachable."
    echo ""
    echo "Please renter the correct parameters"
    echo ""
    echo "---------------------------------------------------------------------------"
    echo
    set_application_configuration
    return
fi

sudo sed -i "s|$current_url|$url|g" /opt/lynxight/lynxight_start.sh

# Output the constructed URL
echo "Constructed URL: $url"
}

# Copying Autostart files, setting Trusted Flags and disabling screen lock
copy_startup_files(){


echo ""
echo "Copying Autostart files for user Ubuntu"

mkdir -p /home/ubuntu/.config/autostart/
cp /opt/lynxight/misc/allow_only_tap.desktop /home/ubuntu/.config/autostart/
cp /opt/lynxight/misc/reception_app.desktop /home/ubuntu/.config/autostart/
cp /opt/lynxight/misc/volume_monitor.desktop /home/ubuntu/.config/autostart/
cp /opt/lynxight/misc/brightness_monitor.desktop /home/ubuntu/.config/autostart/

echo ""
echo "Setting trusted flag for autostart files"
echo ""

gio set /home/ubuntu/.config/autostart/allow_only_tap.desktop metadata::trusted true
gio set /home/ubuntu/.config/autostart/reception_app.desktop metadata::trusted true
gio set /home/ubuntu/.config/autostart/volume_monitor.desktop metadata::trusted true
gio set /home/ubuntu/.config/autostart/brightness_monitor.desktop metadata::trusted true
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.desktop.session idle-delay 0
}

# Disable APPORT, remove apt updates permantly
disable_apport() {
    sudo sed -i 's/^enabled=1/enabled=0/' /etc/default/apport
    sudo systemctl stop apport.service
    sudo systemctl disable apport.service
    echo "Apport has been disabled and the service is disabled from starting at boot."
    sudo sed -i 's/"1"/"0"/g' /etc/apt/apt.conf.d/10periodic
    sudo sed -i 's/"1"/"0"/g' /etc/apt/apt.conf.d/20auto-upgrades
    sudo sed -i 's|^/*|//|' /etc/apt/apt.conf.d/99update-notifier
    sudo sed -i 's/Prompt=. *$/Prompt=never/' /target/etc/update-manager/release-upgrades
    sudo systemctl disable --now apt-daily.timer
    sudo systemctl disable --now apt-daily.service
    sudo systemctl disable --now apt-daily-upgrade.timer
    sudo systemctl disable --now apt-daily-upgrade.service
    sudo mv /usr/bin/gnome-keyring.daemon /usr/bin/gnome-keyring-daemon.old
}

######################
### MAIN EXECUTION ###
######################

logo

copy_startup_files

check_sudo # not allow sudo

set_server_name # first sudo request is here

# Calling for External DHCP/Static Script
sudo /opt/lynxight/lx_setnet.sh

set_application_configuration

pkg_mgmt

disable_apport

update_gdm_conf

install_tailscale

install_realvnc
######################