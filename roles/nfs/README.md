# Role NFS

## Purpose
Setup nfs server


## Defaults
```yml
nfs_export_dir: /nfs_data
nfs_exports_file_path: /etc/exports

nfs_exports:
  - directory: /nfs_data/share1
    host: '*(rw,sync,no_subtree_check)'

```
