#!/bin/bash

NAMESPACE="minio"
ACCESS_KEY="AKIAIOSFODNM7EXAMPLE"
SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bRxRfiCYEXAMPLEKE"


kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic minio-credentials -n "${NAMESPACE}" \
    --from-literal=accesskey=${ACCESS_KEY} \
    --from-literal=secretkey=${SECRET_KEY} \
    --dry-run=client -o yaml | kubectl apply -f -