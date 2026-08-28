#!/bin/bash

# https://projectnessie.org/guides/management/

NAMESPACE=nessie
# Postgres
USER=nessie
HOST=postgresql.postgresql.svc.cluster.local
PORT=5432
PASSWORD=nessie
DATABASE=nessie
SCHEMA=gc
# nessie-gc
DOCKER_IMAGE_TAG=latest
# Minio
ENDPOINT=http://minio.minio.svc.cluster.local:9000
AWS_ACCESS_KEY_ID=AKIAIOSFODNM7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bRxRfiCYEXAMPLEKE
REGION="us-east-1"
# Keycloak
OIDC_AUTH_SERVER_URL=http://keycloak-keycloakx-headless.keycloak.svc.cluster.local:8080/realms/master
CLIENT_ID=nessie-client
CLIENT_SECRET="ivalQbEbsHk0VTZlkti6nfYUA4FmVbyC"


# Создаётся схема, если не существует
kubectl run -it -n ${NAMESPACE} --rm psql \
  --image=bitnamilegacy/postgresql:16.1.0-debian-11-r25 \
  --env=PGPASSWORD=${PASSWORD} \
  --restart=Never \
  --command -- /bin/sh -c "\
  psql -h ${HOST} -p ${PORT} -U ${USER} -d ${DATABASE} -c \"CREATE SCHEMA IF NOT EXISTS ${SCHEMA}\"
  "

# Инициализируется схема
kubectl run -it -n "${NAMESPACE}" --rm nessie-gc-schema-initializer \
  --image="ghcr.io/projectnessie/nessie-gc:${DOCKER_IMAGE_TAG}" \
  --restart=Never \
  --command -- /bin/sh -c "java -jar /nessie-gc.jar create-sql-schema \
  --jdbc-schema CREATE_IF_NOT_EXISTS \
  --jdbc-url \"jdbc:postgresql://${HOST}:${PORT}/${DATABASE}?options=-c search_path=${SCHEMA}\" \
  --jdbc-user ${USER} \
  --jdbc-password ${PASSWORD}"

# Запуск очистки Garbage Collection с cutoff
# Удаляет устаревший metadata.json. После чего DROP TABLE PURGE ничего не оставляет в s3.
# Т. е. для полного удаления таблицы нужно сначала запустить эту команду, затем DROP TABLE PURGE, иначе в логах does not exist, probably already deleted, assuming no files
# --max-file-modification должен быть больше даты создания файла metadata.json
kubectl run -it -n "${NAMESPACE}" --rm nessie-garbage-collector \
  --image="ghcr.io/projectnessie/nessie-gc:${DOCKER_IMAGE_TAG}" \
  --restart=Never \
  --env="AWS_REGION=${REGION}" \
  --env="AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
  --env="AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
  --env="NESSIE_AUTH_TYPE=OAUTH2" \
  --env="NESSIE_AUTHENTICATION_OAUTH2_TOKEN_ENDPOINT=${OIDC_AUTH_SERVER_URL}/protocol/openid-connect/token" \
  --env="NESSIE_AUTHENTICATION_OAUTH2_CLIENT_ID=${CLIENT_ID}" \
  --env="NESSIE_AUTHENTICATION_OAUTH2_CLIENT_SECRET=${CLIENT_SECRET}" \
  --command -- java -jar /nessie-gc.jar gc \
  --defer-deletes=false \
  -u http://nessie.nessie.svc.cluster.local:19120/api/v2 \
  -c P7D \
  --max-file-modification=2026-08-28T00:00:00Z \
  -I s3.region=${REGION} \
  -I s3.endpoint=${ENDPOINT} \
  -I s3.access-key-id=${AWS_ACCESS_KEY_ID} \
  -I s3.secret-access-key=${AWS_SECRET_ACCESS_KEY} \
  -I s3.path-style-access=true \
  --jdbc-url "jdbc:postgresql://${HOST}:${PORT}/${DATABASE}?options=-c search_path=${SCHEMA}" \
  --jdbc-user "${USER}" \
  --jdbc-password "${PASSWORD}"
