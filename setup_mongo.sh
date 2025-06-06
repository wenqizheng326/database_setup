#!/bin/bash
set -a
source .env
set +a

mongosh "$MONGO_DB" --eval '
db.createCollection("samples", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "sample_id",
      "width",
      "thickness",
      "length",
      "data"
    ],
    "properties": {
      "sample_id": {
        "bsonType": "string"
      },
      "width": {
        "bsonType": ["int", "double"]
      },
      "thickness": {
        "bsonType": ["int", "double"]
      },
      "length": {
        "bsonType": ["int", "double"]
      },
      data: {
        bsonType: "array",
        items: {
          bsonType: "object",
          required: ["mm", "N"],
          properties: {
            mm: { bsonType: ["int", "double"] },
            N: { bsonType: ["int", "double"] }
          }
        }
        }
    }
  }
}
});
'

# preprocessing the csv files into separate files for scalar and vector data
mkdir -p preprocessed_mongo

python3 <<EOF
import os
import csv
import json

data_path = os.getenv("DATA_PATH")
out_dir = "preprocessed_mongo"
os.makedirs(out_dir, exist_ok=True)

for fname in os.listdir(data_path):
    if not fname.endswith(".csv"): continue
    with open(os.path.join(data_path, fname)) as f:
        sample_id = fname.replace(".csv", "")
        reader = csv.DictReader(f)
        data = []
        dimensions = {}
        for i, row in enumerate(reader):
            if i == 0:
                dimensions = {
                    "sample_id": sample_id,
                    "width": float(row["width"]),
                    "thickness": float(row["thickness"]),
                    "length": float(row["length"]),
                }
            data.append({"mm": float(row["mm"]), "N": float(row["N"])})
        dimensions["data"] = data
        with open(f"{out_dir}/{sample_id}.json", "w") as out:
            json.dump(dimensions, out)
EOF


# import the preprocessed JSON files into MongoDB
for f in preprocessed_mongo/*.json; do
  mongoimport --db "$MONGO_DB" --collection samples --file "$f" --mode=upsert --upsertFields=sample_id # upsert means update the document if it exists, otherwise insert a new one
done



# import the dictionaries files into MongoDB
for f in "$DICT_PATH"/*.json; do
  mongoimport --db "$MONGO_DB" --collection dictionaries --file "$f" --mode=upsert
done

# shell script to select specific data into csv and json files 

# for f in "$DATA_PATH"/*.csv; do
#   name=$(basename "$f" .csv)
#   mongoimport --db "$MONGO_DB" --collection "$name" --type csv --headerline --file "$f"
# done

# for f in "$DICT_PATH"/*.json; do
#   mongoimport --db "$MONGO_DB" --collection dictionaries --file "$f" --jsonArray
# done
