#!/bin/bash
set -e

ZIPPER=pigz
BACKUP_DIR=${CUSTOM_BACKUP_DIR:="/backup_dumps"}
DATE_STR=$(date '+%Y-%m-%d')
LOGFILE="${BACKUP_DIR}/db_backup.log"

if ! [ -x "$(command -v pigz)" ]; then
  echo 'Error: pigz is not installed! Fallback to gzip' | tee -a $LOGFILE
  ZIPPER=gzip
fi

echo -n "Creating db dump to: ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.dump.tar..." | tee -a $LOGFILE
mongodump -u=$MONGO_INITDB_ROOT_USERNAME -p=$MONGO_INITDB_ROOT_PASSWORD --archive | $ZIPPER > ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.dump.tar
echo "done" | tee -a $LOGFILE
