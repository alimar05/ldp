#!/bin/bash

source configuring.sh

helm install postgresql . -n postgresql -f values-minimum.yaml