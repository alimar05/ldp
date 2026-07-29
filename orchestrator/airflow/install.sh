#!/bin/bash

source configuring.sh

helm install airflow airflow -n airflow -f values-minimum.yaml \
    --set config.keycloak_auth_manager.client_secret="${CLIENT_SECRET}"