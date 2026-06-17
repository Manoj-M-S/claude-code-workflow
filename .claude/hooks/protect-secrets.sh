#!/usr/bin/env bash
#
# protect-secrets.sh — PreToolUse hook (matcher: Read|Bash).
#
# Prevents Claude from reading secret files (.env, private keys, credentials).
# For a Read tool call, inspects tool_input.file_path.
# For a Bash tool call, inspects tool_input.command.
# Exits 2 with an actionable stderr message on violation; exits 0 silently otherwise.

set -uo pipefail

INPUT="$(cat)"

# Parse tool name and relevant field from stdin JSON.
eval "$(printf '%s' "$INPUT" | node -e '
  let d = "";
  process.stdin.on("data", c => d += c).on("end", () => {
    try {
      const o = JSON.parse(d);
      const name = o.tool_name || "";
      const inp = o.tool_input || {};
      const fp = inp.file_path || "";
      const cmd = inp.command || "";
      // Shell-safe: replace single quotes
      const esc = s => s.replace(/\x27/g, "\x27\\\x27\x27");
      console.log("TOOL_NAME=\x27" + esc(name) + "\x27");
      console.log("FILE_PATH=\x27" + esc(fp) + "\x27");
      console.log("COMMAND=\x27" + esc(cmd) + "\x27");
    } catch (e) {
      console.log("TOOL_NAME=\x27\x27");
      console.log("FILE_PATH=\x27\x27");
      console.log("COMMAND=\x27\x27");
    }
  });
')"

# --- helper: check if a path matches a secret pattern ---
is_secret_path() {
  local p="$1"
  local base
  base="$(basename "$p")"

  # Allow .env.example explicitly
  case "$base" in
    .env.example|env.example) return 1 ;;
  esac

  # Secret file patterns
  case "$base" in
    .env|.env.*) return 0 ;;
    id_rsa|id_rsa.*|id_ed25519|id_ed25519.*) return 0 ;;
    credentials|credentials.*) return 0 ;;
  esac

  case "$p" in
    *.pem|*.key|*.p12) return 0 ;;
    */.ssh/*) return 0 ;;
    */credentials|*/credentials.*) return 0 ;;
  esac

  return 1
}

# --- Read tool: check file_path ---
if [ "$TOOL_NAME" = "Read" ] && [ -n "$FILE_PATH" ]; then
  if is_secret_path "$FILE_PATH"; then
    echo "Blocked: reading secret file \`$FILE_PATH\` is not allowed." >&2
    echo "Use environment variables or ask the user for the specific value instead of reading the file directly." >&2
    exit 2
  fi
fi

# --- Bash tool: check command for secret-reading patterns ---
if [ "$TOOL_NAME" = "Bash" ] && [ -n "$COMMAND" ]; then
  # Check if the command references secret files via common read utilities
  secret_hit="$(printf '%s' "$COMMAND" | node -e '
    let d = "";
    process.stdin.on("data", c => d += c).on("end", () => {
      // Utilities that read file contents
      const readers = "cat|grep|head|tail|less|more|cp|mv|source|\\.|bat|type";
      // Secret file patterns (excluding .env.example)
      const secretPatterns = [
        /(?:^|\s|\/)(\.env)(?:\s|$|[;|&])/,
        /(?:^|\s|\/)(\.env\.[a-zA-Z0-9_]+)(?:\s|$|[;|&])/,
        /\bid_rsa\b/,
        /\bid_ed25519\b/,
        /\.pem\b/,
        /\.key\b/,
        /\.p12\b/,
        /\/\.ssh\//,
        /\/credentials\b/,
      ];

      // Check for reader + secret combos
      const readerRe = new RegExp("\\b(" + readers + ")\\b");
      if (!readerRe.test(d)) { process.exit(0); }

      // Exclude .env.example
      if (/\.env\.example\b/.test(d) && !/\.env\.(?!example)[a-zA-Z0-9_]+/.test(d) && !/(?:^|\s|\/)(\.env)(?:\s|$|[;|&])/.test(d)) {
        process.exit(0);
      }

      for (const pat of secretPatterns) {
        if (pat.test(d)) {
          console.log("match");
          process.exit(0);
        }
      }
    });
  ' 2>/dev/null || true)"

  if [ "$secret_hit" = "match" ]; then
    echo "Blocked: the command appears to read a secret file (.env, private key, credentials, etc.)." >&2
    echo "Use environment variables or ask the user for the specific value instead of reading the file directly." >&2
    exit 2
  fi
fi

exit 0
