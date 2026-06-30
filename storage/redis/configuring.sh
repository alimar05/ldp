#!/bin/bash

NAMESPACE="redis"

# Создать namespace
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
