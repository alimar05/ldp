#!/bin/bash

source configuring.sh

helm install gitlab . -n gitlab -f values-minimum.yaml