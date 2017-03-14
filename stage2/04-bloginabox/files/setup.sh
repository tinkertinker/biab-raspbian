#!/bin/sh
WP_PATH=--path=/opt/wordpress
WP="/usr/local/bin/wp $WP_PATH"
SUDO_PI="sudo -u pi"

systemctl disable getty@tty1.service
/usr/bin/fbi -T 1 --noverbose --nocomments -a /opt/bloginabox/boot/biab-setup.png

# Load config values
echo "Blog In A Box setup"
. /boot/biab/setup.conf

echo "Setting up Node"
mv /home/pi/install/nvm /home/pi/.nvm
mkdir -p /home/pi/.nvm/.cache/bin/node-v$NODE_VERSION-linux-armv6l
mkdir -p /home/pi/.nvm/versions/node/v$NODE_VERSION
mv /home/pi/install/node-v$NODE_VERSION-linux-armv6l.tar.xz /home/pi/.nvm/.cache/bin/node-v$NODE_VERSION-linux-armv6l/
tar xf /home/pi/.nvm/.cache/bin/node-v$NODE_VERSION-linux-armv6l/node-v$NODE_VERSION-linux-armv6l.tar.xz --strip-components=1 -C /home/pi/.nvm/versions/node/v$NODE_VERSION/
chown -R pi:pi /home/pi/.nvm
sudo -u pi bash -c '. /home/pi/.nvm/nvm.sh; nvm use v'$NODE_VERSION
ln -s /home/pi/.nvm/versions/node/v$NODE_VERSION/bin/node /usr/bin/node
ln -s /home/pi/.nvm/versions/node/v$NODE_VERSION/bin/npm /usr/bin/npm

echo "Setting up VIM"
mv /home/pi/install/vimrc /home/pi/.vim_runtime
chown -R pi:pi /home/pi/.vim_runtime
sudo -u pi sh /home/pi/.vim_runtime/install_basic_vimrc.sh

# Setup MySQL
echo "Setting up MySQL"
mysql --user=root --password=biab -e "CREATE DATABASE IF NOT EXISTS $MYSQL_WP_DATABASE"
mysql --user=root --password=biab -e "CREATE USER biab IDENTIFIED BY '$MYSQL_WP_USER'"
mysql --user=root --password=biab -e "GRANT ALL ON $MYSQL_WP_DATABASE.* TO '$MYSQL_WP_USER'@'localhost' IDENTIFIED BY '$MYSQL_WP_PASSWORD'"
mysqladmin --user=root --password=biab password "$MYSQL_ROOT_PASSWORD"
mysqladmin --user=root --password="$MYSQL_ROOT_PASSWORD" flush-tables

echo "Setting up Nginx"
sed -i "s/server_name.*/server_name ${HOSTNAME_URL};/g" /etc/nginx/sites-available/biab

echo "Setting up WordPress"
echo "define( 'AUTH_KEY', '"`pwgen 64 1 -s`"' );" >/opt/wordpress/keys.txt
echo "define( 'SECURE_AUTH_KEY', '"`pwgen 64 1 -s`"' );" >>/opt/wordpress/keys.txt
echo "define( 'LOGGED_IN_KEY', '"`pwgen 64 1 -s`"' );" >>/opt/wordpress/keys.txt
echo "define( 'NONCE_KEY', '"`pwgen 64 1 -s`"' );" >>/opt/wordpress/keys.txt
echo "define( 'AUTH_SALT', '"`pwgen 64 1 -s`"' );" >>/opt/wordpress/keys.txt
echo "define( 'SECURE_AUTH_SALT', '"`pwgen 64 1 -s`"' );" >>/opt/wordpress/keys.txt
echo "define( 'LOGGED_IN_SALT', '"`pwgen 64 1 -s`"' );" >>/opt/wordpress/keys.txt
echo "define( 'NONCE_SALT', '"`pwgen 64 1 -s`"' );" >>/opt/wordpress/keys.txt

