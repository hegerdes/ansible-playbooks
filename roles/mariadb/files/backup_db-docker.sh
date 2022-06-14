#!/bin/bash
set -e

BACKUP_DIR=${CUSTOM_BACKUP_DIR:="/backup_dumps"}
DATE_STR=$(date '+%Y-%m-%d')
LOGFILE="${BACKUP_DIR}/db_backup.log"

echo -n "Creating db dump to: ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.sql.dump..." | tee -a $LOGFILE
docker exec mariadb bash -c '/usr/bin/mysqldump --all-databases --password=$MYSQL_ROOT_PASSWORD' | gzip > ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.sql.dump.gz
echo "done" | tee -a $LOGFILE

# Restore:
# docker exec mariadb bash -c 'exec mysql -uroot -p$MYSQL_ROOT_PASSWORD' < <NAME_OF_FILE>
