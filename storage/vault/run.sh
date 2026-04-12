#!/bin/bash

helm upgrade --install --create-namespace --rollback-on-failure --wait vault . -n vault -f values-minimum.yaml