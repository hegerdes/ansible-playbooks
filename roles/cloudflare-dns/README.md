# Role cloudflare-dns

## Purpose
To set DNS records on cloudflare


## Defaults
```yml
---
# cloudflare-DNS

# See: https://open-api.cloudflare.com/
cloudflare_api_token: xxx
cloudflare_dns_zone_id: xxx

# List of dns records:
cloudflare_dns_records: []
# Example
# cloudflare_dns_records:
#  - { host: "my-domain.example", value: "127.0.0.1" }
#  - { host: "test.k8s.example.com", value: "127.0.0.1", type: A, ttl: 3600 }

```
