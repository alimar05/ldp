#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait jupyterhub . -n jupyterhub -f values-minimum.yaml