#!/bin/bash

helm upgrade --install --rollback-on-failure --wait redis . -n redis -f values-minimum.yaml