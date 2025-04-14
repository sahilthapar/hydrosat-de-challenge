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

### 8. Install Python 3.11+ and pip

```bash
# Install Python 3.11 via Homebrew
brew install python@3.11

# Make sure pip is up to date
pip3 install --upgrade pip
```

## Project Structure

```
hydrosat-dagster-k8s/
├── README.md                       # Project documentation
├── Dockerfile                      # Docker image for Dagster code
├── build-and-load.sh               # Script to build and load Docker image
├── .gitignore                      # Git ignore file
├── terraform/                      # IaC for k8s and S3 setup
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   └── providers.tf                # Provider configuration
├── k8s/                            # Kubernetes manifests
│   └── dagster-values.yaml         # Custom Helm values for Dagster
├── dagster_project/                # Dagster code
│   ├── setup.py                    # Package setup
│   └── dagster_project/
│       ├── __init__.py             # Package initialization
│       ├── assets.py               # Asset definitions
│       ├── resources.py            # Resource definitions
│       └── repository.py           # Dagster repository definition
└── data/                           # Sample input data
    ├── bounding_box.json           # Sample bounding box
    └── fields.json                 # Sample field polygons
```

## Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/hydrosat-dagster-k8s.git
cd hydrosat-dagster-k8s
```

### 2. Build and load the Docker image

Before deploying with Terraform, you need to build the Docker image containing the Dagster code and load it into Minikube:

```bash
# Make the build script executable
chmod +x build-and-load.sh

# Run the build script
./build-and-load.sh
```

This script will:
1. Build a Docker image with your Dagster project code
2. Load this image into Minikube's local Docker registry

### 3. Deploy the infrastructure using Terraform

```bash
# Navigate to the terraform directory
cd terraform

# Initialize Terraform
terraform init

# Preview the changes
terraform plan

# Apply the configuration
terraform apply
```

When prompted, type `yes` to confirm the deployment.

The Terraform configuration will:
- Create S3 buckets for input and output data (configured as publicly accessible)
- Upload the sample data files to the input bucket
- Deploy Dagster to your Kubernetes cluster

Note: S3 bucket names must be globally unique. If you encounter errors related to bucket name availability, you can modify the bucket names in the `terraform/variables.tf` file.

### 4. Set up port forwarding to access Dagster UI

```bash
# Set up port forwarding
kubectl port-forward service/dagster-dagster-webserver -n hydrosat 3000:80
```

Keep this terminal window open while you want to access the Dagster UI.

### 5. Access Dagster UI and materialize assets

Once port forwarding is set up, you can access the Dagster UI:

1. Open your web browser and navigate to http://localhost:3000
2. You should see the Dagster UI with your project loaded
3. Go to the Assets section
4. Select the `field_metrics` asset
5. Click on "Materialize" for a specific partition or date range

Alternatively, you can use the Dagster CLI to materialize assets:

```bash
# Materialize a specific partition
dagster asset materialize --select field_metrics --partition 2023-01-20

# Materialize a range of partitions
dagster asset materialize --select field_metrics --from 2023-01-01 --to 2023-01-31
```

## Verifying Results

Check the output S3 bucket for the processed field metrics:

```bash
# List the contents of the output bucket
aws s3 ls s3://hydrosat-output-data/fields/ --recursive
```

You should see files organized by field ID and partition date like:
```
fields/field_1/2023-01-15.json
fields/field_1/2023-01-16.json
...
```

## Cleaning Up

When you're done with the project, you can clean up the resources:

```bash
# Delete the Kubernetes resources
cd terraform
terraform destroy

# Stop minikube
minikube stop

# Optionally delete minikube
minikube delete

# Empty and delete S3 buckets
aws s3 rm s3://hydrosat-input-data --recursive
aws s3 rm s3://hydrosat-output-data --recursive
aws s3api delete-bucket --bucket hydrosat-input-data
aws s3api delete-bucket --bucket hydrosat-output-data
```

## Understanding the Asset Processing

The `field_metrics` asset performs the following steps:

1. **Load Data**:
   - Reads the bounding box from S3
   - Reads field polygons from S3
   
2. **Filter and Process**:
   - Filters fields that intersect with the bounding box
   - Only processes fields with planting dates on or before the current partition date
   - For each field, calculates various metrics based on the intersection with the bounding box
   
3. **Save Results**:
   - Writes field-specific metrics back to S3
   - Results are organized by field ID and partition date

## License

MIT