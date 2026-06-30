#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait vault . -n vault -f values-minimum.yaml