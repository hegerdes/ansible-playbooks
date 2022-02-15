#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.tar.gz.dump..." | tee -a $LOGFILE
mkdir -p /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME} | tee -a $LOGFILE
influx backup /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME} | tee -a $LOGFILE
tar -cvO /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}/ | gzip > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.dump.tar.gz | tee -a $LOGFILE
rm -r /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME} | tee -a $LOGFILE
echo "done" | tee -a $LOGFILE

# Restore
# tar -xzvf $(date '+%Y-%m-%d')-${HOSTNAME}.tar.gz
# influx restore <BACKUP_DIR>