# Build Stage
FROM --platform=linux/amd64 ubuntu:18.04 as builder

## Install build dependencies.
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less man wget tar git gzip unzip make cmake software-properties-common curl
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y automake
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y g++
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y bison flex
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pike8.0 autoconf bison libgmp-dev nettle-dev


ADD . /repo
WORKDIR /repo
RUN make -j8
RUN make install
