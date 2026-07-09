#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait keycloak . -n keycloak -f values-minimum.yaml