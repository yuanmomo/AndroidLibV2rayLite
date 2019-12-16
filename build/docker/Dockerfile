FROM ubuntu:18.04
MAINTAINER yuanmomo <yuanhongbin9090@gmail.com>

# update sys and install build required
RUN apt-get update && apt-get -y upgrade && \
    apt-get -y install openjdk-8-jdk wget make git && \
    apt-get autoremove && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root/go/src/AndroidLibV2rayLite

CMD ["/bin/bash","-vx","build-in-docker.sh","data","dep"]