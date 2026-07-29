#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait keycloak keycloakx -n keycloak -f values-minimum.yaml