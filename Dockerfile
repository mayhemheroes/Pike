FROM --platform=linux/amd64 ubuntu:18.04 as builder

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pike8.0 autoconf bison libgmp-dev nettle-dev make g++

ADD . /repo
WORKDIR /repo
RUN make -j8
RUN make CONFIGUREARGS="--prefix=/repo/build" install

FROM ubuntu:18.04 as package

COPY --from=builder /repo/build /repo/build
ENV LD_LIBRARY_PATH=/repo/build
