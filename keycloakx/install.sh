#!/bin/bash

source configuring.sh

helm install keycloak . -n keycloak -f values-minimum.yaml