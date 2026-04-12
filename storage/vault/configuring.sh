#!/bin/bash

NAMESPACE="vault"
VAULT_ROOT_TOKEN="hvs.ImLBKtKVsSQ6ke4h6pR8Bqt6"
VAULT_UNSEAL_KEY_1="Oo/S0Wm5rXkZ+isrXdGLuIXyEYLjLssWp7aiNAr+kdFH"
VAULT_UNSEAL_KEY_2="zJBt6IwtPiP5Mqx13CURg7WPQVBtYiZB8mLuK/NcZm22"
VAULT_UNSEAL_KEY_3="CW9skMwxs57vzWlFKiJ4easOJijmn0LmFzW5c2il7P6k"


kubectl create secret generic vault-root-token -n ${NAMESPACE} \
    --from-literal=VAULT_ROOT_TOKEN=${VAULT_ROOT_TOKEN} \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic vault-unseal-keys -n ${NAMESPACE} \
    --from-literal=VAULT_UNSEAL_KEY_1=${VAULT_UNSEAL_KEY_1} \
    --from-literal=VAULT_UNSEAL_KEY_2=${VAULT_UNSEAL_KEY_2} \
    --from-literal=VAULT_UNSEAL_KEY_3=${VAULT_UNSEAL_KEY_3} \
    --dry-run=client -o yaml | kubectl apply -f -