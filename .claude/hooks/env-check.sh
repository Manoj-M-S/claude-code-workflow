#!/usr/bin/env bash
#
# env-check.sh — runs at session start to verify that local environment variables
# are aligned with the project's example environment configuration.
#
# It compares .env.local against .env.example (or .env vs .env.example) and alerts
# if any keys are missing, preventing runtime failures.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

EXAMPLE_FILE=".env.example"
LOCAL_FILE=".env.local"

# If there's no .env.example, we can't perform alignment check.
[ -f "$EXAMPLE_FILE" ] || exit 0

if [ ! -f "$LOCAL_FILE" ] && [ -f ".env" ]; then
  # Fallback to .env if .env.local doesn't exist
  LOCAL_FILE=".env"
fi

if [ ! -f "$LOCAL_FILE" ]; then
  echo "⚠️  Warning: Local environment file ($LOCAL_FILE) is missing." >&2
  echo "   You should create it based on $EXAMPLE_FILE to avoid runtime errors." >&2
  exit 0
fi

# Compare keys using a simple node script
missing_keys="$(node -e '
  const fs = require("fs");
  const parseKeys = (path) => {
    try {
      const content = fs.readFileSync(path, "utf8");
      return new Set(
        content.split("\n")
          .map(line => line.trim())
          .filter(line => line && !line.startsWith("#"))
          .map(line => line.split("=")[0].trim())
          .filter(Boolean)
      );
    } catch (e) {
      return new Set();
    }
  };

  const exampleKeys = parseKeys(process.argv[1]);
  const localKeys = parseKeys(process.argv[2]);
  
  const missing = [...exampleKeys].filter(key => !localKeys.has(key));
  if (missing.length > 0) {
    console.log(missing.join("\n"));
    process.exit(1);
  }
' "$EXAMPLE_FILE" "$LOCAL_FILE" 2>/dev/null || true)"

if [ -n "$missing_keys" ]; then
  echo "⚠️  Environment Configuration Mismatch!" >&2
  echo "   The following keys are defined in $EXAMPLE_FILE but missing from $LOCAL_FILE:" >&2
  while read -r key; do
    echo "   - $key" >&2
  done <<< "$missing_keys"
  echo "   Please add these keys to your local configuration." >&2
  echo
fi

exit 0
