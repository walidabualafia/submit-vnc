#!/bin/bash
#SBATCH --job-name=VNC_Desktop
#SBATCH --partition=ondemand_gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --output=%x-%j.out

# Author: Walid Abu Al-Afia (2025)

# Load necessary modules
# For our usecase, all the required software is globally installed.

# Get the compute node's hostname
NODE_HOSTNAME=$(hostname)

# Function to find an available VNC display
# 
# Given we have simultaneous VNC connections on the same host, we have to
# dynamically find an open display.
find_available_display() {
    for i in {1..99}; do
        VNC_PORT=$((5900 + i))
        LOCK_FILE="/tmp/.X${i}-lock"
        if [ ! -e "$LOCK_FILE" ] && ! netstat -tulnp | grep -q ":$VNC_PORT"; then
            echo $i
            return
        fi
    done
    echo "ERROR: No available VNC display found." >&2
    exit 1
}

# Get an available VNC display
VNC_DISPLAY=$(find_available_display)
VNC_PORT=$((5900 + VNC_DISPLAY))
WEBSOCKIFY_PORT=$((6080 + VNC_DISPLAY))

# Generate a random VNC password
VNC_PASSWD=$(openssl rand -base64 6)

# Store password securely (as secure as I could, we will have to revise security)
mkdir -p ~/.vnc
echo "$VNC_PASSWD" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Kill any lingering VNC session on the selected display
#
# TODO: check if vncserver -kill cleans up the tmp files to free
#       the display
if [ -e "/tmp/.X${VNC_DISPLAY}-lock" ]; then
    vncserver -kill :$VNC_DISPLAY
    sleep 2
fi

# Start TurboVNC server 
vncserver :$VNC_DISPLAY -geometry 1920x1080 -depth 24 -rfbauth ~/.vnc/passwd
sleep 2

# Start XFCE session
export DISPLAY=:$VNC_DISPLAY
echo "exec startxfce4" > ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup

# Start websockify for NoVNC access
websockify --web=/usr/share/novnc $WEBSOCKIFY_PORT localhost:$VNC_PORT &

# Extract the login node's hostname
LOGIN_HOST=$(scontrol show hostname $SLURM_SUBMIT_HOST | head -n 1)

# Output connection details
echo "------------------------------------------------------------"
echo "VNC session started on compute node: $NODE_HOSTNAME"
echo "Access it with a VNC viewer using: $NODE_HOSTNAME:$VNC_DISPLAY"
echo "VNC Password: $VNC_PASSWD"
echo "Alternatively, connect via web browser using:"
echo "http://$LOGIN_HOST:$WEBSOCKIFY_PORT/vnc.html?host=$LOGIN_HOST&port=$WEBSOCKIFY_PORT"
echo ""
echo "For clean up: your VNC_DISPLAY=${VNC_DISPLAY}"
echo "------------------------------------------------------------"

echo "${VNC_DISPLAY}" > vnc_display.txt

# Wait for the job to finish
wait
