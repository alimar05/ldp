#!/bin/bash

source configuring.sh

helm install minio . -n minio -f values-minimum.yaml