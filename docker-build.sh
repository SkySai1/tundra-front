#!/bin/bash

# Exit if any command fails
set -e

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <image-name>"
  exit 1
fi

# Get the image name from the argument
IMAGE_NAME=$1

# Build the Docker image
echo "Building the Docker image: $IMAGE_NAME"
docker buildx build -t "$IMAGE_NAME" -f docker/Dockerfile.dist . --no-cache

# Output instructions for running the container
echo "Docker image '$IMAGE_NAME' built successfully."
echo "To run the container, use the following command:"
echo
echo "docker run -d --name <container-name> -p 8080:80 $IMAGE_NAME"
