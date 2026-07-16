#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait jupyterhub . -n jupyterhub -f values-minimum.yaml \
    --set singleuser.storage.extraVolumes[0].hostPath.path="${NOTEBOOKS_HOST_PATH}" \
    --set hub.config.GenericOAuthenticator.client_secret="${CLIENT_SECRET}"