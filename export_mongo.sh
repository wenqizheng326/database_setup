#!/bin/bash
set -a
source .env
set +a

mkdir -p exported_mongo
mkdir -p exported_mongo/csv
mkdir -p exported_mongo/json

echo "Select export format for MongoDB (csv / json / both):"
read -r format

FILTER='{}'

if [[ "$format" == "csv" || "$format" == "both" ]]; then
  echo "Exporting scalar data to CSV..."
  mongoexport \
    --uri "$MONGO_URI" \
    --db "$MONGO_DB" \
    --collection samples \
    --type=csv \
    --fields sample_id,width,thickness,length \
    --query "$FILTER" \
    --out exported_mongo/csv/export_samples.csv   
fi

if [[ "$format" == "json" || "$format" == "both" ]]; then
  echo "Exporting full data (including array) to JSON..."
  mongoexport \
    --uri "$MONGO_URI" \
    --db "$MONGO_DB" \
    --collection samples \
    --type=json \
    --query "$FILTER" \
    --out exported_mongo/json/export_samples.json

    # file clean up
    jq '._id = ._id["$oid"]' exported_mongo/json/export_samples.json > tmp && mv tmp exported_mongo/json/export_samples.json # rmp && mv stores and removes the original (ugly) file where _id is an object 
    jq '.' exported_mongo/json/export_samples.json > tmp && mv tmp exported_mongo/json/export_samples.json # rmp && mv stores and removes the original (ugly) file

fi

