#!/bin/bash

BACKUP_DIR=${CUSTOM_BACKUP_DIR:="/backup_dumps"}
DATE_STR=$(date '+%Y-%m-%d')
LOGFILE="${BACKUP_DIR}/db_backup.log"

echo -n "Creating db dump to: ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.dump.tar..." | tee -a $LOGFILE
mongodump -u=$MONGO_INITDB_ROOT_USERNAME -p=$MONGO_INITDB_ROOT_PASSWORD --archive | gzip > ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.dump.tar
echo "done" | tee -a $LOGFILE
