#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait postgresql . -n postgresql -f values-minimum.yaml