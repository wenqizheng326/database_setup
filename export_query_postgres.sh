#!/bin/bash
set -a
source .env
set +a

mkdir -p exported_query
mkdir -p exported_query/postgres

echo "Choose PostgreSQL export option:"
echo "1. Record with a given sampleId"
echo "2. All records with 'groupA' in sampleId"
echo "3. Record with max UTS"
echo "4. Top 5 records with highest UTS"
echo "5. Top 5 records with 'groupA' in sampleId and highest UTS"
read -r query_choice

case "$query_choice" in
  1)
    echo "Enter sampleId:"
    read -r sampleId
    psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY (
      SELECT * FROM samples WHERE sample_id = '$sampleId'
    ) TO 'exported_query/postgres/postgres_sample_${sampleId}.csv' WITH CSV HEADER;"
    ;;
  2)
    psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY (
      SELECT * FROM samples WHERE sample_id LIKE '%groupA%'
    ) TO 'exported_query/postgres/postgres_groupA.csv' WITH CSV HEADER;"
    ;;
  3)
    psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY (
      SELECT * FROM samples ORDER BY uts DESC LIMIT 1
    ) TO 'exported_query/postgres/postgres_max_uts.csv' WITH CSV HEADER;"
    ;;
  4)
    psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY (
      SELECT * FROM samples ORDER BY uts DESC LIMIT 5
    ) TO 'exported_query/postgres/postgres_top5_uts.csv' WITH CSV HEADER;"
    ;;
  5)
    psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY (
      SELECT * FROM samples WHERE sample_id LIKE '%groupA%' ORDER BY uts DESC LIMIT 5 
    ) TO 'exported_query/postgres/postgres_top5_groupA_uts.csv' WITH CSV HEADER;"
    ;;
  *)
    echo "Invalid option."
    exit 1
    ;;
esac
