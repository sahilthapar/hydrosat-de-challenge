import json
import os
from typing import Dict

import boto3
import geopandas as gpd
from dagster import ConfigurableResource


class S3Resource(ConfigurableResource):
    """Resource for interacting with S3."""

    input_bucket: str
    output_bucket: str
    region_name: str = "us-east-1"

    def get_client(self):
        """Get an S3 client."""
        return boto3.client("s3", region_name=self.region_name)

    def get_bounding_box(self):
        """Get the bounding box from S3."""
        client = self.get_client()

        try:
            response = client.get_object(
                Bucket=self.input_bucket,
                Key="bounding_box.json",
            )
            bounding_box_data = json.loads(response["Body"].read().decode("utf-8"))

            # Convert the GeoJSON to a Shapely geometry
            bounding_box_gdf = gpd.GeoDataFrame.from_features(bounding_box_data["features"])
            return bounding_box_gdf.geometry[0]
        except Exception as e:
            # If there's an error, log it and raise
            print(f"Error loading bounding box: {str(e)}")
            raise

    def get_fields(self):
        """Get all field polygons from S3."""
        client = self.get_client()

        try:
            response = client.get_object(
                Bucket=self.input_bucket,
                Key="fields.json",
            )
            fields_data = json.loads(response["Body"].read().decode("utf-8"))

            # Convert the GeoJSON to a GeoDataFrame
            fields_gdf = gpd.GeoDataFrame.from_features(fields_data["features"])

            # Ensure the required columns exist
            if "field_id" not in fields_gdf.columns:
                fields_gdf["field_id"] = [f"field_{i}" for i in range(len(fields_gdf))]

            if "planting_date" not in fields_gdf.columns:
                # Set a default planting date if none is specified
                fields_gdf["planting_date"] = "2023-01-01"

            return fields_gdf
        except Exception as e:
            # If there's an error, log it and raise
            print(f"Error loading fields: {str(e)}")
            raise

    def save_field_metrics(self, field_id: str, partition_date: str, metrics: Dict) -> None:
        """Save field metrics to S3."""
        client = self.get_client()

        try:
            # Create a directory structure like fields/field_id/partition_date.json
            client.put_object(
                Bucket=self.output_bucket,
                Key=f"fields/{field_id}/{partition_date}.json",
                Body=json.dumps(metrics, default=str),  # Handle non-serializable objects
                ContentType="application/json",
            )
        except Exception as e:
            # If there's an error, log it and raise
            print(f"Error saving field metrics: {str(e)}")
            raise

    def get_partition_metadata(self, partition_date: str) -> Dict:
        """Get metadata for a specific partition."""
        client = self.get_client()

        try:
            response = client.get_object(
                Bucket=self.output_bucket,
                Key=f"metadata/partition_{partition_date}.json",
            )
            metadata = json.loads(response["Body"].read().decode("utf-8"))
            return metadata
        except:
            # If the metadata doesn't exist, return an empty dict
            return {}

    def update_partition_metadata(self, partition_date: str, metadata: Dict) -> None:
        """Update metadata for a specific partition."""
        client = self.get_client()

        try:
            client.put_object(
                Bucket=self.output_bucket,
                Key=f"metadata/partition_{partition_date}.json",
                Body=json.dumps(metadata, default=str),
                ContentType="application/json",
            )
        except Exception as e:
            # If there's an error, log it and raise
            print(f"Error updating partition metadata: {str(e)}")
            raise


# Resource instance definition
s3_resource = S3Resource(
    input_bucket=os.getenv("INPUT_BUCKET", "hydrosat-input-data"),
    output_bucket=os.getenv("OUTPUT_BUCKET", "hydrosat-output-data"),
    region_name=os.getenv("AWS_REGION", "us-east-1"),
)