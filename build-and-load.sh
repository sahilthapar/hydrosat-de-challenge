#!/bin/bash
# Build the Docker image and load it into Minikube

# Build the Docker image
docker build -t hydrosat-dagster:latest . --no-cache

# Load the image into Minikube
minikube image load hydrosat-dagster:latest --overwrite=true
