#!/bin/bash

source configuring.sh

helm install nginx-ingress nginx-ingress -n nginx-ingress --create-namespace -f values-minimum.yaml