#!/bin/bash

source configuring.sh

helm install keycloak keycloakx -n keycloak -f values-minimum.yaml