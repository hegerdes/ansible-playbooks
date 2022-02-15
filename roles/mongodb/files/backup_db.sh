#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.dump..." | tee -a $LOGFILE
mongodump -u=$MONGO_INITDB_ROOT_USERNAME -p=$MONGO_INITDB_ROOT_PASSWORD --archive | gzip > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.dump.gz
echo "done" | tee -a $LOGFILE
