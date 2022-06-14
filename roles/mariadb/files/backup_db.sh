#!/bin/bash
set -e

BACKUP_DIR=${CUSTOM_BACKUP_DIR:="/backup_dumps"}
DATE_STR=$(date '+%Y-%m-%d')
LOGFILE="${BACKUP_DIR}/db_backup.log"

echo -n "Creating db dump to: ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.sql.dump..." | tee -a $LOGFILE
mysqldump --all-databases | gzip > ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.sql.dump.gz
echo "done" | tee -a $LOGFILE

# Restore
# mysql < <NAME_OF_FILE>