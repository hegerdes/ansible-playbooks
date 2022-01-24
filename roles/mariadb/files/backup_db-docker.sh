#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.sql.dump..." >> $LOGFILE
docker exec mariadb bash -c '/usr/bin/mysqldump --all-databases --password=$MYSQL_ROOT_PASSWORD' > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.sql.dump
echo "done" >> $LOGFILE

# Restore:
# docker exec mariadb bash -c 'exec mysql -uroot -p$MYSQL_ROOT_PASSWORD' < <NAME_OF_FILE>