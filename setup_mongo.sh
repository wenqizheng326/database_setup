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
      "data",
      "extracted_properties"
    ],
    "properties": {
      "sample_id": {
        "bsonType": "string"
      },
      "width": {
        "bsonType": "double"
      },
      "thickness": {
        "bsonType": "double"
      },
      "length": {
        "bsonType": "double"
      },
      "data": {
        "bsonType": "string"
      },
      "extracted_properties": {
        "bsonType": "string"
      }
    }
  }
}
});
'

for f in "$DATA_PATH"/*.csv; do
  name=$(basename "$f" .csv)
  mongoimport --db "$MONGO_DB" --collection "$name" --type csv --headerline --file "$f"
done

for f in "$DICT_PATH"/*.json; do
  mongoimport --db "$MONGO_DB" --collection dictionaries --file "$f" --jsonArray
done
