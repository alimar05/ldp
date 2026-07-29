#!/bin/bash

source configuring.sh

helm install gitlab gitlab -n gitlab -f values-minimum.yaml -f values-gitlab-runner-override.yaml