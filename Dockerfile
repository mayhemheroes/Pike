FROM --platform=linux/amd64 ubuntu:18.04 as builder

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pike8.0 autoconf bison libgmp-dev nettle-dev make g++

ADD . /repo
WORKDIR /repo
RUN make -j8
RUN make install

RUN mkdir -p /deps
RUN ldd /usr/local/pike/8.1.17/bin/pike | tr -s '[:blank:]' '\n' | grep '^/' | xargs -I % sh -c 'cp % /deps;'

FROM ubuntu:18.04 as package

COPY --from=builder /deps /deps
COPY --from=builder /usr/local/pike /usr/local/pike
ENV LD_LIBRARY_PATH=/deps
