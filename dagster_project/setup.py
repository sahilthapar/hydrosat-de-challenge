from setuptools import find_packages, setup

setup(
    name="dagster_project",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "dagster",
        "dagster-aws",
        "dagster-postgres",
        "boto3",
        "geopandas",
        "shapely",
        "pandas",
        "numpy",
        "rasterio",
        "pyproj",
    ],
    extras_require={
        "dev": [
            "pytest",
        ],
    },
)