import json
from datetime import datetime

import geopandas as gpd
import pandas as pd
from dagster import AssetExecutionContext, DailyPartitionsDefinition, asset
from shapely.geometry import Polygon

# Define the daily partitions starting from 2023-01-01
start_date = datetime(2023, 1, 1)
partitions_def = DailyPartitionsDefinition(start_date=start_date)


@asset(
    partitions_def=partitions_def,
    group_name="hydrosat",
    description="Process field data within a bounding box and calculate metrics for each field",
)
def field_metrics(context: AssetExecutionContext) -> None:
    """
    Daily partitioned asset that processes field data within a bounding box.

    For each daily partition:
    1. Load the bounding box and field polygons from S3
    2. Filter fields that intersect with the bounding box
    3. Process fields with planting dates on or before the current partition
    4. Save field-specific metrics to S3
    """
    # Get the current partition (today's date)
    partition_date_str = context.asset_partition_key_for_output()
    partition_date = datetime.strptime(partition_date_str, "%Y-%m-%d")
    context.log.info(f"Processing partition: {partition_date_str}")

    s3 = context.resources.s3

    # Get the bounding box from S3
    bounding_box = s3.get_bounding_box()
    context.log.info(f"Loaded bounding box with bounds: {bounding_box.bounds}")

    # Get all field polygons from S3
    fields_gdf = s3.get_fields()
    context.log.info(f"Loaded {len(fields_gdf)} fields")

    # Filter fields that intersect with the bounding box
    intersecting_fields = fields_gdf[fields_gdf.intersects(bounding_box)]
    context.log.info(f"{len(intersecting_fields)} fields intersect with the bounding box")

    # Filter fields based on planting dates
    # Only process fields that have a planting date on or before the current partition date
    fields_to_process = intersecting_fields[
        pd.to_datetime(intersecting_fields["planting_date"]) <= partition_date
        ]

    context.log.info(f"Found {len(fields_to_process)} fields to process for this partition")

    if len(fields_to_process) == 0:
        context.log.info("No fields to process for this partition")
        return

    # Process each field and save the results
    for _, field in fields_to_process.iterrows():
        field_id = field["field_id"]
        field_geometry = field["geometry"]
        planting_date = pd.to_datetime(field["planting_date"])

        # Calculate days since planting
        days_since_planting = (partition_date - planting_date).days

        context.log.info(f"Processing field {field_id}, planted {days_since_planting} days ago")

        # Clip the field to the bounding box if it extends beyond it
        processed_geometry = field_geometry.intersection(bounding_box)

        # Calculate field area in hectares (approximate conversion)
        area_hectares = processed_geometry.area * 10000  # Simple conversion

        # Calculate simple metrics for this field
        # In a real scenario, this would involve more complex processing with actual input data
        metrics = {
            "field_id": field_id,
            "date": partition_date_str,
            "days_since_planting": days_since_planting,
            "area_hectares": area_hectares,
            "processed_geometry_type": processed_geometry.geom_type,
            "intersection_percentage": (processed_geometry.area / field_geometry.area) * 100,
            # Simulate a metric that changes with time since planting
            "vegetation_index": min(0.9, (0.3 + (days_since_planting * 0.01))),
            # Simulate a status that depends on the day of processing
            "status": "healthy" if days_since_planting % 7 < 5 else "stressed"
        }

        # Save the metrics to S3
        s3.save_field_metrics(field_id, partition_date_str, metrics)
        context.log.info(f"Successfully processed field {field_id}")

    context.log.info(f"Completed processing partition {partition_date_str}")