cp /boot/biab/wordpress.zip /home/pi
$SUDO_PI $WP core config --dbname=$MYSQL_WP_DATABASE --dbuser=$MYSQL_WP_USER --dbpass=$MYSQL_WP_PASSWORD --skip-salts --extra-php </opt/wordpress/keys.txt
$SUDO_PI $WP core install --url=$HOSTNAME_URL --title="$WP_BLOG_TITLE" --admin_user=$WP_USERNAME --admin_password=$WP_PASSWORD --skip-email --admin_email=$WP_EMAIL
echo "Applying local WP update"
$SUDO_PI $WP core update --force /home/pi/wordpress.zip
echo "Trying remote WP update"
$SUDO_PI $WP core update --force
$SUDO_PI $WP option update blogdescription "$WP_TAGLINE"
$SUDO_PI $WP theme activate biab-theme
$SUDO_PI $WP plugin activate biab-plugin
$SUDO_PI $WP plugin activate basic-auth
$SUDO_PI $WP widget reset --all
$SUDO_PI $WP site empty --yes
$SUDO_PI $WP rewrite structure '/%year%/%monthnum%/%day%/%postname%/'
$SUDO_PI $WP post create --post_type=post --post_title='Welcome to Blog In A Box!' --post_content='<p><img src="/wp-content/uploads/first-post.png" /></p><p>Visit <a href="/wp-admin/admin.php?page=biab-plugin">WP Admin</a> to configure Blog In A Box for your hardware</p>' --post_status=publish
rm -f /opt/wordpress/keys.txt
rm -f /home/pi/wordpress.zip
$SUDO_PI ln -sf /opt/wordpress /home/pi/wordpress

echo '{"username":"'$WP_USERNAME'","password":"'$WP_PASSWORD'"}' >/opt/bloginabox/auth.json

echo "Setting up PHP"
mv /home/pi/install/phpunit.phar /usr/local/bin/phpunit
mv /home/pi/install/composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/phpunit /usr/local/bin/composer

echo "Enabling firewall"
ufw default deny incoming
ufw allow ssh
ufw allow www
ufw allow bonjour
ufw enable

if [ "$SAMBA_WORKGROUP" != "" ]; then
	echo "Enabling SAMBA share: ${SAMBA}"
	sed -i "s/.*workgroup =.*/workgroup = ${SAMBA_WORKGROUP}/g" /etc/samba/smb.conf
	( echo "$PI_USER_PASSWORD"; echo "$PI_USER_PASSWORD" ) | smbpasswd -a -s pi
	ufw allow cifs
else
	apt-get remove samba samba-common-bin
fi

if [ "$WIFI_NETWORK" != "" ]; then
	echo "Enabling Wifi on $WIFI_NETWORK"
	echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" > /etc/wpa_supplicant/wpa_supplicant.conf
	echo "update_config=1" >> /etc/wpa_supplicant/wpa_supplicant.conf
	echo "network={"  >> /etc/wpa_supplicant/wpa_supplicant.conf
	echo '  ssid="'$WIFI_NETWORK'"' >> /etc/wpa_supplicant/wpa_supplicant.conf
	echo '  psk="'$WIFI_PASSWORD'"' >> /etc/wpa_supplicant/wpa_supplicant.conf
	echo '}'  >> /etc/wpa_supplicant/wpa_supplicant.conf
fi

if [ "$TIMEZONE" != "" ]; then
	echo "Setting timezone to $TIMEZONE"
	echo "$TIMEZONE" > /etc/timezone
fi

dpkg-reconfigure -f noninteractive tzdata
if [ "$LOCALE" != "" ]; then
	echo "Setting locale to $LOCALE"
	sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
	sed -i -e 's/# $LOCALE UTF-8/$LOCALE UTF-8/' /etc/locale.gen
	dpkg-reconfigure --frontend=noninteractive locales
	update-locale LANG=$LOCALE
fi

echo "Changing hostname: $HOSTNAME"
echo $HOSTNAME >/etc/hostname
sed -i "s/raspberrypi/${HOSTNAME}/g" /etc/hosts
/etc/init.d/hostname.sh

echo "Changing account password"
echo "pi:$PI_USER_PASSWORD" | chpasswd

if [ "$SSH_KEY" != "" ]; then
	echo "Enabling SSH"
	echo "$SSH_KEY" > /home/pi/.ssh/authorized_keys
	update-rc.d ssh enable
	invoke-rc.d ssh start
fi

# Clean up after ourselves
rm -rf /home/pi/install
chown pi:crontab /var/spool/cron/crontabs/pi

# Don't run this again
systemctl disable biab
rm -rf /boot/biab/setup.conf

# Renable login prompt
systemctl enable getty@tty1.service
wall "System rebooting, hold on to your hats!"
reboot now
