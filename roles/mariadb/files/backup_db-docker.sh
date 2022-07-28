#!/bin/bash
set -e

ZIPPER=pigz
BACKUP_DIR=${CUSTOM_BACKUP_DIR:="/backup_dumps"}
DATE_STR=$(date '+%Y-%m-%d')
LOGFILE="${BACKUP_DIR}/db_backup.log"

checkExitCode() {
    if [ $1 -ne 0 ]; then
        echo -e "${RED}Last command returned none zero exit code. Please check${NC}"; exit 1
    fi
}

# Trim filesystem
fstrim -av
if ! [ -x "$(command -v pigz)" ]; then
  echo 'Error: pigz is not installed! Fallback to gzip' | tee -a $LOGFILE
  ZIPPER=gzip
fi

mkdir -p $BACKUP_DIR

echo -n "Creating db dump to: ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.sql.dump..." | tee -a $LOGFILE
docker exec mariadb bash -c '/usr/bin/mysqldump --all-databases --password=$MYSQL_ROOT_PASSWORD' | $ZIPPER > ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.sql.dump.gz
echo "done" | tee -a $LOGFILE

# Restore:
# docker exec mariadb bash -c 'exec mysql -uroot -p$MYSQL_ROOT_PASSWORD' < <NAME_OF_FILE>
