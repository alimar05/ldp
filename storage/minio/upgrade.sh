#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait minio minio -n minio -f values-minimum.yaml