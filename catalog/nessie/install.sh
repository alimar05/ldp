#!/bin/bash

source configuring.sh

helm upgrade --install --create-namespace --rollback-on-failure --wait nessie . -n nessie -f values-minimum.yaml