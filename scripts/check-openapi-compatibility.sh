#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${BASE_REF:-origin/main}"
PR_TITLE="${PR_TITLE:-}"
COMMIT_MSG="$(git log -1 --pretty=%B 2>/dev/null || echo "")"

# Normalize short branch names (e.g. github.base_ref = "main") to origin/<branch> when needed.
if [[ "$BASE_REF" != origin/* ]] && ! git rev-parse --verify "$BASE_REF" &>/dev/null; then
  if git rev-parse --verify "origin/${BASE_REF}" &>/dev/null; then
    BASE_REF="origin/${BASE_REF}"
  fi
fi

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
  OASDIFF_VERSION="1.11.7"
  curl -fsSL "https://github.com/oasdiff/oasdiff/releases/download/v${OASDIFF_VERSION}/oasdiff_${OASDIFF_VERSION}_linux_amd64.tar.gz" | tar -xz -C /usr/local/bin oasdiff 2>/dev/null || \
  curl -fsSL "https://github.com/oasdiff/oasdiff/releases/download/v${OASDIFF_VERSION}/oasdiff_${OASDIFF_VERSION}_linux_amd64.tar.gz" | tar -xz oasdiff && chmod +x oasdiff && mv oasdiff /usr/local/bin/ || true
fi

if ! command -v oasdiff &> /dev/null; then
  echo "Fallback: installing oasdiff with go..."
  go install github.com/oasdiff/oasdiff@latest || true
fi

if ! command -v oasdiff &> /dev/null; then
  echo "ERROR: oasdiff could not be found or installed."
  exit 1
fi

TOTAL_BREAKING=0
TOTAL_INVALID=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

OPENAPI_FILES=$(find openapi/ -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) | sort)

if [ -z "$OPENAPI_FILES" ]; then
  echo "ERROR: No OpenAPI specification files found under openapi/."
  exit 1
fi

for spec in $OPENAPI_FILES; do
  echo "Evaluating spec: $spec"

  # Always verify OpenAPI syntax/validity first
  if ! SYNTAX_ERR=$(oasdiff changelog "$spec" "$spec" 2>&1); then
    echo "ERROR: Invalid OpenAPI specification in $spec:"
    echo "$SYNTAX_ERR"
    TOTAL_INVALID=$((TOTAL_INVALID + 1))
    continue
  fi

  # Check if baseline file exists in BASE_REF
  if git rev-parse --verify "$BASE_REF" &>/dev/null && git cat-file -e "${BASE_REF}:${spec}" 2>/dev/null; then
    BASE_FILE="$TMP_DIR/base_$(echo "$spec" | tr '/' '_')"
    git show "${BASE_REF}:${spec}" > "$BASE_FILE"

    BREAKING_OUTPUT=$(oasdiff breaking "$BASE_FILE" "$spec" --format text 2>&1) || true

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
    echo "OK: No baseline found in $BASE_REF for $spec (new contract); syntax is valid."
  fi
done

if [ "$TOTAL_INVALID" -gt 0 ]; then
  echo "ERROR: $TOTAL_INVALID spec(s) failed OpenAPI syntax/schema validation."
  exit 1
fi

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

echo "SUCCESS: All OpenAPI specifications passed syntax and backward compatibility verification."
exit 0
