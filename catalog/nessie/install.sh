#!/bin/bash

source configuring.sh

helm install nessie . -n nessie -f values-minimum.yaml