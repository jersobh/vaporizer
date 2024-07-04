#!/bin/bash

# Check if the Steam directory is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/steam/directory"
  exit 1
fi

# Define Steam directories
STEAM_DIR="$1"
STEAM_APPS_DIR="$STEAM_DIR/steamapps"
COMPATDATA_DIR="$STEAM_APPS_DIR/compatdata"
ACF_FILES_DIR="$STEAM_APPS_DIR"

# Check if the provided Steam directory exists
if [ ! -d "$STEAM_DIR" ]; then
  echo "The specified Steam directory does not exist: $STEAM_DIR"
  exit 1
fi

# Get a list of installed app IDs from ACF files
installed_app_ids=($(grep -hoP '^\s*"appid"\s*"\K[0-9]+' "$ACF_FILES_DIR"/*.acf))

# Add appid 0 to the list of installed app IDs to avoid deletion
installed_app_ids+=(0)

# Get a list of all prefix IDs in the compatdata directory
prefix_ids=($(ls -d "$COMPATDATA_DIR"/* | xargs -n 1 basename))

# Loop through each prefix ID and delete if not in installed app IDs
for prefix_id in "${prefix_ids[@]}"; do
  if [[ ! " ${installed_app_ids[@]} " =~ " ${prefix_id} " ]]; then
    echo "Deleting unused prefix: $prefix_id"
    rm -rf "$COMPATDATA_DIR/$prefix_id"
  fi
done

echo "Cleanup complete."
