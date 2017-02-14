#!/bin/bash -e

# Dont prompt for MySQL
on_chroot << EOF
debconf-set-selections <<< "mysql-server mysql-server/root_password password biab"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password biab"
debconf-set-selections <<< "mysql-server-5.0 mysql-server/root_password seen true"
debconf-set-selections <<< "mysql-server-5.0 mysql-server/root_password_again seen true"
apt-get -y install mysql-server mysql-client
EOF

# Add PHP7 to the repo list
install -v -m 644 files/preferences ${ROOTFS_DIR}/etc/apt/

if grep -q 'mati75' ${ROOTFS_DIR}/etc/apt/sources.list; then
	echo "PHP7 source already in list"
else
	echo "Adding PHP7 source"
	echo 'deb http://repozytorium.mati75.eu/raspbian jessie-backports main contrib non-free' >> ${ROOTFS_DIR}/etc/apt/sources.list
	echo '#deb-src http://repozytorium.mati75.eu/raspbian jessie-backports main contrib non-free' >> ${ROOTFS_DIR}/etc/apt/sources.list
fi

on_chroot << EOF
sudo gpg --keyserver pgpkeys.mit.edu --recv-key CCD91D6111A06851
sudo gpg --armor --export CCD91D6111A06851 | apt-key add -
apt-get update
EOF
