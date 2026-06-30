#!/bin/bash

NAMESPACE="vault"
VAULT_ROOT_TOKEN="hvs.FsNWzPEjvR6OzFsAuohVzm85"
VAULT_UNSEAL_KEY_1="w5Md279toLSyDbTll6Vt2vP4ZsxS2kwoE1SNcZuBRU5w"
VAULT_UNSEAL_KEY_2="DB8l67GJ+yt5E8i+AHQWTYmDNHjXfi1CKm2U/ywW3o7L"
VAULT_UNSEAL_KEY_3="li9DwmE/9RCX6OGUY3XnjOXMlOKo3rHzyrDgm+GRj642"


# Создать namespace
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic vault-root-token -n ${NAMESPACE} \
    --from-literal=VAULT_ROOT_TOKEN=${VAULT_ROOT_TOKEN} \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic vault-unseal-keys -n ${NAMESPACE} \
    --from-literal=VAULT_UNSEAL_KEY_1=${VAULT_UNSEAL_KEY_1} \
    --from-literal=VAULT_UNSEAL_KEY_2=${VAULT_UNSEAL_KEY_2} \
    --from-literal=VAULT_UNSEAL_KEY_3=${VAULT_UNSEAL_KEY_3} \
    --dry-run=client -o yaml | kubectl apply -f -