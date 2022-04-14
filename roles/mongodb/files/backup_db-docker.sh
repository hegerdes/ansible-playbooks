#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.dump..." | tee -a $LOGFILE
docker exec mongodb sh -c 'exec mongodump -u=$MONGO_INITDB_ROOT_USERNAME -p=$MONGO_INITDB_ROOT_PASSWORD --archive' | gzip > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.dump.gz
echo "done" | tee -a $LOGFILE

# Restore
# docker exec -i mongodb sh -c 'exec mongorestore -u=$MONGO_INITDB_ROOT_USERNAME -p=$MONGO_INITDB_ROOT_PASSWORD --gzip --archive' < /root/mongo_dump/2022-04-14-mongodb.dump.gz

# Options
# --gzip              # If gziped
# --stopOnError       # Halt on error
# --drop              # Drop existing collections withe the same name as in the dump
# --objcheck          # Validate requests
# --dryRun            # Test run