#!/bin/bash
touch /home/ubuntu/webserver_install.log
echo "Sarang's Automated Deployment" >> /home/ubuntu/webserver_install.log
echo "-----------------------------" >> /home/ubuntu/webserver_install.log

sudo apt-get update -y

echo "Installing apache server ... " >> /home/ubuntu/webserver_install.log
sudo apt-get install -y apache2
sudo systemctl enable apache2
sudo systemctl start apache2

echo "Installing git ... " >> /home/ubuntu/webserver_install.log
sudo apt-get install -y git

echo "echo Cloning web site from Sarang's Github Account .... " 
####sudo git clone https://github.com/sarangsalunke1989/sarang_website.git 
####sudo cp -rp /sarang_website/* /var/www/html/ 

sudo git clone https://github.com/sarangsalunke1989/week5-web-site.git
sudo cp -rp /week5-web-site/* /var/www/html/

echo "Website deployed ...." >> /home/ubuntu/webserver_install.log
