#!/bin/bash

NAMESPACE="nessie"
# Postgresql
PSQL_COMMAND="psql -h postgresql.postgresql.svc.cluster.local -p 5432 -U postgres"
USERNAME="nessie"
PASSWORD="nessie"
DATABASE="nessie"
# Minio
ACCESS_KEY_ID="AKIAIOSFODNM7EXAMPLE"
SECRET_ACCESS_KEY_ID="wJalrXUtnFEMI/K7MDENG/bRxRfiCYEXAMPLEKE"
ENDPOINT="http://minio.minio.svc.cluster.local:9000"


kubectl create secret generic postgresql-secret -n ${NAMESPACE} \
    --from-literal=username="${USERNAME}" \
    --from-literal=password="${PASSWORD}" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic warehouse-secret -n ${NAMESPACE} \
    --from-literal=access-key-id="${ACCESS_KEY_ID}" \
    --from-literal=secret-access-key-id="${SECRET_ACCESS_KEY_ID}" \
    --dry-run=client -o yaml | kubectl apply -f -

# Прежде всего в postgresql должны быть созданы user и database
kubectl run -it -n ${NAMESPACE} --rm psql \
  --image=bitnamilegacy/postgresql:16.1.0-debian-11-r25 \
  --env=PGPASSWORD=postgres \
  --restart=Never \
  --command -- /bin/sh -c "\
  ${PSQL_COMMAND} -d postgres -c \"SELECT create_user_if_not_exists('${USERNAME}', '${PASSWORD}')\"
  # Создать database, если не существует (https://stackoverflow.com/a/18389184)
  echo \"SELECT 'CREATE DATABASE ${DATABASE} OWNER ${USERNAME}' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${DATABASE}')\gexec\" | \
  ${PSQL_COMMAND} -d postgres"

kubectl run -it -n ${NAMESPACE} --rm minio-cli \
  --image=minio/mc \
  --restart=Never \
  --command -- /bin/sh -c "\
    mc alias set obs ${ENDPOINT} ${ACCESS_KEY_ID} '${SECRET_ACCESS_KEY_ID}' \
    && mc mb --ignore-existing obs/iceberg"