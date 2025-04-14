#!/bin/bash
# Build the Docker image and load it into Minikube

# Ensure we're in the project root
cd "$(dirname "$0")"

# Build the Docker image
echo "Building Docker image..."
docker build -t hydrosat-dagster:latest .

# Load the image into Minikube
echo "Loading image into Minikube..."
minikube image load hydrosat-dagster:latest

echo "Done! The image is now available in Minikube."