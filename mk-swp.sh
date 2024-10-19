#!/bin/bash

read -p "Enter the desired swap volume (in gigabytes): " swap_volume
swap_size=$((swap_volume * 1024 * 1024 * 1024))
sudo fallocate -l $swap_size /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo "Swap file created and added to fstab."
echo "Current swap status:"
sudo swapon --show
