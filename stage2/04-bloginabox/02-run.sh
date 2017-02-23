#!/bin/bash -e

. ./versions.conf

function downloadGit {
	if [ -d ${ROOTFS_DIR}/home/pi/install/$2 ]; then
		git --git-dir=${ROOTFS_DIR}/home/pi/install/$2/.git pull
	else
		git clone $1 ${ROOTFS_DIR}/home/pi/install/$2
	fi
}

function downloadUrl {
	if [ ! -f ${ROOTFS_DIR}/home/pi/install/$2 ]; then
		curl -L -o ${ROOTFS_DIR}/home/pi/install/$2 $1
	fi
}

# PHP setup
echo "Setting up PHP"
install -m 644 files/php/biab.ini ${ROOTFS_DIR}/etc/php/$PHP_VERSION/fpm/conf.d
install -m 644 files/php/opcache.ini ${ROOTFS_DIR}/etc/php/$PHP_VERSION/fpm/conf.d

# Splash screen
echo "Setting up Blog In A Box services"
install -m 644 files/services/splash.service ${ROOTFS_DIR}/etc/systemd/system
install -m 644 files/services/biab.service ${ROOTFS_DIR}/etc/systemd/system

on_chroot << EOF
systemctl enable biab
systemctl enable splash
EOF

# Install the BIAB post-setup scripts
echo "Setting up boot scripts"
if [ ! -d ${ROOTFS_DIR}/boot/biab ]; then
	mkdir -p -m 755 ${ROOTFS_DIR}/boot/biab
fi

install -m 755 files/setup.sh ${ROOTFS_DIR}/boot/biab/
install -m 755 files/setup.conf ${ROOTFS_DIR}/boot/biab/

# Setup Nginx
echo "Setting up Nginx"
install -m 644 files/nginx/biab ${ROOTFS_DIR}/etc/nginx/sites-available
install -m 644 files/nginx/restrictions.conf ${ROOTFS_DIR}/etc/nginx/snippets
install -m 644 files/nginx/wordpress.conf ${ROOTFS_DIR}/etc/nginx/snippets
install -m 644 files/nginx/50x.html ${ROOTFS_DIR}/usr/share/nginx/html

on_chroot << EOF
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/biab /etc/nginx/sites-enabled/biab
EOF

# Install latest WordPress release
install -m 700 files/crontabs/pi ${ROOTFS_DIR}/var/spool/cron/crontabs/

if [ ! -d ${ROOTFS_DIR}/opt/wordpress ]; then
	echo "Installing WordPress"
	install -v -m 755 -d ${ROOTFS_DIR}/opt/wordpress

	curl -o ${ROOTFS_DIR}/usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

on_chroot << EOF
chmod +x /usr/local/bin/wp
chown pi:pi /opt/wordpress
sudo -u pi /usr/local/bin/wp core download --path=/opt/wordpress --version=latest
chown pi:crontab /var/spool/cron/crontabs/pi
EOF
fi

# Blog In A Box WP stuff
echo "Setting up Blog In A Box theme and plugin"
mkdir -p ${ROOTFS_DIR}/home/pi/install

if [ -d ${ROOTFS_DIR}/opt/wordpress/wp-content/themes/biab-theme ]; then
	git --git-dir=${ROOTFS_DIR}/opt/wordpress/wp-content/themes/biab-theme/.git pull
	git --git-dir=${ROOTFS_DIR}/opt/wordpress/wp-content/plugins/biab-plugin/.git pull
	git --git-dir=${ROOTFS_DIR}/opt/bloginabox/.git pull
	git --git-dir=${ROOTFS_DIR}/opt/wordpress/wp-content/plugins/basic-auth/.git pull
else
	git clone https://github.com/tinkertinker/biab-theme.git ${ROOTFS_DIR}/opt/wordpress/wp-content/themes/biab-theme
	git clone https://github.com/tinkertinker/biab-plugin.git ${ROOTFS_DIR}/opt/wordpress/wp-content/plugins/biab-plugin
	git clone https://github.com/tinkertinker/biab-cli.git ${ROOTFS_DIR}/opt/bloginabox
	git clone https://github.com/WP-API/Basic-Auth.git ${ROOTFS_DIR}/opt/wordpress/wp-content/plugins/basic-auth
fi

( cd ${ROOTFS_DIR}/opt/bloginabox; npm install )

# Set permissions
on_chroot << EOF
chown pi:pi -R /opt/bloginabox
chmod go-rwx -R /opt/bloginabox
chown pi:pi -R /opt/wordpress/wp-content/themes/biab-theme
chown pi:pi -R /opt/wordpress/wp-content/plugins/biab-plugin
mkdir -p -m 777 /opt/wordpress/wp-content/uploads
chmod u+x /opt/bloginabox/biab
apt-get autoclean
apt-get clean
EOF

install -m 755 files/first-post.png ${ROOTFS_DIR}/opt/wordpress/wp-content/uploads

sed -i 's/^\/\/Unattended-Upgrade::Remove-Unused-Dependencies "false";/Unattended-Upgrade::Remove-Unused-Dependencies "true";/g' ${ROOTFS_DIR}/etc/apt/apt.conf.d/50unattended-upgrades

# Other things
echo "Setting up environment"
install -m 440 files/sudoers/biab ${ROOTFS_DIR}/etc/sudoers.d
install -m 644 files/motd ${ROOTFS_DIR}/etc/
install -m 644 files/smb.conf ${ROOTFS_DIR}/etc/samba/
install -m 744 files/profile/.bash_profile ${ROOTFS_DIR}/home/pi/
install -m 744 files/profile/.bashrc ${ROOTFS_DIR}/home/pi/
install -m 744 files/profile/.dircolors ${ROOTFS_DIR}/home/pi/
install -m 744 files/get-calypso ${ROOTFS_DIR}/home/pi/
install -m 644 files/issue ${ROOTFS_DIR}/etc/
install -d -m 700 ${ROOTFS_DIR}/home/pi/.ssh

on_chroot << EOF
chown pi:pi /home/pi/.bash_profile
chown pi:pi /home/pi/.bashrc
chown pi:pi /home/pi/.dircolors
chown pi:pi /home/pi/.ssh
chown pi:pi /home/pi/get-calypso
chown pi:pi /opt/wordpress/wp-content/uploads/first-post.png
EOF

echo "start_x=1" >>${ROOTFS_DIR}/boot/config.txt
echo "gpu_mem=128" >>${ROOTFS_DIR}/boot/config.txt

downloadGit https://github.com/amix/vimrc.git vimrc
downloadGit https://github.com/creationix/nvm.git nvm
downloadUrl http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-armv7l.tar.xz node-v$NODE_VERSION-linux-armv7l.tar.xz
downloadUrl https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash ../.wpcli.bash
downloadUrl https://phar.phpunit.de/phpunit.phar phpunit.phar
downloadUrl https://getcomposer.org/composer.phar composer.phar

on_chroot << EOF
chown pi:pi /home/pi/.wpcli.bash
EOF
