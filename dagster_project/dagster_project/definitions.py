from dagster import Definitions, load_assets_from_modules
from dagster_project import assets
from dagster_project.resources import s3_resource

# Load assets from the assets module
all_assets = load_assets_from_modules([assets])

# Define the Dagster definitions without schedules
defs = Definitions(
    assets=all_assets,
    resources={
        "s3": s3_resource,
    },
)