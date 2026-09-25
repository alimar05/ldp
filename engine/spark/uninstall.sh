#!/bin/bash

# set -e

helm uninstall spark -n spark
kubectl delete secrets -n spark spark-spark-operator-webhook-certs
kubectl delete crd -n spark sparkapplications.sparkoperator.k8s.io sparkconnects.sparkoperator.k8s.io