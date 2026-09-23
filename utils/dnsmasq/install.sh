#!/bin/bash

source configuring.sh

docker run -d \
  --name ${NAME} \
  --restart always \
  -p 127.0.0.1:2053:53/udp \
  -p 127.0.0.1:2053:53/tcp \
  -v "${PWD}/dnsmasq.conf:/etc/dnsmasq.conf:ro" \
  jpillora/dnsmasq:latest