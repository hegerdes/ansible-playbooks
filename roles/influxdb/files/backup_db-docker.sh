#!/bin/bash

LOGFILE=/db_dumps/db_backup.log
echo -n "Creating db dump to: /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}..tar.gz.dump..." >> $LOGFILE

docker exec influxdb bash -c 'mkdir -p /db_dumps/$(date '+%Y-%m-%d')-service-influxdb'

docker exec influxdb bash -c 'influx backup --org $DOCKER_INFLUXDB_INIT_ORG --token $TOKEN /db_dumps/$(date '+%Y-%m-%d')-service-influxdb'

docker cp influxdb:/db_dumps/$(date '+%Y-%m-%d')-service-influxdb /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}

docker exec influxdb bash -c 'rm -r /db_dumps/$(date '+%Y-%m-%d')-service-influxdb'

tar -czvf $(date '+%Y-%m-%d')-${HOSTNAME}.tar.gz.dump /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}/ >> $LOGFILE

rm -r /db_dumps/$(date '+%Y-%m-%d')-${HOSTNAME}

echo "done" >> $LOGFILE

# Restore:
# docker exec influxdb bash -c 'tar -xzvf -' < <BACKUP_FILE>
# docker exec influxdb bash -c "influx restore --org $DOCKER_INFLUXDB_INIT_ORG --token $TOKEN <BACKUP_DIR>"
