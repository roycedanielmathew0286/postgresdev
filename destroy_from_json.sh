#!/bin/bash
set -e

# Directory where connection JSONs are stored
JSON_DIR="./"

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "❌ jq is required but not installed."
  exit 1
fi

# Loop through all pg_connection_*.json files
for FILE in $JSON_DIR/pg_connection_*.json; do
  [ -e "$FILE" ] || continue  # skip if no files

  echo "🔻 Processing $FILE"

  # Extract details
  CONTAINER_NAME=$(jq -r '.container' "$FILE")
  VOLUME_NAME=$(jq -r '.volume' "$FILE")
  PG_USER=$(jq -r '.username' "$FILE")
  DOCKER_COMPOSE=$(jq -r '.compose_file' "$FILE") 

  echo "  Developer: $PG_USER"
  echo "  Container: $CONTAINER_NAME"
  echo "  Volume:    $VOLUME_NAME"
  echo "  DockerCompose: $DOCKER_COMPOSE"

  # Remove container
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker rm -f "$CONTAINER_NAME"
    echo "  ✅ Removed container: $CONTAINER_NAME"
  else
    echo "  ⚠️ Container $CONTAINER_NAME not found."
  fi
#
  ## Remove volume
  if docker volume ls --format '{{.Name}}' | grep -q "^${VOLUME_NAME}$"; then
    docker volume rm "$VOLUME_NAME"
    echo "  ✅ Removed volume: $VOLUME_NAME"
  else
    echo "  ⚠️ Volume $VOLUME_NAME not found."
  fi
#

  ## Remove Docker Compose file (optional cleanup)
  rm -f "$DOCKER_COMPOSE"
  echo "  🗑️ Deleted Docker Compose file: $DOCKER_COMPOSE"

  ## Remove JSON file (optional cleanup)
  rm -f "$FILE"
  echo "  🗑️ Deleted JSON file: $FILE"
#
  #echo
done

echo "🎉 All developer Postgres instances destroyed."