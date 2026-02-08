#!/bin/bash

NAMESPACE="postgresql"
ADMINPASSWORD="admin"
PASSWORD="postgres"


kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic postgresql-credentials -n "${NAMESPACE}" \
    --from-literal=postgresql-postgres-password=${ADMINPASSWORD} \
    --from-literal=postgresql-password=${PASSWORD} \
    --dry-run=client -o yaml | kubectl apply -f -
