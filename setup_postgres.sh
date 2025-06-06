#!/bin/bash
set -a
source .env
set +a

psql -U "$DB_USER" -d "$DB_NAME" -c "DROP TABLE IF EXISTS force_data;"
psql -U "$DB_USER" -d "$DB_NAME" -c "DROP TABLE IF EXISTS samples;"
psql -U "$DB_USER" -d "$DB_NAME" <<EOF
CREATE TABLE samples (
  sample_id TEXT PRIMARY KEY,
  width NUMERIC,
  thickness NUMERIC,
  length NUMERIC,
  material TEXT,
  yield_strength NUMERIC,
  uts NUMERIC,
  elongation NUMERIC
);

CREATE TABLE force_data (
  id SERIAL PRIMARY KEY,
  sample_id TEXT REFERENCES samples(sample_id),
  displacement NUMERIC,
  force NUMERIC
);
EOF

# for f in "$DATA_PATH"/*.csv; do
#   psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY samples(sample_id, width, thickness, length, data) FROM '$f' WITH CSV HEADER;"
# done

# preprocessing the csv files into separate files for scalar and vector data
mkdir -p preprocessed_postgres

python3 <<EOF
import os
import csv

data_path = os.getenv("DATA_PATH")
sample_out = open("preprocessed_postgres/samples.csv", "w", newline="")
force_out = open("preprocessed_postgres/force_data.csv", "w", newline="")
sw = csv.writer(sample_out)
fw = csv.writer(force_out)
sw.writerow(["sample_id", "width(mm)", "thickness(mm)", "length(mm)"]) # keeping the units of the dimensions
fw.writerow(["sample_id", "displacement(mm)", "force(N)"]) # keeping the units of displacement

for fname in os.listdir(data_path):
    if not fname.endswith(".csv"): continue
    sample_id = fname.replace(".csv", "")
    with open(os.path.join(data_path, fname)) as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            if i == 0:
                sw.writerow([sample_id, row["width"], row["thickness"], row["length"]])
            fw.writerow([sample_id, row["mm"], row["N"]])
EOF

# Importing the preprocessed data into PostgreSQL
psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY samples(sample_id, width, thickness, length) FROM 'preprocessed_postgres/samples.csv' WITH CSV HEADER;"
psql -U "$DB_USER" -d "$DB_NAME" -c "\COPY force_data(sample_id, displacement, force) FROM 'preprocessed_postgres/force_data.csv' WITH CSV HEADER;"
