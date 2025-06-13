#!/bin/bash
set -a
source .env
set +a

echo "Creating tables if they don't exist..."

psql -U "$DB_USER" -d "$DB_NAME" <<EOF
CREATE TABLE IF NOT EXISTS samples (
  sample_id TEXT PRIMARY KEY,
  width NUMERIC,
  thickness NUMERIC,
  length NUMERIC
);

CREATE TABLE IF NOT EXISTS force_data (
  id SERIAL PRIMARY KEY,
  sample_id TEXT REFERENCES samples(sample_id),
  displacement NUMERIC,
  force NUMERIC
);

CREATE TABLE IF NOT EXISTS extracted_properties (
  sample_id TEXT PRIMARY KEY REFERENCES samples(sample_id),
  youngs_modulus NUMERIC,
  ultimate_tensile_strength NUMERIC
);
EOF

echo "Processing JSON files from dictionary/ and inserting into tables..."

python3 <<EOF
import os, json
from subprocess import run

dict_dir = "FAIRtrain-schema/dictionary"
db_user = os.getenv("DB_USER")
db_name = os.getenv("DB_NAME")

for fname in os.listdir(dict_dir):
    if not fname.endswith(".json"): continue
    fpath = os.path.join(dict_dir, fname)
    with open(fpath) as f:
        try:
            record = json.load(f)
        except Exception as e:
            print(f"Failed to parse {fname}: {e}")
            continue

    sid = record.get("sample_id")
    width = record.get("width")
    thickness = record.get("thickness")
    length = record.get("length")

    # Insert into samples
    run(["psql", "-U", db_user, "-d", db_name, "-c",
        f"INSERT INTO samples (sample_id, width, thickness, length) VALUES ('{sid}', {width}, {thickness}, {length}) ON CONFLICT DO NOTHING;"])

    # Insert into force_data
    for row in record.get("data", []):
        mm = row.get("mm")
        force = row.get("N")
        run(["psql", "-U", db_user, "-d", db_name, "-c",
            f"INSERT INTO force_data (sample_id, displacement, force) VALUES ('{sid}', {mm}, {force});"])

    # Insert into extracted_properties
    props = record.get("extracted_properties", {})
    E = props.get("youngs_modulus")
    uts = props.get("ultimate_tensile_strength")
    run(["psql", "-U", db_user, "-d", db_name, "-c",
        f"INSERT INTO extracted_properties (sample_id, youngs_modulus, ultimate_tensile_strength) VALUES ('{sid}', {E}, {uts}) ON CONFLICT DO NOTHING;"])
EOF

echo "All done."
