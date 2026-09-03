#!/usr/bin/env bash

read -p "Do you want to Install system-diagnostics? [Y/n] " -n 1 -r </dev/tty
echo

if [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Installing..."
else
    echo "Aborting Installation."
    exit 1
fi

TARGET_DIR="$HOME/system-diagnostics"

if [ -d "$TARGET_DIR" ]; then
    echo "This Package Already Exists" >&2

    read -p "Do you want to proceed anyway? [y/N]: " REPLY </dev/tty

    REPLY=${REPLY:-N}

    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Re-Installing..."
        rm -rf "$TARGET_DIR"
        sed -i '/system-diagnostics/d' "$HOME/.bashrc"
        sed -i '/bashedit/d' "$HOME/.bashrc"
    else
        echo "Aborting Installation." >&2
        exit 1
    fi
fi

mkdir ~/system-diagnostics
touch ~/system-diagnostics/system-diagnostics.sh
touch ~/system-diagnostics/power.sh
touch ~/system-diagnostics/unins_sysdiag.sh
touch ~/system-diagnostics/plasmarestart.sh

cat << 'EOF' >> ~/system-diagnostics/system-diagnostics.sh
echo "[Storage]" > ~/system-diagnostics/an-out.txt
lsblk -f >> ~/system-diagnostics/an-out.txt

echo -e "\n[Critical Chain]" >> ~/system-diagnostics/an-out.txt
systemd-analyze critical-chain >> ~/system-diagnostics/an-out.txt

echo -e "\n[Blame]" >> ~/system-diagnostics/an-out.txt
systemd-analyze blame >> ~/system-diagnostics/an-out.txt

echo "Output Written to: ~/system-diagnostics/an-out.txt"
EOF

cat << 'EOF' >> ~/system-diagnostics/power.sh
voltage_now=$(cat /sys/class/power_supply/ucsi-source-psy-USBC000:002/voltage_now)
current_now=$(cat /sys/class/power_supply/ucsi-source-psy-USBC000:002/current_now)

voltage_now2=$((voltage_now / 1000000))
current_now2=$((current_now / 1000000))
wattage2=$(( (voltage_now * current_now) / 1000000000000 ))

echo "Voltage: ${voltage_now2}V Current: ${current_now2}A Wattage: ${wattage2}W"
EOF

cat << 'EOF' >> ~/system-diagnostics/unins_sysdiag.sh
read -p "Do you want to Uninstall system-diagnostics? [Y/n] " -n 1 -r </dev/tty
echo

if [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Uninstalling..."
else
    echo "Aborting"
    exit 1
fi

rm -rf ~/system-diagnostics
sed -i '/system-diagnostics/d' ~/.bashrc
sed -i '/bashedit/d' ~/.bashrc
source ~/.bashrc
EOF

cat << 'EOF' >> ~/system-diagnostics/plasmarestart.sh
nohup plasmashell --replace &

EOF
chmod +x ~/system-diagnostics/system-diagnostics.sh
chmod +x ~/system-diagnostics/power.sh
chmod +x ~/system-diagnostics/unins_sysdiag.sh
chmod +x ~/system-diagnostics/plasmarestart.sh

echo "alias system-diagnostics='~/system-diagnostics/system-diagnostics.sh'" >> ~/.bashrc
echo "alias whatpower='~/system-diagnostics/power.sh'" >> ~/.bashrc
echo "alias bashedit='nano ~/.bashrc'" >> ~/.bashrc
echo "alias uninstall-system-diagnostics='~/system-diagnostics/unins_sysdiag.sh'" >> ~/.bashrc
echo "alias plasmarestart='~/system-diagnostics/plasmarestart.sh'" >> ~/.bashrc
source ~/.bashrc

echo -e "
Diagnostics Package Installed Successfully \n
Added Commands & Functionality:
    Run 'system-diagnostics' to Run a quick Boot Time & Storage Overview. Output will be written to: ~/system-diagnostics/an-out.txt
    Run 'whatpower' to get current Input Voltage, Current and Wattage
    Run 'bashedit' for quick ~/.bashrc access
    Run 'plasmarestart' to restart Plasmashell in Case of Hangups / Crashes \n
To Uninstall this Package, Run 'uninstall-system-diagnostics' \n
Please Reload your Shell or run 'source ~/.bashrc' for all Changes to take Effect
"


