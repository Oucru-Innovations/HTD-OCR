#!/bin/bash

# Clear .cache directory
echo "Clearing .cache directory..."
rm -rf /home/khoaldv/.cache/*

# Docker cleanup
echo "Removing stopped containers..."
docker container prune -f

echo "Removing unused images..."
docker image prune -a -f

echo "Removing unused volumes..."
docker volume prune -f

echo "Removing unused networks..."
docker network prune -f

echo "Removing all unused Docker resources..."
docker system prune -a --volumes -f

# Clear Docker build cache
echo "Clearing Docker build cache..."
docker builder prune -f

# Verify the cleanup
echo "Disk usage after cleanup:"
du -sh /home/khoaldv/.cache
du -sh /home/khoaldv/.docker
