#!/bin/bash

source configuring.sh

helm install nessie . -n nessie -f values-minimum.yaml \
    --set advancedConfig.quarkus.oidc.ui-app.credentials.secret="${CLIENT_SECRET}"