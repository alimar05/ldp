#!/bin/bash

source configuring.sh

helm install redis . -n redis -f values-minimum.yaml