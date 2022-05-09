#!/bin/bash

BACKUP_DIR=${CUSTOM_BACKUP_DIR:="/backup_dumps"}
DATE_STR=$(date '+%Y-%m-%d')
LOGFILE="${BACKUP_DIR}/db_backup.log"

echo -n "Creating db dump to: ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.dump.tar.gz..." | tee -a $LOGFILE
mkdir -p ${BACKUP_DIR}

docker exec influxdb bash -c "mkdir -p ${BACKUP_DIR}/${DATE_STR}-service-influxdb" | tee -a $LOGFILE

docker exec influxdb bash -c 'influx backup --org $DOCKER_INFLUXDB_INIT_ORG --token $TOKEN '"${BACKUP_DIR}/${DATE_STR}-service-influxdb" | tee -a $LOGFILE

docker cp influxdb:${BACKUP_DIR}/${DATE_STR}-service-influxdb ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME} | tee -a $LOGFILE

docker exec influxdb bash -c "rm -r ${BACKUP_DIR}/${DATE_STR}-service-influxdb" | tee -a $LOGFILE

tar -cvO ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}/ | gzip > ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME}.dump.tar.gz | tee -a $LOGFILE

rm -r ${BACKUP_DIR}/${DATE_STR}-${HOSTNAME} | tee -a $LOGFILE

echo "done" | tee -a $LOGFILE

# Restore:
# docker exec influxdb bash -c 'tar -xzvf -' < <BACKUP_FILE>
# docker exec influxdb bash -c "influx restore --org $DOCKER_INFLUXDB_INIT_ORG --token $TOKEN <BACKUP_DIR>"
