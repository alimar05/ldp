#!/bin/bash

source configuring.sh

helm install nginx-ingress . -n nginx-ingress -f values-minimum.yaml