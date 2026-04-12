#!/bin/bash


source configuring.sh

helm upgrade --install --create-namespace --rollback-on-failure --wait gitlab . -n gitlab -f values-minimum.yaml