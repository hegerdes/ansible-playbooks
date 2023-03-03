# Minio

This installs a (clustered) minio service.


## Client
```bash
# Add expire lifecycle
mc ilm add <ALIAS>/<BUCKET>/<PATH> --expiry-days <DAYS>
mc ilm add <ALIAS>/<BUCKET>/<PATH> --noncurrentversion-expiration-days <DAYS>
mc ilm add <ALIAS>/<BUCKET> --tags '<key1>=<value1>&<key2>=<value2>' --expiry-days <DAYS>
```
