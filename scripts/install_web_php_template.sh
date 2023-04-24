#!/bin/bash

# Install Apache and Php

sudo yum install httpd -y
sudo systemctl enable httpd
sudo systemctl restart httpd
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --reload

sudo dnf module install php:7.4 -y
sudo yum install php-cli php-mysqlnd php-zip php-gd php-mbstring php-xml php-json -y
sudo systemctl restart httpd

sudo echo "
<?php
phpinfo();
?>
" > /var/www/html/info.php

sudo echo "
<?php
// Database credentials
define('DB_SERVER', '10.0.20.128');// MDS server IP address
define('DB_USERNAME', 'admin');
define('DB_PASSWORD', 'Welcome#1');
define('DB_NAME', 'census');
//Attempt to connect to MySQL database
$link = mysqli_connect(DB_SERVER, DB_USERNAME, DB_PASSWORD, DB_NAME);
// Check connection
if($link === false){
die("ERROR: Could not connect. " . mysqli_connect_error());
}
// Print database connection result
echo 'Successfull Connect.';
?>
" > /var/www/html/config.php

sudo setsebool -P httpd_can_network_connect 1

echo "The apache and php successfully installed !"
