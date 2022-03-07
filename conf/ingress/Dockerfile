FROM node:16-alpine as build

WORKDIR /app
COPY package.json /app/package.json
RUN npm install

# Copy base files
COPY . /app

# Add labes if build by CI
ARG COMMIT_HASH="none"
ARG COMMIT_TAG="none"
ENV COMMIT_HASH=$COMMIT_HASH
ENV COMMIT_TAG=$COMMIT_TAG
LABEL commit-hash=$COMMIT_HASH
LABEL commit-tag=$COMMIT_TAG
ENV TZ=Europe/Berlin
ENV USE_DOCKER=true

# For debugging
ENTRYPOINT [ "sh" ]


# RUN npm run generate-nginx ingress-hosts-nginx.yml

# FROM nginx:1.20-alpine
# RUN apk add certbot certbot-nginx

# COPY --from=build /app/nginx /etc/nginx
# RUN nginx -t