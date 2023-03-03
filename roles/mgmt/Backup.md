# How we create backups

## Preparation
```bash
# Gen private key
openssl genrsa -aes256 -out db-backup-key 2048
# Gen public key
openssl rsa -in db-backup-key -pubout > db-backup-key.pub
```
## Encrypting
```bash
# Generate random symetric key
SECRET=$(openssl rand -base64 128)
# Encrypt file with random symetric key
cat <FILE> | gpg --batch --symmetric --passphrase $SECRET > <OUTPUT>
# Encrypt key with asymetric key
echo $SECRET | openssl rsautl -encrypt -inkey db-backup-key.pub -pubin -out key.asc
```

## Decrypting
```bash
#Decrypt random key
openssl rsautl -decrypt -in KEY.acs -out KEY.out -inkey db-backup-key
# Decrypt backup with radnom key
gpg --batch --decrypt --passphrase $(cat KEY.out) <FILE> | gzip -d > <OUT_FILE>
```

## Uploading
```bash
azcopy copy <file> <token> --recursive=true
aws...
```
