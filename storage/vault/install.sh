#!/bin/bash

source configuring.sh

helm install vault . -n vault -f values-minimum.yaml