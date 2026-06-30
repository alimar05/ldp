#!/bin/bash

source configuring.sh

helm install airflow . -n airflow -f values-minimum.yaml