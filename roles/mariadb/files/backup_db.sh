#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.sql.dump..." | tee -a $LOGFILE
mysqldump --all-databases | gzip > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.sql.dump.gz
echo "done" | tee -a $LOGFILE

# Restore
# mysql < <NAME_OF_FILE>