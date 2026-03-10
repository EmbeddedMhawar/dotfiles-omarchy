#!/bin/bash
# Start wayvnc servers for headless monitors and launch VNC viewers on remote PCs
#
# Layout:
#   HEADLESS-2 (Pentium 136x768) = right of main
#   HEADLESS-3 (Atom 1024x600)    = below main
#
# Ports:
#   HEADLESS-2 -> 5901 (Pentium)
#   HEADLESS-3 -> 5900 (Atom)

# Auto-detect main machine IP
MAIN_IP=$(ip -4 addr show | grep -oP 'inet \K10\.\d+\.\d+\.\d+' | head -n 1)
[ -z "$MAIN_IP" ] && MAIN_IP=$(ip -4 route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[\d.]+')

ATOM_IP="10.114.222.133"
PENTIUM_IP="10.114.222.72"

echo "Using Main IP: $MAIN_IP"

# Clean up any previous wayvnc instances
killall wayvnc 2>/dev/null
rm -f /tmp/wayvnc_*.sock
sleep 1

# Wait for headless monitors to be available
echo "Waiting for headless monitors..."
for i in $(seq 1 10); do
    COUNT=$(hyprctl monitors -j | jq '[.[] | select(.name | contains("HEADLESS"))] | length')
    [ "$COUNT" -ge 2 ] && break
    sleep 1
done

# Get actual headless monitor names
MON1=$(hyprctl monitors -j | jq -r '[.[] | select(.name | contains("HEADLESS"))] | sort_by(.name) | .[0].name')
MON2=$(hyprctl monitors -j | jq -r '[.[] | select(.name | contains("HEADLESS"))] | sort_by(.name) | .[1].name')

if [ -z "$MON1" ] || [ -z "$MON2" ]; then
    notify-send "VNC Displays" "Failed to find headless monitors" 2>/dev/null
    exit 1
fi

echo "Found monitors: $MON1, $MON2"

# Ensure monitors are ON
hyprctl dispatch dpms on "$MON1"
hyprctl dispatch dpms on "$MON2"

# Start wayvnc for each headless monitor
echo "Starting wayvnc servers..."
# Use nohup to ensure wayvnc doesn't die when the script exits
nohup wayvnc -S /tmp/wayvnc_1.sock --output "$MON1" 0.0.0.0 5901 > /tmp/wayvnc_1.log 2>&1 &
nohup wayvnc -S /tmp/wayvnc_2.sock --output "$MON2" 0.0.0.0 5900 > /tmp/wayvnc_2.log 2>&1 &

# Wait and verify they are listening
sleep 3
if ! ss -tlnp | grep -q ':5901' || ! ss -tlnp | grep -q ':5900'; then
    echo "Error: wayvnc failed to start. Check /tmp/wayvnc_*.log"
    notify-send "VNC Displays" "wayvnc failed to start" 2>/dev/null
    exit 1
fi

# Launch applications on specific monitors
echo "Launching applications on specific monitors..."

# Main Screen
hyprctl dispatch focusmonitor eDP-1
hyprctl dispatch exec alacritty
sleep 1

# Pentium Screen (MON1)
hyprctl dispatch focusmonitor "$MON1"
hyprctl dispatch exec browseros
sleep 2

# Atom Screen (MON2)
hyprctl dispatch focusmonitor "$MON2"
hyprctl dispatch exec obsidian
sleep 2

hyprctl dispatch focusmonitor eDP-1

# Function to launch VNC in Kiosk mode
launch_kiosk() {
    local IP=$1
    local PORT=$2
    local NAME=$3
    echo "Launching Kiosk mode on $NAME ($IP) on port $PORT..."
    
    ssh -n -f -o ConnectTimeout=5 -o StrictHostKeyChecking=no mhawar@"$IP" \
        "export DISPLAY=:0; \
         i3-msg exit 2>/dev/null; \
         sleep 1; \
         pkill -u mhawar i3 2>/dev/null; \
         pkill -9 Xorg 2>/dev/null; \
         sleep 1; \
         nohup xinit /bin/sh -c 'xset s off -dpms; /usr/bin/vncviewer -FullScreen -RemoteResize=0 -SecurityTypes None ${MAIN_IP}:${PORT}' -- :0 vt1 -s 0 -dpms > /tmp/vnc_kiosk.log 2>&1 &"
}

# Launch on both
launch_kiosk "$PENTIUM_IP" 5901 "Pentium"
launch_kiosk "$ATOM_IP" 5900 "Atom"

# Restart waybar
sleep 3
omarchy-restart-waybar 2>/dev/null

notify-send "VNC Displays" "Remote displays connected ($MAIN_IP)" 2>/dev/null
