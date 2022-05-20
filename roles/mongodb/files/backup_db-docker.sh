#!/bin/bash

ZIPPER=pigz
BACKUP_DIR=${CUSTOM_BACKUP_DIR:="/backup_dumps"}
DATE_STR=$(date '+%Y-%m-%d')
LOGFILE="${BACKUP_DIR}/db_backup.log"

if ! [ -x "$(command -v pigz)" ]; then
  echo 'Error: pigz is not installed! Fallback to gzip' | tee -a $LOGFILE
  ZIPPER=gzip
fi

echo -n "Creating db dump to: ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.dump.tar..." | tee -a $LOGFILE
docker exec mongodb sh -c 'exec mongodump -u=$MONGO_INITDB_ROOT_USERNAME -p=$MONGO_INITDB_ROOT_PASSWORD --archive' | $ZIPPER > ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.dump.tar.gz
echo "done" | tee -a $LOGFILE

# Restore
# docker exec -i mongodb sh -c 'exec mongorestore -u=$MONGO_INITDB_ROOT_USERNAME -p=$MONGO_INITDB_ROOT_PASSWORD --drop --gzip --archive' < /root/mongo_dump/mongodb.dump.gz

# Options
# --gzip              # If gziped
# --stopOnError       # Halt on error
# --drop              # Drop existing collections withe the same name as in the dump
# --objcheck          # Validate requests
# --dryRun            # Test run
