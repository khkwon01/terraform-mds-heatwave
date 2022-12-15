# terraform-mds

Provision MySQL Database Service (MDS) and Heatwave with Terraform.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/khkwon01/terraform-mds/archive/refs/tags/mds-heatwave.zip)


<hr/>

# It need to install LudicrousDB for testing read replica for MySQL.

1. login wordpress server firstly.
2. install LudicrousDB plgin to Word press application.
```
  [opc@wordpressserver1 ~]$ cd /var/www/html/wp-content/plugins
  [opc@wordpressserver1 ~]$ sudo wget https://github.com/stuttter/ludicrousdb/archive/refs/heads/master.zip
  [opc@wordpressserver1 plugins]$ sudo unzip master.zip
  [opc@wordpressserver1 plugins]$ sudo mv ludicrousdb-master ludicrousdb
  [opc@wordpressserver1 plugins]$ sudo rm master.zip
  [opc@wordpressserver1 plugins]$ sudo chown -R apache. ludicrousdb
  [opc@wordpressserver1 plugins]$ sudo cp ludicrousdb/ludicrousdb/drop-ins/db.php ../db.php
  [opc@wordpressserver1 plugins]$ sudo cp ludicrousdb/ludicrousdb/drop-ins/db-config.php ../../
```
