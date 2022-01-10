#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d').sql..." >> $LOGFILE
mysqldump --all-databases > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.sql
echo "done" >> $LOGFILE
