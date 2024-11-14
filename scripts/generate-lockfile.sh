#!/bin/bash

PARENT_DIR="$(dirname "$(realpath "$0")")"
PROJECT_DIR="$PARENT_DIR"/..

# Initial build to generate the `uv.lock` file
docker build -t cosmos-init -f "$PARENT_DIR"/init.Dockerfile "$PROJECT_DIR"
# Create a container using this image and copy `uv.lock` from there into the project root
docker create --name temp-container cosmos-init:latest
docker cp temp-container:/app/uv.lock "$PROJECT_DIR"
docker rm temp-container
