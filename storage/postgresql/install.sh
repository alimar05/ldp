#!/bin/bash

source configuring.sh

helm install postgresql postgresql -n postgresql -f values-minimum.yaml