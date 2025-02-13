#!/bin/bash
#SBATCH --job-name=VNC_Cleaning
#SBATCH --partition=ondemand_gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=04:00:00
#SBATCH --output=%x-%j.out

# Cleanup on exit
rm -f /tmp/.X$(cat vnc_display.txt)-lock
rm -f /tmp/.X11-unix/X$(cat vnc_display.txt)
