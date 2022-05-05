# Ingress conf generator

## Nginx
Create a nginx config form a simple `yml` file. Run `npm run generate-nginx <YML_FILE_PATH>`

### Usage:
To use this create a ``Dockerfile`` with the following content:
```Dockerfile
FROM gitlab-registry.***REMOVED***/servermgmt-tools/symbic-playbooks/ingress-genarator:main as build

# Copy ingress conf files
COPY . /app

# Genarate config
RUN npm run generate-nginx ingress-hosts-nginx.yml

FROM nginx:1.20
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    bash certbot python3-certbot-nginx \
    && rm /etc/nginx/conf.d/*.conf \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/nginx /etc/nginx
RUN mv /etc/nginx/nginx-entrypoint.sh /nginx-entrypoint.sh \
    && mkdir -p /etc/letsencrypt/live/certs \
    && cp /etc/nginx/ssl/dummy/*.pem /etc/letsencrypt/live/certs/ \
    && chmod +x /nginx-entrypoint.sh \
    && nginx -t \
    && rm /etc/letsencrypt/live/certs/*.pem

# Certbot & debug
ENV NGINX_DEBUG="no"
ARG RUN_CERTBOT="no"
ENV RUN_CERTBOT=$RUN_CERTBOT
# Comma separated domain list
ENV CERTBOT_DOMAINS="mydomain.example.com"
ENTRYPOINT [ "/nginx-entrypoint.sh"]
```

## Supported options

```yml
conf:
  nginx:
    # Header for all vhosts
    common_header: |
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-For $remote_addr;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection 'upgrade';
      proxy_cache_bypass $http_upgrade;
      client_max_body_size 200M;
      proxy_redirect http:// $scheme://;
    # Settings for all vhosts server section
    common_server_settings: ''
# NOTE: Upstream
# The upsteams are always named by the HOST prefix and the name on the current upstream
# Resulting in <HOSTNAME>_<UPSTREAM_ROUTE>. To pass use proxy_pass http://<HOSTNAME>_<UPSTREAM_ROUTE>/;
########################################################################
# NOTE: Locations
# If no location is given, a default location ("/") is created.
# Every location contains the common headers and the proxypass to the defined upstream ips
sites:
    # Minimal site example
  - host: site1.my-domain.com
    ip: 111.222.222.111
    upstreams:
      - route: default
        targets:
        - 127.0.0.1:3000
        - 127.0.0.2:3000
    # Extra sever settings
  - host: site2.my-domain.com
    ip: 111.222.222.111
    upstreams:
      - route: default
        targets:
        - 127.0.0.1:3000
    nginx:
      server_settings: |
        ssl_client_certificate /etc/nginx/ssl/dummy/fullchain.pem;
        ssl_verify_client on;
        proxy_set_header SSL_CLIENT_CERT $ssl_client_cert;
    # Own routes
  - host: site3.my-domain.com
    ip: 111.222.222.111
    upstreams:
      - route: default
        targets:
        - 127.0.0.1:3000
    nginx:
      locations:
        - route: /
          body: |
            # First attempt to serve request as file, then 404
            try_files $uri $uri/ =404;
        - route: /not_found
          body: |
            return 404;
        - route: /private
    # No TLS
  - host: site4.my-domain.com
    ip: 111.222.222.111
    upstreams:
      - route: default
        targets:
        - 127.0.0.2:3000
    tls: 'no'
    # Own certs
  - host: site5.my-domain.com
    ip: 111.222.222.111
    upstreams:
      - route: default
        targets:
        - 127.0.0.1:3000
    tls:
      crt: /etc/nginx/ssl/dummy/fullchain.pem
      key: /etc/nginx/ssl/dummy/privkey.pem
```