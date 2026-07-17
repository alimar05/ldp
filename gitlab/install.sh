#!/bin/bash

source configuring.sh

helm install gitlab . -n gitlab -f values-minimum.yaml -f values-gitlab-runner-override.yaml