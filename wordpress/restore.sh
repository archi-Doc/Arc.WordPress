#!/bin/bash
# chmod 600 /home/ubuntu/wordpress/testkey.sk

set -e -o pipefail

echo 'Restore WordPress'

# MariaDB (server->sshh)
rsync -av -e "ssh -p 2222 -i /home/ubuntu/wordpress/testkey.sk -o StrictHostKeyChecking=no" root@your.sshh.address:/sshh/Backup/mariadb /home/ubuntu

# Restore MariaDB
mariadb -h db-multi -u wordpressdbuser -p'testpass' wpdb_1 < /home/ubuntu/mariadb/wpdb_1.sql
mariadb -h db-multi -u wordpressdbuser -p'testpass' wpdb_2 < /home/ubuntu/mariadb/wpdb_2.sql

# WordPress data (server->sshh)
sudo rsync -av --delete -e "ssh -p 2222 -i /home/ubuntu/wordpress/testkey.sk" root@your.sshh.address:/sshh/Backup/wp_1 /home/ubuntu
sudo rsync -av --delete -e "ssh -p 2222 -i /home/ubuntu/wordpress/testkey.sk" root@your.sshh.address:/sshh/Backup/wp_2 /home/ubuntu

echo 'Complete'
