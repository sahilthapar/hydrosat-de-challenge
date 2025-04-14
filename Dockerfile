FROM python:3.9-slim

# Set working directory
WORKDIR /opt/dagster/app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy the Dagster project
COPY dagster_project/ /opt/dagster/app/

# Install Python dependencies
RUN pip install --no-cache-dir -e .

# Set Python path
ENV PYTHONPATH=/opt/dagster/app

# Set environment variables with default values
ENV AWS_REGION=us-east-1
ENV INPUT_BUCKET=hydrosat-input-data
ENV OUTPUT_BUCKET=hydrosat-output-data

# Command to run
CMD ["dagster", "api", "grpc", "--host", "0.0.0.0", "--port", "4000", "-m", "dagster_project"]