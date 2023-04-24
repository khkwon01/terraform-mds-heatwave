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

sudo echo '{
<?php
phpinfo();
?>
}' > /var/www/html/info.php

sudo setsebool -P httpd_can_network_connect 1

echo "The apache and php successfully installed !"
