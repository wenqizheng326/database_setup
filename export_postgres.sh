#!/bin/bash
set -a
source .env
set +a

mkdir -p exported_postgres
mkdir -p exported_postgres/csv
mkdir -p exported_postgres/json


echo "Select export format for PostgreSQL (csv / json / both): "    #prompting the user for export type
read -r format

if [[ "$format" == "csv" || "$format" == "both" ]]; then
  echo "Exporting data to CSV..."
  psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY samples TO 'exported_postgres/csv/exported_samples.csv' CSV HEADER;"
  psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY force_data TO 'exported_postgres/csv/exported_force_data.csv' CSV HEADER;"
fi

if [[ "$format" == "json" || "$format" == "both" ]]; then
  echo "Exporting data to JSON..."
  psql -U "$DB_USER" -d "$DB_NAME" -t -A -c "SELECT json_agg(samples) FROM samples;" > exported_postgres/json/exported_samples.json # -t -A to get rid column/row formatting (saves clean, raw json data)
  psql -U "$DB_USER" -d "$DB_NAME" -t -A -c "SELECT json_agg(force_data) FROM force_data;" > exported_postgres/json/exported_force_data.json # -t -A to get rid column/row formatting (saves clean, raw json data)
  
  # file clean up
  jq '.' exported_postgres/json/exported_samples.json > tmp && mv tmp exported_postgres/json/exported_samples.json # rmp && mv stores and removes the original (ugly) file  
  jq '.' exported_postgres/json/exported_force_data.json > tmp && mv tmp exported_postgres/json/exported_force_data.json # rmp && mv stores and removes the original (ugly) file  
fi

