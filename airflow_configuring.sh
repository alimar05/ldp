#!/bin/bash

NAMESPACE="airflow"
# gitSync
GITSYNC_USERNAME="airflow"
GITSYNC_PASSWORD="glpat-vk6-ev2hmQDKQGV2avl95W86MQp1OjQH.01.0w0hkv4mr"
# airflow metadata
PSQL_COMMAND="psql -h postgresql.postgresql.svc.cluster.local -p 5432 -U postgres"
USERNAME="airflow"
PASSWORD="airflow"
DATABASE="airflow"


kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic git-credentials -n ${NAMESPACE} \
    --from-literal=GIT_SYNC_USERNAME=${GITSYNC_USERNAME} \
    --from-literal=GIT_SYNC_PASSWORD=${GITSYNC_PASSWORD} \
    --from-literal=GITSYNC_USERNAME=${GITSYNC_USERNAME} \
    --from-literal=GITSYNC_PASSWORD=${GITSYNC_PASSWORD} \
    --dry-run=client -o yaml | kubectl apply -f -

# Прежде всего в postgresql должны быть созданы user и database
kubectl run -it -n ${NAMESPACE} --rm psql \
  --image=bitnamilegacy/postgresql:16.1.0-debian-11-r25 \
  --env=PGPASSWORD=postgres \
  --restart=Never \
  --command -- /bin/sh -c "\
  ${PSQL_COMMAND} -d postgres -c \"SELECT create_user_if_not_exists('${USERNAME}', '${PASSWORD}');\"
  # Создать database, если не существует (https://stackoverflow.com/a/18389184)
  echo \"SELECT 'CREATE DATABASE ${DATABASE} OWNER ${USERNAME}' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${DATABASE}')\gexec\" | \
  ${PSQL_COMMAND} -d postgres"

kubectl create secret generic external-postgresql-secret -n ${NAMESPACE} \
    --from-literal=connection=postgresql://${USERNAME}:${PASSWORD}@postgresql.postgresql.svc.cluster.local:5432/${DATABASE} \
    --dry-run=client -o yaml | kubectl apply -f -
