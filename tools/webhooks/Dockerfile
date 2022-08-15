ARG VARIANT="3"
FROM alpine:$VARIANT

# Install
RUN apk add curl jq webhook

ENV TZ=Europe/Berlin
ARG COMMIT_HASH="none"
ARG COMMIT_TAG="none"
ENV COMMIT_HASH=$COMMIT_HASH
ENV COMMIT_TAG=$COMMIT_TAG
ENV TZ=Europe/Berlin
LABEL commit-hash=$COMMIT_HASH
LABEL commit-tag=$COMMIT_TAG

ENTRYPOINT [ "webhook" ]
