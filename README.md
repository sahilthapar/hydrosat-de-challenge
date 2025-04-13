# Hydrosat Data Engineering Project

This project demonstrates a simplified version of Hydrosat's data processing setup using Dagster on Kubernetes. It processes geospatial data within a bounding box for multiple fields with different planting dates.

## Overview

The project implements the following requirements:
- Deploying Dagster to a Kubernetes cluster
- Creating a daily partitioned asset that processes geospatial data
- Reading from and writing to S3 buckets
- Processing data within a bounding box extent
- Handling fields with different planting dates

## Prerequisites Setup (macOS)
Note: Please note that the following instructions are only verified on a MacOS machine with Intel-chip. If you're on a different machine, you might need to find suitable equivalents.

### 1. Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Docker Desktop

```bash
# Install Docker Desktop for Mac
brew install --cask docker

# Start Docker Desktop
open -a Docker
```

Wait for Docker Desktop to fully start. Verify it's running by checking the Docker icon in the menu bar.

### 3. Install minikube for local Kubernetes

```bash
# Install minikube
brew install minikube

# Start minikube with sufficient resources
minikube start --memory=4096 --cpus=2 --driver=docker
```

### 4. Install kubectl

```bash
# Install kubectl
brew install kubectl

# Verify installation
kubectl version --client
```

### 5. Install Helm

```bash
# Install Helm
brew install helm

# Add the Dagster repository
helm repo add dagster https://dagster-io.github.io/helm
helm repo update
```

### 6. Install Terraform

```bash
# Install Terraform
brew install terraform

# Verify installation
terraform --version
```

### 7. Install AWS CLI and configure credentials

```bash
# Install AWS CLI
brew install awscli

# Configure your AWS credentials
aws configure
```

When prompted, enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

### 8. Install Python 3.9+ and pip

```bash
# Install Python 3.9 via Homebrew
brew install python@3.9

# Make sure pip is up to date
pip3 install --upgrade pip
```

