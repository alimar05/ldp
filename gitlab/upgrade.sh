#!/bin/bash

source configuring.sh

helm upgrade --install --rollback-on-failure --wait gitlab . -n gitlab -f values-minimum.yaml