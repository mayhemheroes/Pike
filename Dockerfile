FROM --platform=linux/amd64 ubuntu:18.04

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pike8.0 autoconf bison libgmp-dev nettle-dev make g++

ADD . /repo
WORKDIR /repo
RUN make -j8
RUN make install
