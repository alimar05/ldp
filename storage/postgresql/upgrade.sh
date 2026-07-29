#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait postgresql postgresql -n postgresql -f values-minimum.yaml