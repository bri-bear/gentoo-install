#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

TARGET_DRIVE=/dev/sda

ROOT_PASSWORD="gentoo"




echo "[Setting time!]"

timedatectl set-timezone America/Halifax

echo "[Partitioning]"

sfdisk ${TARGET_DISK} << END
size=128MB,bootable
size=1024MB
;
END


yes | mkfs.ext4 /dev/sda1
yes | mkfs.ext4 /dev/sda3
yes | mkswap /dev/sda2 && swapon/dev/sda2


echo "[Mounting partitions]"

mkdir -p /mnt/gentoo/boot
mount /dev/sda3 /mnt/gentoo
mount /dev/sda1 /mnt/gentoo/boot

cd /mnt/gentoo

echo "[Setting up stage3]"

wget https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20220626T170536Z/stage3-amd64-openrc-20220626T170536Z.tar.xz

tar xpf stage* --xattrs-include='*.*' --numeric-owner

echo "[Cleaning up stage3]"

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
cp /etc/resolv.conf etc && chroot . /bin/bash


source /etc/profile

echo "[Syncing Gentoo repository]"
emerge-webrsync

echo "Create a root password:"
passwd

echo "[Adding user 'gentoo' to users.]"
useradd -g users -G wheel,portage,audio,video,usb,cdrom -m gentoo
echo "[Create a password for 'gentoo']"
passwd gentoo

echo "[Installing vim]"
emerge -vq vim

# /etc/fstab config should be around here


echo "[Configuring portage]"
cp ./make.conf /etc/portage/make.conf

echo "[Configuring locale]"
## en_US.UTF-8 UTF-8
## C.UTF8 UTF-8


echo "[Setting Gentoo time]"
ln -sf /usr/share/zoneinfo/America/Halifax /etc/localtime

echo "[Installing the kernel]"

emerge -av sys-kernel/gentoo-sources sys-kernel/linux-firmware
cd /usr/src/linux*

echo "Configure the kernel: "
make localyesconfig
make -j8


make modules_install
make install

echo "[Installing grub]"
emerge --ask sys-boot/grub
grub-install /dev/sda

gruv-mkconfig -o /boot/grub/grub.cfg


echo "[Installing network tools]"
emerge --ask sys-apps/iproute2 net-misc/dhcpcd net-wireless/wireless-tools net-wireless/iw net-wireless/wpa_supplicant

echo "Cleaning up..."
exit
exit
cd /mnt
umount -R gentoo

echo "Reboot!"

