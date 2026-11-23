#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying Contracts Repository Purity (ADR-0015, LAB-108) ==="

FORBIDDEN_PATTERNS=(
  "@Entity"
  "@Table"
  "@Repository"
  "@Service"
  "@Component"
  "org.springframework.data"
  "org.springframework.stereotype"
  "jakarta.persistence"
  "javax.persistence"
)

VIOLATIONS=0

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if grep -rn --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="target" "$pattern" openapi/ avro/ asyncapi/ generators/ 2>/dev/null; then
    echo "ERROR: Found forbidden domain/persistence pattern: $pattern"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done

# Check that avro/ and asyncapi/ have no schema files before LAB-50
AVRO_COUNT=$(find avro/ -type f -name "*.avsc" 2>/dev/null | wc -l)
ASYNCAPI_COUNT=$(find asyncapi/ -type f \( -name "*.yaml" -o -name "*.json" \) 2>/dev/null | wc -l)

if [ "$AVRO_COUNT" -gt 0 ]; then
  echo "WARNING: avro/ contains $AVRO_COUNT schemas. Before LAB-50 this directory should remain empty of active schemas."
fi

if [ "$ASYNCAPI_COUNT" -gt 0 ]; then
  echo "WARNING: asyncapi/ contains $ASYNCAPI_COUNT specifications. Before LAB-50 this directory should remain empty."
fi

if [ "$VIOLATIONS" -eq 0 ]; then
  echo "SUCCESS: Repository contains only contract specifications and generator tooling. Domain purity verified."
  exit 0
else
  echo "FAILURE: Contracts repository purity check failed with $VIOLATIONS violations."
  exit 1
fi
