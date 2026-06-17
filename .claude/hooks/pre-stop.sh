#!/usr/bin/env bash
#
# pre-stop.sh — runs when Claude finishes responding (Stop event).
#
# Whole-project checks that only make sense across all files at once. On failure
# it writes details to stderr and exits 2, which on a Stop hook PREVENTS Claude
# from stopping and continues the turn — so Claude keeps working until the
# project type-checks and has no duplicate function names. Clean → exit 0.
#
# Checks: TypeScript (tsc --noEmit) · duplicate exported function names.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT" || exit 0
INPUT="$(cat)"

# Re-entry guard: when this hook blocks, Claude responds again and Stop fires
# once more with stop_hook_active=true. Bail out then so we never loop forever.
ACTIVE="$(printf '%s' "$INPUT" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{process.stdout.write(String(JSON.parse(d).stop_hook_active||false))}catch(e){process.stdout.write("false")}})')"
[ "$ACTIVE" = "true" ] && exit 0

problems=()
TSC="$ROOT/node_modules/.bin/tsc"

# --- 1. TypeScript type check (whole program) ---------------------------------
if [ -f "$ROOT/tsconfig.json" ] && [ -x "$TSC" ]; then
  tscout="$("$TSC" --noEmit 2>&1)"
  if [ $? -ne 0 ]; then
    problems+=("TypeScript errors (\`tsc --noEmit\`):"$'\n'"$tscout")
  fi
fi

# --- 2. Duplicate exported function names across files ------------------------
# Flags the same exported function/const-function name defined in 2+ files.
# Same-file duplicates are already a TypeScript error, so this targets the
# cross-file case where logic was likely re-implemented instead of reused.
dupout="$(node -e '
  const fs=require("fs"),cp=require("child_process");
  let files=[];
  try{files=cp.execSync("git ls-files \"*.ts\" \"*.tsx\" \"*.js\" \"*.jsx\" \"*.mjs\"",
      {encoding:"utf8"}).split("\n").filter(Boolean);}catch(e){process.exit(0);}
  const map={};
  const pats=[
    /export\s+(?:async\s+)?function\s+([A-Za-z0-9_$]+)/g,
    /export\s+const\s+([A-Za-z0-9_$]+)\s*=\s*(?:async\s*)?(?:\([^)]*\)|[A-Za-z0-9_$]+)\s*=>/g
  ];
  for(const f of files){
    let s=""; try{s=fs.readFileSync(f,"utf8");}catch(e){continue;}
    for(const p of pats){let m;p.lastIndex=0;
      while((m=p.exec(s))){(map[m[1]]=map[m[1]]||new Set()).add(f);}}
  }
  const dups=Object.entries(map).filter(([,set])=>set.size>=2);
  for(const [n,set] of dups) console.log("  "+n+"  →  "+[...set].join(", "));
' 2>/dev/null || true)"
if [ -n "$dupout" ]; then
  problems+=("Duplicate exported function names found in multiple files — consolidate into one shared implementation and import it, instead of defining the same name twice:"$'\n'"$dupout")
fi

# --- 3. Test suite (if a test script exists) ----------------------------------
if [ -f "$ROOT/package.json" ]; then
  HAS_TEST="$(node -e 'try{const p=require("./package.json");process.exit(p.scripts&&p.scripts.test?0:1)}catch(e){process.exit(1)}' 2>/dev/null && echo yes || echo no)"
  if [ "$HAS_TEST" = "yes" ]; then
    PM="npm run"
    [ -f "$ROOT/bun.lockb" ] || [ -f "$ROOT/bun.lock" ] && PM="bun run"
    [ -f "$ROOT/pnpm-lock.yaml" ] && PM="pnpm run"
    [ -f "$ROOT/yarn.lock" ] && PM="yarn"
    # --run avoids watch mode in vitest; fall back to plain test if --run isn't supported
    testout="$($PM test -- --run 2>&1)"
    rc=$?
    if [ $rc -ne 0 ]; then
      # If --run flag itself caused the failure, retry without it
      if echo "$testout" | grep -qi "unknown option\|unrecognized"; then
        testout="$($PM test 2>&1)"
        rc=$?
      fi
    fi
    if [ $rc -ne 0 ]; then
      problems+=("Tests failed (\`$PM test\`):"$'\n'"$(echo "$testout" | tail -40)")
    fi
  fi
fi

# --- report --------------------------------------------------------------------
if [ ${#problems[@]} -gt 0 ]; then
  {
    echo "Project checks failed — please fix these before finishing:"
    echo
    for p in "${problems[@]}"; do
      echo "• $p"
      echo
    done
  } >&2
  exit 2     # Stop hook: keeps Claude going until these pass
fi

exit 0
