FROM python:3.9-slim-bullseye

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN apt-get update && apt-get install -y --no-install-recommends \
    ssh-client jq rsync && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir -r requirements.txt

ARG COMMIT_HASH="none"
ARG COMMIT_TAG="none"
ENV COMMIT_HASH=$COMMIT_HASH
ENV COMMIT_TAG=$COMMIT_TAG
LABEL commit-hash=$COMMIT_HASH
LABEL commit-tag=$COMMIT_TAG
