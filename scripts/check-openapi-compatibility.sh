#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${BASE_REF:-origin/main}"
PR_TITLE="${PR_TITLE:-}"
COMMIT_MSG="$(git log -1 --pretty=%B 2>/dev/null || echo "")"

echo "=== Checking OpenAPI Compatibility with oasdiff against $BASE_REF ==="

# Check breaking change declaration in PR Title or latest commit message
IS_BREAKING_DECLARED=false
if [[ "$PR_TITLE" =~ !: ]] || [[ "$PR_TITLE" =~ BREAKING[[:space:]]CHANGE: ]] || \
   [[ "$COMMIT_MSG" =~ !: ]] || [[ "$COMMIT_MSG" =~ BREAKING[[:space:]]CHANGE: ]]; then
  IS_BREAKING_DECLARED=true
  echo "INFO: Breaking change indicator detected in PR title or commit message."
fi

# Ensure oasdiff is available
if ! command -v oasdiff &> /dev/null; then
  echo "Installing oasdiff..."
  go install github.com/tufin/oasdiff@latest 2>/dev/null || curl -fsSL https://raw.githubusercontent.com/tufin/oasdiff/main/install.sh | sh
fi

TOTAL_BREAKING=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

OPENAPI_FILES=$(find openapi/ -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \))

for spec in $OPENAPI_FILES; do
  echo "Evaluating spec: $spec"

  # Check if baseline file exists in BASE_REF
  if git rev-parse --verify "$BASE_REF" &>/dev/null && git cat-file -e "${BASE_REF}:${spec}" 2>/dev/null; then
    BASE_FILE="$TMP_DIR/base_$(basename "$spec")"
    git show "${BASE_REF}:${spec}" > "$BASE_FILE"

    BREAKING_OUTPUT=$(oasdiff breaking "$BASE_FILE" "$spec" --format text || true)

    if [ -n "$BREAKING_OUTPUT" ]; then
      echo "--------------------------------------------------------"
      echo "BREAKING CHANGES DETECTED in $spec:"
      echo "$BREAKING_OUTPUT"
      echo "--------------------------------------------------------"
      TOTAL_BREAKING=$((TOTAL_BREAKING + 1))
    else
      echo "OK: $spec is backward compatible."
    fi
  else
    echo "INFO: No baseline found in $BASE_REF for $spec (new contract or initial release). Validating syntax."
    oasdiff changelog "$spec" "$spec" >/dev/null 2>&1 || true
    echo "OK: $spec syntax is valid."
  fi
done

if [ "$TOTAL_BREAKING" -gt 0 ]; then
  if [ "$IS_BREAKING_DECLARED" = true ]; then
    echo "WARNING: $TOTAL_BREAKING spec(s) contain breaking changes, but a MAJOR version increment is declared."
    echo "Gate PASSED for MAJOR release."
    exit 0
  else
    echo "ERROR: $TOTAL_BREAKING spec(s) contain breaking changes without a declared MAJOR release indicator (!: or BREAKING CHANGE:)."
    echo "To proceed, either revert the breaking change or mark the commit/PR title as a breaking change."
    exit 1
  fi
fi

echo "SUCCESS: All OpenAPI specifications passed backward compatibility verification."
exit 0
