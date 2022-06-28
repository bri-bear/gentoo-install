
echo "[Mounting partitions]"

mkdir -p /mnt/gentoo/boot
mount /dev/sda3 /mnt/gentoo
mount /dev/sda1 /mnt/gentoo/boot

cd /mnt/gentoo
wget https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20220626T170536Z/stage3-amd64-openrc-20220626T170536Z.tar.xz

tar xpf stage*

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
