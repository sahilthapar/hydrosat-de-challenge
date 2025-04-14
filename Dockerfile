FROM python:3.11

# Copy your Dagster project. You may need to replace the filepath depending on your project structure
COPY dagster_project /

# This makes sure that logs show up immediately instead of being buffered
ENV PYTHONUNBUFFERED=1

# Install dagster and any other dependencies your project requires
RUN pip install --no-cache-dir -e .

WORKDIR /dagster_project/
# Expose the port that your Dagster instance will run on
EXPOSE 80