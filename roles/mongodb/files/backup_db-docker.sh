#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.mongo_dump..." >> $LOGFILE
docker exec mongodb sh -c 'exec mongodump -u=$MONGO_INITDB_ROOT_USERNAME -p=$MONGO_INITDB_ROOT_PASSWORD --archive' > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.mongo_dump
echo "done" >> $LOGFILE
