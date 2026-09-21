#!/bin/bash

helm upgrade --install --rollback-on-failure --wait spark spark -n spark -f values-minimum.yaml 