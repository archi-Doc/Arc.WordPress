#!/bin/bash
# chmod 600 /home/ubuntu/wordpress/testkey.sk

set -e -o pipefail

echo 'Backup WordPress'

# MariaDB
mkdir -p /home/ubuntu/mariadb
mariadb-dump -h db-multi -u wordpressdbuser -p'testpass' wpdb_1 > /home/ubuntu/mariadb/wpdb_1.sql
mariadb-dump -h db-multi -u wordpressdbuser -p'testpass' wpdb_2 > /home/ubuntu/mariadb/wpdb_2.sql

# MariaDB data (sshh->server)
rsync -av -e "ssh -p 2222 -i /home/ubuntu/wordpress/testkey.sk -o StrictHostKeyChecking=no" /home/ubuntu/mariadb root@your.sshh.address:/sshh/Backup/

# WordPress data (sshh->server)
rsync -av --delete -e "ssh -p 2222 -i /home/ubuntu/wordpress/testkey.sk" /home/ubuntu/wp_1 root@your.sshh.address:/sshh/Backup/
rsync -av --delete -e "ssh -p 2222 -i /home/ubuntu/wordpress/testkey.sk" /home/ubuntu/wp_2 root@your.sshh.address:/sshh/Backup/

echo 'Complete'
