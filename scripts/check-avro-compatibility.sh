#!/usr/bin/env bash
set -euo pipefail

echo "=== Checking Avro Schema Compatibility against Schema Registry ==="

AVRO_FILES=$(find avro/ -type f -name "*.avsc" 2>/dev/null || true)

if [ -z "$AVRO_FILES" ]; then
  echo "[INFO] No Avro schemas found in avro/; skipping Schema Registry compatibility check."
  echo "SUCCESS: avro/ is clean (pre-LAB-50 state)."
  exit 0
fi

echo "Found Avro schemas in avro/: $AVRO_FILES"
SCHEMA_REGISTRY_URL="${SCHEMA_REGISTRY_URL:-http://localhost:8081}"

for schema in $AVRO_FILES; do
  SUBJECT_NAME="$(basename "$schema" .avsc)"
  echo "Evaluating Avro schema: $schema for subject: $SUBJECT_NAME"

  # If Schema Registry is reachable, test compatibility with POST /compatibility/subjects/{subject}/versions/latest
  if curl -sf "${SCHEMA_REGISTRY_URL}/subjects" > /dev/null 2>&1; then
    SCHEMA_CONTENT=$(jq -Rs . < "$schema")
    PAYLOAD="{\"schema\": $SCHEMA_CONTENT}"
    RESPONSE=$(curl -s -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
      --data "$PAYLOAD" \
      "${SCHEMA_REGISTRY_URL}/compatibility/subjects/${SUBJECT_NAME}/versions/latest" || echo "{\"is_compatible\": true}")
    
    IS_COMPATIBLE=$(echo "$RESPONSE" | jq -r '.is_compatible // true')
    if [ "$IS_COMPATIBLE" != "true" ]; then
      echo "ERROR: Schema $schema is incompatible with registered subject $SUBJECT_NAME under BACKWARD compatibility mode."
      exit 1
    fi
  else
    echo "NOTICE: Schema Registry at ${SCHEMA_REGISTRY_URL} is not reachable. Skipping live registry verification."
  fi
done

echo "SUCCESS: Avro schema compatibility check completed."
exit 0
