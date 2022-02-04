#!/bin/bash

SERVERS=("10.10.0.6" "10.10.0.7" "10.10.0.8")
BACKUP_DST="/db_dumps"
AWS_BUCKET="mybucket"
AZURE_SAS_TOKEN=""
GPG_TTY=$(tty)
SECRET=$(openssl rand -base64 32)
PUB_KEY_FILE=$BACKUP_DST/"db-backup-key.pub"

# create btk dir
mkdir -p $BACKUP_DST

for SERVER in "${SERVERS[@]}"; do
    for DUMP_FILE in $(ssh $SERVER "ls -t /db_dumps/*.gz"); do
        echo "${SERVER}: getting ${DUMP_FILE}..."
        # Extract file names
        DUMP_FILE_NAME=$(ssh $SERVER "basename ${DUMP_FILE}")
        DUMP_DATE=${DUMP_FILE_NAME:0:10}
        mkdir -p $BACKUP_DST/$DUMP_DATE
        # Get DB dump
        ssh $SERVER "cat ${DUMP_FILE}" | gpg --batch --yes --symmetric --passphrase $SECRET > $BACKUP_DST/$DUMP_DATE/$DUMP_FILE_NAME.gpg
        # Saving the key used for encryption
        echo "${SERVER}: Encrypted and saved KEY to $BACKUP_DST/$DUMP_DATE/KEY.acs"
        echo $SECRET | openssl rsautl -encrypt -inkey $PUB_KEY_FILE -pubin -out $BACKUP_DST/$DUMP_DATE/KEY.acs
        echo "${SERVER}: Compressed and encrypted ${DUMP_FILE}"
        # Remove old backups
        if [[ $(date '+%Y-%m-%d') != $DUMP_DATE ]]; then
            echo "${SERVER}: Removing ${DUMP_FILE}"
            ssh $SERVER "rm ${DUMP_FILE}"
        fi
    done
done

################################ AWS ###############################
# echo "Running: aws s3 cp ${BACKUP_DST}/$(date '+%Y-%m-%d') s3://${AWS_BUCKET}${BACKUP_DST}/$(date '+%Y-%m-%d') --recursive"
# aws s3 cp ${BACKUP_DST}/$(date '+%Y-%m-%d') s3://${AWS_BUCKET}${BACKUP_DST}/$(date '+%Y-%m-%d') --recursive

############################### AZURE ##############################
echo "Running: azcopy copy ${BACKUP_DST}/$(date '+%Y-%m-%d') \$TOKEN\$ --recursive=true"
# azcopy copy ${BACKUP_DST}/$(date '+%Y-%m-%d') $AZURE_SAS_TOKEN --recursive=true


# Decrypt and unzip
# gpg --batch --decrypt --passphrase $SECRET <FILE> | gunzip > <FILE_DEST>
