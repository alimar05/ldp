#!/bin/bash

source configuring.sh

helm upgrade --install --create-namespace --rollback-on-failure --wait airflow . -n airflow -f values-minimum.yaml