#!/bin/bash
set -a
source .env
set +a

psql -U "$DB_USER" -d "$DB_NAME" -c "DROP TABLE IF EXISTS samples;"
psql -U "$DB_USER" -d "$DB_NAME" <<EOF
CREATE TABLE samples (
  sample_id TEXT,
  width NUMERIC,
  thickness NUMERIC,
  length NUMERIC,
  data TEXT
);
EOF

for f in "$DATA_PATH"/*.csv; do
  psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY samples(sample_id, width, thickness, length, data) FROM '$f' WITH CSV HEADER;"
done
