#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait minio . -n minio -f values-minimum.yaml