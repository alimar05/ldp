#!/bin/bash

helm upgrade --install --rollback-on-failure --wait redis redis -n redis -f values-minimum.yaml