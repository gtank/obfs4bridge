FROM alpine:latest
MAINTAINER George Tankersley <george.tankersley@gmail.com>

# Get package index.
RUN apk update

# Install Go for building obfs4proxy.
RUN apk add go git ca-certificates
RUN mkdir -p /go/src /go/bin
RUN chmod -R 777 /go
ENV GOPATH /go
ENV PATH /go/bin:$PATH
WORKDIR /go

# Install tor and obfs4proxy with the ability to bind on low ports.
RUN apk add libcap
RUN apk add tor --update-cache --repository http://dl-4.alpinelinux.org/alpine/edge/testing

# Remove cache to reduce image size.
RUN rm -rf /var/cache/apk/*

# Install obfs4proxy.
RUN go get github.com/yawning/obfs4/obfs4proxy
RUN mv /go/bin/obfs4proxy /usr/local/bin/obfs4proxy
RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/obfs4proxy

# Copy both tor configs to the image.
COPY torrc.public /etc/tor/torrc.public
COPY torrc.private /etc/tor/torrc.private

# Bridges on low and common ports are much less likely to be blocked.
# Even very restrictive networks usually allow traffic on port 80.
EXPOSE 80

# Run tor as a nonprivileged user.
RUN chown -R tor /etc/tor
USER tor

ENTRYPOINT ["tor"]
