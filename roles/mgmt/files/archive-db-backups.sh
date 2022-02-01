#!/bin/bash

SERVERS=("10.10.0.6" "10.10.0.7" "10.10.0.8")
BACKUP_DST="/db_dumps"
AWS_BUCKET="mybucket"
SECRET=MySecureSecret

# create btk dir
mkdir -p $BACKUP_DST

for SERVER in "${SERVERS[@]}"; do
    for DUMP_FILE in $(ssh $SERVER "ls -t /db_dumps/*.dump"); do
        echo "${SERVER}: getting ${DUMP_FILE}..."
        DUMP_FILE_NAME=$(ssh $SERVER "basename ${DUMP_FILE}")
        DUMP_DATE=${DUMP_FILE_NAME:0:10}
        mkdir -p $BACKUP_DST/$DUMP_DATE
        ssh $SERVER "gzip -c ${DUMP_FILE}" | gpg --batch --symmetric --passphrase $SECRET > $BACKUP_DST/$DUMP_DATE/$DUMP_FILE_NAME.gz.gpg
        echo "${SERVER}: Compressed and encrypted ${DUMP_FILE}"
        if [[ $(date '+%Y-%m-%d') != $DUMP_DATE ]]; then
            echo "${SERVER}: Removing ${DUMP_FILE}"
            # ssh $SERVER "rm ${DUMP_FILE}"
        fi
    done
done


echo "Running: aws s3 cp ${BACKUP_DST}/$(date '+%Y-%m-%d') s3://${AWS_BUCKET}${BACKUP_DST}/$(date '+%Y-%m-%d') --recursive"
# aws s3 cp ${BACKUP_DST}/$(date '+%Y-%m-%d') s3://${AWS_BUCKET}${BACKUP_DST}/$(date '+%Y-%m-%d') --recursive


# Decrypt and unzip
# gpg --batch --decrypt --passphrase $SECRET <FILE> | gunzip > <FILE_DEST>
