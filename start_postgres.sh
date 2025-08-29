#!/bin/bash
set -e

# -------------------------
# Dynamic Postgres Dev Setup (via Docker Compose)
# -------------------------

# 1. SQL folder on host
SQL_DIR="$(realpath ./dwh)"   # absolute path required for docker-compose mount
if [[ ! -d "$SQL_DIR" ]]; then
    echo "SQL folder not found: $SQL_DIR"
    exit 1
fi

export SQL_DIR 

# Ensure all SQL files are readable by Docker
chmod -R 755 "$SQL_DIR"

# 2. Generate dynamic credentials

PG_USER="devuser_$(date +%s | sha256sum | head -c 6)"
PG_PASSWORD="$(date +%s | sha256sum | head -c 12)"
PG_DB="devdb_$(date +%s | sha256sum | head -c 6)"
PG_PORT=$((5432 + RANDOM % 1000))
CONTAINER_NAME="postgres_${PG_USER}"
VOLUME_NAME="pgdata_${PG_USER}"


# Inject dynamic DB name into init.sql
sed -i "s/__PG_DB__/$PG_DB/" "$SQL_DIR/init/init.sql"


# 2. Create working docker-compose file
COMPOSE_FILE="docker-compose-${PG_USER}.yml"
export PG_USER PG_PASSWORD PG_DB PG_PORT CONTAINER_NAME VOLUME_NAME
envsubst < docker-compose.yml.template > $COMPOSE_FILE

# 3. Start container with a unique project name
PROJECT_NAME="proj_${PG_USER}"

# 4. Start Postgres via Docker Compose
echo "Starting Postgres ($CONTAINER_NAME) on port $PG_PORT..."
docker compose -p $PROJECT_NAME -f $COMPOSE_FILE up -d

# 5. Wait for Postgres to be ready
echo "⏳ Waiting for Postgres to start..."
sleep 5

# 6. Save connection details to JSON
JSON_FILE="pg_connection_${PG_USER}.json"
cat <<EOF > $JSON_FILE
{
  "username": "$PG_USER",
  "password": "$PG_PASSWORD",
  "database": "$PG_DB",
  "port": $PG_PORT,
  "host": "localhost",
  "container": "$CONTAINER_NAME",
  "volume": "$VOLUME_NAME",
  "compose_file": "$COMPOSE_FILE",
  "connection_string": "postgresql://$PG_USER:$PG_PASSWORD@localhost:$PG_PORT/$PG_DB"
}
EOF

# 7. Print connection info
echo "----------------------------"
echo "Postgres Dev Instance Ready!"
echo "----------------------------"
cat $JSON_FILE
echo "----------------------------"
echo "Connection details saved to $JSON_FILE"

# 8. Revert to Original init.sql
sed -i "s/$PG_DB/__PG_DB__/" "$SQL_DIR/init/init.sql"