#!/bin/bash

# Function to get the game name by appid using Steam's API
get_game_name() {
  local appid=$1
  # Fetch the data from Steam API and filter out null bytes
  local response=$(curl -s "https://store.steampowered.com/api/appdetails?appids=${appid}" | tr -d '\000')

  # Extract the game name using jq
  local game_name=$(echo "$response" | jq -r ".\"$appid\".data.name // empty")
  
  # Return the game name if it's not empty
  if [ -n "$game_name" ]; then
    echo "$game_name"
  else
    echo ""
  fi
}

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

# Get a list of all prefix IDs in the compatdata directory
prefix_ids=($(ls -d "$COMPATDATA_DIR"/* | xargs -n 1 basename))

# Loop through each prefix ID and delete if not in installed app IDs
for prefix_id in "${prefix_ids[@]}"; do
  # Skip prefix ID 0 explicitly
  if [ "$prefix_id" -eq 0 ]; then
    continue
  fi

  game_name=$(get_game_name "$prefix_id")
  
  # Skip blank game names, which could indicate Proton-related prefixes
  if [ -z "$game_name" ]; then
    continue
  fi

  # Ask for confirmation before deleting
  if [[ ! " ${installed_app_ids[@]} " =~ " ${prefix_id} " ]]; then
    echo "Found orphan prefix $prefix_id: $game_name"
    read -p "Do you want to delete this prefix? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "Deleting unused prefix: $prefix_id"
      rm -rf "$COMPATDATA_DIR/$prefix_id"
    else
      echo "Skipping deletion of prefix: $prefix_id"
    fi
  fi
done

echo "Cleanup complete."
