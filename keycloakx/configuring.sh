#!/bin/bash

NAMESPACE="keycloak"
# Postgresql
PSQL_COMMAND="psql -h postgresql.postgresql.svc.cluster.local -p 5432 -U postgres"
USERNAME="keycloak"
PASSWORD="keycloak"
DATABASE="keycloak"

kubectl create secret generic postgresql-secret -n ${NAMESPACE} \
    --from-literal=username="${USERNAME}" \
    --from-literal=password="${PASSWORD}" \
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
