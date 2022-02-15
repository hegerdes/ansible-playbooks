#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.sql.dump..." | tee -a $LOGFILE
docker exec mariadb bash -c '/usr/bin/mysqldump --all-databases --password=$MYSQL_ROOT_PASSWORD' | gzip > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.sql.dump.gz
echo "done" | tee -a $LOGFILE

# Restore:
# docker exec mariadb bash -c 'exec mysql -uroot -p$MYSQL_ROOT_PASSWORD' < <NAME_OF_FILE>