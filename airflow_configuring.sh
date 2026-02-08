#!/bin/bash

NAMESPACE="airflow"
GITSYNC_USERNAME="airflow_dags"
GITSYNC_PASSWORD="glpat-G1BZ505hVyVKwIWkcibeY286MQp1OjUH.01.0w0ga8nvd"


kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic git-credentials -n ${NAMESPACE} \
    --from-literal=GIT_SYNC_USERNAME=${GITSYNC_USERNAME} \
    --from-literal=GIT_SYNC_PASSWORD=${GITSYNC_PASSWORD} \
    --from-literal=GITSYNC_USERNAME=${GITSYNC_USERNAME} \
    --from-literal=GITSYNC_PASSWORD=${GITSYNC_PASSWORD} \
    --dry-run=client -o yaml | kubectl apply -f -
