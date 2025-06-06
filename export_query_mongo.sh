#!/bin/bash
set -a
source .env
set +a

mkdir -p exported_query
mkdir -p exported_query/mongo

echo "Choose MongoDB export option:"
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
    mongoexport \
      --uri "$MONGO_URI" \
      --db "$MONGO_DB" \
      --collection samples \
      --type=csv \
      --fields sample_id,width,thickness,length,material,yield_strength,uts,elongation \
      --query "{\"sample_id\": \"$sampleId\"}" \
      --out exported_query/mongo/mongo_sample_${sampleId}.csv
    ;;
  2)
    mongoexport \
      --uri "$MONGO_URI" \
      --db "$MONGO_DB" \
      --collection samples \
      --type=csv \
      --fields sample_id,width,thickness,length,material,yield_strength,uts,elongation \
      --query '{"sample_id": {"$regex": "groupA"}}' \
      --out exported_query/mongo/mongo_groupA.csv
    ;;
  3)
    sampleId=$(mongosh "$MONGO_DB" --quiet --eval 'db.samples.find().sort({uts:-1}).limit(1).map(s=>s.sample_id)[0]')
    mongoexport \
      --uri "$MONGO_URI" \
      --db "$MONGO_DB" \
      --collection samples \
      --type=csv \
      --fields sample_id,width,thickness,length,material,yield_strength,uts,elongation \
      --query "{\"sample_id\": \"$sampleId\"}" \
      --out exported_query/mongo/mongo_max_uts.csv
    ;;
  4)
    sampleIds=$(mongosh "$MONGO_DB" --quiet --eval '
      db.samples.find().sort({uts:-1}).limit(5).map(s=>s.sample_id).join(",")
    ')
    IFS=',' read -ra ids <<< "$sampleIds"
    for i in "${!ids[@]}"; do
      mongoexport \
        --uri "$MONGO_URI" \
        --db "$MONGO_DB" \
        --collection samples \
        --type=csv \
        --fields sample_id,width,thickness,length,material,yield_strength,uts,elongation \
        --query "{\"sample_id\": \"${ids[$i]}\"}" \
        --out exported_query/mongo/mongo_top5_uts_$i.csv
    done
    ;;
  5)
    sampleIds=$(mongosh "$MONGO_DB" --quiet --eval '
      db.samples.find({sample_id: {$regex: "groupA"}}).sort({uts:-1}).limit(5).map(s=>s.sample_id).join(",")
    ')
    IFS=',' read -ra ids <<< "$sampleIds"
    for i in "${!ids[@]}"; do
      mongoexport \
        --uri "$MONGO_URI" \
        --db "$MONGO_DB" \
        --collection samples \
        --type=csv \
        --fields sample_id,width,thickness,length,material,yield_strength,uts,elongation \
        --query "{\"sample_id\": \"${ids[$i]}\"}" \
        --out exported_query/mongo/mongo_top5_groupA_uts_$i.csv
    done
    ;;
  *)
    echo "Invalid option."
    exit 1
    ;;
esac
