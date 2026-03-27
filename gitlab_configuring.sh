#!/bin/bash

NAMESPACE="gitlab"
# Postgresql
PSQL_COMMAND="psql -h postgresql.postgresql.svc.cluster.local -p 5432 -U postgres"
USERNAME="gitlab"
PASSWORD="gitlab"
DATABASE="gitlab"
# Secret for Rails
PROVIDER="AWS"
REGION="us-east-1"
AWS_ACCESS_KEY_ID="AKIAIOSFODNM7EXAMPLE"
AWS_SECRET_ACCESS_KEY_ID="wJalrXUtnFEMI/K7MDENG/bRxRfiCYEXAMPLEKE"
AWS_SIGNATURE_VERSION=4
ENDPOINT="http://minio.minio.svc.cluster.local:9000"
PATH_STYLE="true"
# Registry secret
ACCESS_KEY=$AWS_ACCESS_KEY_ID
SECRET_KEY=$AWS_SECRET_ACCESS_KEY_ID
V4_AUTH="true"

# Прежде всего в postgresql должна быть создан user gitlab и database gitlab со всеми привилегиями для user gitlab
kubectl run -it -n ${NAMESPACE} --rm psql \
  --image=bitnamilegacy/postgresql:16.1.0-debian-11-r25 \
  --env=PGPASSWORD=postgres \
  --restart=Never \
  --command -- /bin/sh -c "\
  -- https://stackoverflow.com/a/18389184
  echo \"SELECT 'CREATE DATABASE gitlab' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'gitlab')\gexec\" | \
  ${PSQL_COMMAND} -d postgres \
  && ${PSQL_COMMAND} -d postgres \
  -c \"SELECT create_user_if_not_exists('${USERNAME}', '${PASSWORD}');SELECT grant_database_privileges('${DATABASE}', '${USERNAME}');\"
  
  ${PSQL_COMMAND} -d ${DATABASE} -c \
  \"-- Права на схему public (разрешает создание объектов)
  GRANT ALL ON SCHEMA public TO ${USERNAME};
  -- Для будущих объектов в схеме public
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${USERNAME};
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${USERNAME};
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${USERNAME};\""

kubectl create secret generic external-postgresql-secret -n ${NAMESPACE} \
    --from-literal=secret="${PASSWORD}" \
    --dry-run=client -o yaml | kubectl apply -f -

# Прежде всего в minio должны быть созданы бакеты согласно https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/advanced/external-object-storage/minio.md
kubectl run -it -n ${NAMESPACE} --rm minio-cli \
  --image=minio/mc \
  --restart=Never \
  --command -- /bin/sh -c "\
    mc alias set obs ${ENDPOINT} ${AWS_ACCESS_KEY_ID} '${AWS_SECRET_ACCESS_KEY_ID}' \
    && mc mb --ignore-existing obs/gitlab-backup-storage \
    && mc mb --ignore-existing obs/gitlab-lfs-storage \
    && mc mb --ignore-existing obs/gitlab-packages-storage \
    && mc mb --ignore-existing obs/gitlab-uploads-storage \
    && mc mb --ignore-existing obs/gitlab-registry-storage \
    && mc mb --ignore-existing obs/gitlab-tmp-storage"

kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

## Создаём секреты, если их нет
# https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.minio.yaml
kubectl create secret generic gitlab-object-storage -n ${NAMESPACE} \
    --from-literal=connection="provider: ${PROVIDER}
aws_access_key_id: ${AWS_ACCESS_KEY_ID}
aws_secret_access_key: ${AWS_SECRET_ACCESS_KEY_ID}
aws_signature_version: ${AWS_SIGNATURE_VERSION}
endpoint: ${ENDPOINT}
path_style: ${PATH_STYLE}" \
    --dry-run=client -o yaml | kubectl apply -f -

# https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/registry.minio.yaml
kubectl create secret generic gitlab-registry-storage -n ${NAMESPACE} \
    --from-literal=config="s3:
    v4auth: ${V4_AUTH}
    regionendpoint: ${ENDPOINT}
    pathstyle: ${PATH_STYLE}
    region: ${REGION}
    bucket: gitlab-registry-storage
    accesskey: ${AWS_ACCESS_KEY_ID}
    secretkey: ${AWS_SECRET_ACCESS_KEY_ID}" \
    --dry-run=client -o yaml | kubectl apply -f -

