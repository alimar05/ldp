#!/bin/bash

source configuring.sh

helm upgrade --install --create-namespace --rollback-on-failure --wait postgresql . -n postgresql -f values-minimum.yaml