#!/bin/bash

# Install MySQL Community Edition 8.0
# sudo rpm -ivh https://dev.mysql.com/get/mysql80-community-release-$(uname -r | sed 's/^.*\(el[0-9]\+\).*$/\1/')-1.noarch.rpm
sudo yum install -y mysql-shell
sudo mkdir ~${user}/.mysqlsh
sudo echo '{
    "history.autoSave": "true",
    "history.maxSize": "5000"
}' | sudo tee -a ~${user}/.mysqlsh/options.json
sudo chown -R ${user} ~${user}/.mysqlsh

echo "MySQL Shell successfully installed !"
