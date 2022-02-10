FROM python:3.9-bullseye

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN apt-get update && apt-get install -y \
    ssh-client rsync \
    && pip3 install -r requirements.txt
