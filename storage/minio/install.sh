#!/bin/bash

source configuring.sh

helm install minio minio -n minio -f values-minimum.yaml