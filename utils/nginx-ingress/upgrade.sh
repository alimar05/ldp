#!/bin/bash

helm upgrade --install --rollback-on-failure --wait nginx-ingress . -n nginx-ingress -f values-minimum.yaml