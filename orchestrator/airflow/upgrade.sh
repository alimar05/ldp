#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait airflow . -n airflow -f values-minimum.yaml \
    --set config.keycloak_auth_manager.client_secret="${CLIENT_SECRET}"