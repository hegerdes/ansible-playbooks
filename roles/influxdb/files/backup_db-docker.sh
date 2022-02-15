#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.tar.gz.dump..." | tee -a $LOGFILE

docker exec influxdb bash -c 'mkdir -p /db_dumps/$(date '+%Y-%m-%d')-service-influxdb' | tee -a $LOGFILE

docker exec influxdb bash -c 'influx backup --org $DOCKER_INFLUXDB_INIT_ORG --token $TOKEN /db_dumps/$(date '+%Y-%m-%d')-service-influxdb' | tee -a $LOGFILE

docker cp influxdb:/db_dumps/$(date '+%Y-%m-%d')-service-influxdb /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME} | tee -a $LOGFILE

docker exec influxdb bash -c 'rm -r /db_dumps/$(date '+%Y-%m-%d')-service-influxdb' | tee -a $LOGFILE

tar -cvO /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}/ | gzip > /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}.dump.tar.gz | tee -a $LOGFILE

rm -r /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME} | tee -a $LOGFILE

echo "done" | tee -a $LOGFILE

# Restore:
# docker exec influxdb bash -c 'tar -xzvf -' < <BACKUP_FILE>
# docker exec influxdb bash -c "influx restore --org $DOCKER_INFLUXDB_INIT_ORG --token $TOKEN <BACKUP_DIR>"
