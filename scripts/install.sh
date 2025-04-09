#!/bin/sh -e

# Based on https://github.com/nix-community/nixbox/blob/master/scripts/install.sh

export MACHINE_TYPE=$([ -d /sys/firmware/efi/efivars ] && echo "UEFI" || echo "Legacy")
export DISK=/dev/vda

# Partition disk
if [ $MACHINE_TYPE == "Legacy" ];then
cat <<FDISK | fdisk $DISK
n




a
w

FDISK

elif [ $MACHINE_TYPE == "UEFI" ];then

parted $DISK -- mklabel gpt
parted $DISK -- mkpart root ext4 512MB 100%
parted $DISK -- mkpart ESP fat32 1MB 512MB
parted $DISK -- set 2 esp on
fi

# Create filesystem
if [ $MACHINE_TYPE == "Legacy" ];then

mkfs.ext4 -j -L nixos ${DISK}1

elif [ $MACHINE_TYPE == "UEFI" ];then

mkfs.fat -F 32 -n ESP ${DISK}2
mkfs.ext4 -L nixos ${DISK}1

fi

# Mount filesystem
mount LABEL=nixos /mnt
if [ $MACHINE_TYPE == "UEFI" ];then
mkdir -p /mnt/boot
if [ -e /dev/disk/by-label/ESP ];then
mount /dev/disk/by-label/ESP /mnt/boot
else
mount ${DISK}2 /mnt/boot
fi
fi

# Setup system
nixos-generate-config --root /mnt

curl -sf "$PACKER_HTTP_ADDR/vagrant.nix" > /mnt/etc/nixos/vagrant.nix
curl -sf "$PACKER_HTTP_ADDR/qemu.nix" > /mnt/etc/nixos/hardware-builder.nix
curl -sf "$PACKER_HTTP_ADDR/vagrant-hostname.nix" > /mnt/etc/nixos/vagrant-hostname.nix
curl -sf "$PACKER_HTTP_ADDR/vagrant-network.nix" > /mnt/etc/nixos/vagrant-network.nix
curl -sf "$PACKER_HTTP_ADDR/configuration.nix" > /mnt/etc/nixos/configuration.nix

### Install ###
nixos-install

### Cleanup ###
curl "$PACKER_HTTP_ADDR/postinstall.sh" | nixos-enter