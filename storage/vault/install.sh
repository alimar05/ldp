#!/bin/bash

source configuring.sh

helm install vault vault -n vault -f values-minimum.yaml