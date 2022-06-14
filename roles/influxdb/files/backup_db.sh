#!/bin/bash
set -e

BACKUP_DIR=${CUSTOM_BACKUP_DIR:="/backup_dumps"}
DATE_STR=$(date '+%Y-%m-%d')
LOGFILE="${BACKUP_DIR}/db_backup.log"

echo -n "Creating db dump to: ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.dump.tar.gz..." | tee -a $LOGFILE
mkdir -p $BACKUP_DIR/$DATE_STR-$HOSTNAME | tee -a $LOGFILE
influx backup $BACKUP_DIR/$DATE_STR-$HOSTNAME | tee -a $LOGFILE
tar -cvO $BACKUP_DIR/$DATE_STR-$HOSTNAME/ | gzip > $BACKUP_DIR/$DATE_STR-$HOSTNAME.dump.tar.gz | tee -a $LOGFILE
rm -r $BACKUP_DIR/$DATE_STR-$HOSTNAME | tee -a $LOGFILE
echo "done" | tee -a $LOGFILE

# Restore
# tar -xzvf ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.tar.gz
# influx restore <BACKUP_DIR>