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

echo "Creating sql-db-dump to: ${BACKUP_DIR}..." | tee -a $LOGFILE
mysqldump --all-databases | $ZIPPER > $BACKUP_DIR/${DATE_STR}-${HOSTNAME}.sql.dump.gz
echo "done" | tee -a $LOGFILE


# Restore:
# Ungzip and than
# mysql < <NAME_OF_FILE>
