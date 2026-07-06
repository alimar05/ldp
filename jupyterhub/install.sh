#!/bin/bash


helm install jupyterhub . -n jupyterhub -f values-minimum.yaml --set singleuser.storage.extraVolumes[0].hostPath.path=$(pwd)/notebooks