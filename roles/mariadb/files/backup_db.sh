#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.sql.dump..." >> $LOGFILE
mysqldump --all-databases > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.sql.dump
echo "done" >> $LOGFILE

# Restore
# mysql < <NAME_OF_FILE>