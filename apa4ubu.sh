#!/bin/bash

#This script installs Apache for Ubuntu, enables color for bash shell, changes default password, 
#configures the firewall, preps a new site- includes virtual host files and landing page creation, 
#and creates a new user once work is complete in root.

#Install vim and fix shell color
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install vim
sed -I 's/"#force_color_prompt=yes"/"force_color_prompt=yes"/g' ~/.bashrc
exec bash
#Update default user password
echo "Enter a new password"
read newpw
sudo passwd
echo "$newpw";
echo "$newpw";
#Install Apache web server on Ubuntu
sudo apt-get install apache2
sudo apt-get update
sudo apt-get upgrade
#Enable install SSL
sudo a2ensite default-ssl
sudo a2enmod ssl
sudo systemctl restart apache2
#Make self signed certs
#make-ssl-cert generate-default-snakeoil --force-overwrite
#Create additional certs with different host names
#make-ssl-cert /usr/share/ssl-cert/ssleay.cnf /path/to/cert-file.crt

#Configure Apache firewall
sudo ufw show app list
sudo ufw allow 'Apache'
#Set up SSH and open necessary ports
sudo ufw allow 'OpenSSH'
sudo ufw allow ssh
sudo ufw allow 2222
sudo ufw enable
sudo ufw allow 80
sudo ufw allow https
sudo ufw allow 443
sudo ufw reload
sudo ufw status
#Remove default Apache web server landing page. Creeate dir +html page for new site. Fix perms of new files
sudo rm /var/www/html/index.html
echo "Enter site name"
read siteName
sudo mkdir -p /var/www/"$siteName"/public_html
touch /var/www/"$siteName"/public_html/index.html
sudo chown -R www-data:www-data /var/www/"$siteName"
#create virtual host config file and write the config for virtual host on port 80
serverAdmin=$(webmaster@"$siteName")
echo "Enter intended primary domain"
read serverName
echo "Enter all other domains i.e. subdomain, each seperated by a single space"
read serverAlias
documentRoot=$(/var/www/"$siteName"/public_html)
#One of the following will probably return an error. If so, match syntax of the one that does work
#If neither work, delete the two lonies, and leave the lines below this as are, they assume these two lines weill have issues and account for this
errorLog=$([${APACHE_LOG_DIR}]/"$siteName"-error.log)
accessLog=$("${APACHE_LOG_DIR}"/"$siteName"-access.log)
#If the two lines above this work, change both lines beginning from this point: ${APACHE_LOG_DIR} and ending after this one: .log
#Use functioning vars above instead in their place. $errorLog & $accessLog
sudo sh printf "%s" "[<VirtualHost *:80>\nServerAdmin "$serverAdmin"\nServerName "$serverName"\nServerAlias "$serverAlias"\nDocumentRoot "$documentRoot" \nErrorLog ${APACHE_LOG_DIR}/"$siteName"-error.log \nCustomLog ${APACHE_LOG_DIR}/"$siteName"-access.log combined \n</VirtualHost>]" > /etc/apache2/sites-available/"$siteName".conf
#Enable the virtual host config file
sudo a2ensite "$siteName"
sudo apachectl configtest
sudo systemctl reload apache2
#Add a new user to avoid working in root going forward
echo "Enter a User Name for your new user"
read userName
sudo useradd $userName
echo "Entewr a Password for your new user"
read newpw
sudo passwd
echo "$newpw";
echo "$newpw";
#Add new user to the sudoer file and give sudo access
usermod -aG sudo "$userName"
echo "$userName  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$userName"
