#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait nessie nessie -n nessie -f values-minimum.yaml