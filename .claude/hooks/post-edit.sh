#!/usr/bin/env bash
#
# post-edit.sh — runs after Claude edits or writes a file (PostToolUse: Edit|Write).
#
# Fast, single-file checks only. On a problem it writes an actionable message to
# stderr and exits 2 — for PostToolUse that does NOT undo the edit (the tool
# already ran), it feeds the message back to Claude so it fixes the file on the
# next turn. A clean run exits 0 silently.
#
# Checks: Prettier formatting · ESLint · "rem over px" · repeated Tailwind class
# clusters. Heavy whole-program checks (tsc, duplicate function names) live in
# pre-stop.sh instead, because they only make sense across the whole project.

set -uo pipefail

# --- locate the project root and read the edited file path from stdin JSON ----
ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
INPUT="$(cat)"
FP="$(printf '%s' "$INPUT" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{process.stdout.write(((JSON.parse(d).tool_input)||{}).file_path||"")}catch(e){}})')"

# Nothing to check (e.g. a Write with no path, or non-file tool) → pass.
[ -z "$FP" ] && exit 0
[ -f "$FP" ] || exit 0

ext="${FP##*.}"
problems=()   # collected, human-readable findings

# Local tool binaries — prefer the project's installed versions; never auto-install.
PRETTIER="$ROOT/node_modules/.bin/prettier"
ESLINT="$ROOT/node_modules/.bin/eslint"

# --- 1. Prettier (formatting) --------------------------------------------------
case "$ext" in
  js|jsx|ts|tsx|mjs|cjs|css|scss|less|json|jsonc|md|mdx|html|vue|svelte|yaml|yml)
    if [ -x "$PRETTIER" ]; then
      if ! "$PRETTIER" --check "$FP" >/dev/null 2>&1; then
        problems+=("Prettier: \`$FP\` is not formatted. Reformat it (e.g. \`prettier --write\`) so it matches the project style.")
      fi
    fi
    ;;
esac

# --- 2. ESLint -----------------------------------------------------------------
case "$ext" in
  js|jsx|ts|tsx|mjs|cjs|vue|svelte)
    if [ -x "$ESLINT" ]; then
      out="$("$ESLINT" "$FP" 2>&1)"
      if [ $? -ne 0 ]; then
        problems+=("ESLint reported issues in \`$FP\`:"$'\n'"$out")
      fi
    fi
    ;;
esac

# --- 3. Padding/Margin (px) & Font Size (rem) ---------------------------------
# Spacing/sizing (padding, margin, gap, width, height, etc.) must use pixels (px).
# Font sizes must use rem. Flags violations in CSS rules and Tailwind classes.
case "$ext" in
  css|scss|less|tsx|jsx|html|vue|svelte)
    pxhits="$(node -e '
      const fs=require("fs");const f=process.argv[1];let s="";
      try{s=fs.readFileSync(f,"utf8")}catch(e){process.exit(0)}
      const lines=s.split(/\n/); const out=[];
      lines.forEach((ln,i)=>{
        // A. Spacing using rem (Violation)
        const cssRemRe = /\b(padding|margin|gap|width|height|top|bottom|left|right)(-[a-z]+)*\s*:\s*[^;]*\b([0-9.]+)\s*rem\b/gi;
        const twRemRe = /\b(p|m|gap|w|h|top|bottom|left|right|space-[xy]|translate-[xy])-\[[^\]]*\b([0-9.]+)\s*rem\b/gi;

        // B. Font-size using px (Violation)
        const cssPxRe = /\bfont-size\s*:\s*[^;]*\b([0-9.]+)\s*px\b/gi;
        const twPxRe = /\btext-\[[^\]]*\b([0-9.]+)\s*px\b/gi;

        let m;
        if ((m = cssRemRe.exec(ln)) || (m = twRemRe.exec(ln))) {
          out.push("  line "+(i+1)+": Spacing/sizing must be in px, not rem: "+ln.trim().slice(0,80));
        } else if ((m = cssPxRe.exec(ln)) || (m = twPxRe.exec(ln))) {
          const val = parseFloat(m[1] || m[2]);
          if (val > 1) {
            out.push("  line "+(i+1)+": Font size must be in rem, not px: "+ln.trim().slice(0,80));
          }
        }
      });
      out.slice(0,8).forEach(l=>console.log(l));
    ' "$FP" 2>/dev/null || true)"
    if [ -n "$pxhits" ]; then
      problems+=("Styling convention violation in \`$FP\` (spacing must use px, font-size must use rem):"$'\n'"$pxhits")
    fi
    ;;
esac

# --- 4. Repeated Tailwind class clusters --------------------------------------
# If the same long className string (6+ utilities) appears 2+ times in one file,
# it should be extracted — into a shared component, or a custom class defined in
# the Tailwind config / @layer — rather than duplicated.
case "$ext" in
  tsx|jsx|html|vue|svelte)
    dup="$(node -e '
      const fs=require("fs");const f=process.argv[1];let s="";
      try{s=fs.readFileSync(f,"utf8")}catch(e){process.exit(0)}
      const re=/className\s*=\s*"([^"]+)"/g, seen={}; let m;
      while((m=re.exec(s))){const v=m[1].trim();
        if(v.split(/\s+/).length>=6) seen[v]=(seen[v]||0)+1;}
      const dups=Object.entries(seen).filter(([,c])=>c>=2);
      for(const [v,c] of dups)
        console.log("  "+c+"x: \""+v.slice(0,70)+(v.length>70?"…":"")+"\"");
    ' "$FP" 2>/dev/null || true)"
    if [ -n "$dup" ]; then
      problems+=("Repeated Tailwind class strings in \`$FP\` — extract into a reusable component or a custom class in the Tailwind config instead of repeating them:"$'\n'"$dup")
    fi
    ;;
esac

# --- 5. Bundle-size import patterns -------------------------------------------
# Flags imports that hurt bundle size or violate frontend best practices
# (full lodash, moment, raw <img> in Next.js, lucide-react wildcard).
case "$ext" in
  js|jsx|ts|tsx|vue|svelte)
    bundlehits="$(node -e '
      const fs=require("fs");const f=process.argv[1];let s="";
      try{s=fs.readFileSync(f,"utf8")}catch(e){process.exit(0)}
      const lines=s.split(/\n/),out=[];
      lines.forEach((ln,i)=>{
        if(/import\s+.*\s+from\s+["\x27]lodash["\x27]/.test(ln)&&!/import\s+type/.test(ln))
          out.push("  line "+(i+1)+": Import from \"lodash-es\" or use cherry-picked imports instead of full \"lodash\".");
        if(/from\s+["\x27]moment["\x27]/.test(ln))
          out.push("  line "+(i+1)+": \"moment\" is deprecated and bloated. Use \"date-fns\", \"dayjs\", or native Date/Temporal.");
        if((f.includes("app/")||f.includes("pages/"))&&/<img\b/.test(ln)&&!/eslint-disable/.test(ln))
          out.push("  line "+(i+1)+": Use Next.js \"<Image />\" from \"next/image\" instead of raw \"<img>\".");
        if(/import\s+\*\s+as\s+\w+\s+from\s+["\x27]lucide-react["\x27]/.test(ln))
          out.push("  line "+(i+1)+": Wildcard import of \"lucide-react\" prevents treeshaking. Import specific icons.");
      });
      out.slice(0,5).forEach(l=>console.log(l));
    ' "$FP" 2>/dev/null || true)"
    if [ -n "$bundlehits" ]; then
      problems+=("Bundle/import issues in \`$FP\`:"$'\n'"$bundlehits")
    fi
    ;;
esac

# --- 6. Raw hex/rgb colors in component files ---------------------------------
# Token definition files (globals.css, tokens.css, tailwind.config) are excluded —
# only component/page code should use var(--color-*) references, not raw values.
case "$ext" in
  css|scss|less|tsx|jsx|html|vue|svelte)
    base="$(basename "$FP")"
    is_token_file=false
    case "$base" in
      globals.css|tokens.css|variables.css|theme.css|tailwind.config.*) is_token_file=true ;;
    esac
    if [ "$is_token_file" = "false" ]; then
      hexhits="$(node -e '
        const fs=require("fs");const f=process.argv[1];let s="";
        try{s=fs.readFileSync(f,"utf8")}catch(e){process.exit(0)}
        const lines=s.split(/\n/),out=[];
        lines.forEach((ln,i)=>{
          // Skip comments, CSS variable definitions, and SVG attributes
          const trimmed=ln.trim();
          if(trimmed.startsWith("//")||trimmed.startsWith("*")||trimmed.startsWith("/*")) return;
          if(/--[\w-]+\s*:/.test(ln)) return;
          // Flag raw hex colors (3,4,6,8 digit)
          const hexRe=/#[0-9a-fA-F]{3,8}\b/g;
          let m;
          while((m=hexRe.exec(ln))){
            // Exclude SVG fill/stroke literals and tailwind arbitrary color
            if(!/fill=|stroke=|stop-color/.test(ln)){
              out.push("  line "+(i+1)+": Raw hex color "+m[0]+" — use a CSS variable (var(--color-*)) instead.");
            }
          }
          // Flag raw rgb/rgba/hsl/hsla
          if(/\b(rgba?|hsla?|oklch)\s*\(/.test(ln)&&!/--[\w-]+\s*:/.test(ln)&&!/@theme/.test(ln)){
            out.push("  line "+(i+1)+": Raw color function — use a CSS variable (var(--color-*)) instead: "+trimmed.slice(0,70));
          }
        });
        out.slice(0,6).forEach(l=>console.log(l));
      ' "$FP" 2>/dev/null || true)"
      if [ -n "$hexhits" ]; then
        problems+=("Raw color values in \`$FP\` — use design tokens (CSS variables) instead of inline colors:"$'\n'"$hexhits")
      fi
    fi
    ;;
esac

# --- 7. Hardcoded z-index values ----------------------------------------------
# z-index should use the token scale (var(--z-*) or Tailwind z-* classes).
case "$ext" in
  css|scss|less|tsx|jsx|html|vue|svelte)
    zindexhits="$(node -e '
      const fs=require("fs");const f=process.argv[1];let s="";
      try{s=fs.readFileSync(f,"utf8")}catch(e){process.exit(0)}
      const lines=s.split(/\n/),out=[];
      lines.forEach((ln,i)=>{
        const trimmed=ln.trim();
        if(trimmed.startsWith("//")||trimmed.startsWith("*")||trimmed.startsWith("/*")) return;
        if(/--[\w-]+\s*:/.test(ln)) return; // token definition — fine
        // CSS property: z-index: <number>
        if(/z-index\s*:\s*\d+/.test(ln)&&!/var\(/.test(ln)){
          out.push("  line "+(i+1)+": Hardcoded z-index — use a token (var(--z-modal), etc.): "+trimmed.slice(0,70));
        }
        // Tailwind arbitrary z-index: z-[<number>]
        if(/\bz-\[\d+\]/.test(ln)){
          out.push("  line "+(i+1)+": Arbitrary z-index class — use a named z-index token (z-modal, z-overlay, etc.): "+trimmed.slice(0,70));
        }
      });
      out.slice(0,5).forEach(l=>console.log(l));
    ' "$FP" 2>/dev/null || true)"
    if [ -n "$zindexhits" ]; then
      problems+=("Hardcoded z-index values in \`$FP\` — use the z-index token scale instead of arbitrary numbers:"$'\n'"$zindexhits")
    fi
    ;;
esac

# --- 8. !important usage ------------------------------------------------------
# Almost always a specificity problem. Flag it so the author flattens selectors
# or uses @layer instead.
case "$ext" in
  css|scss|less|tsx|jsx|html|vue|svelte)
    imphits="$(node -e '
      const fs=require("fs");const f=process.argv[1];let s="";
      try{s=fs.readFileSync(f,"utf8")}catch(e){process.exit(0)}
      const lines=s.split(/\n/),out=[];
      lines.forEach((ln,i)=>{
        const trimmed=ln.trim();
        // Skip comments and prefers-reduced-motion override (the one valid use)
        if(trimmed.startsWith("//")||trimmed.startsWith("*")||trimmed.startsWith("/*")) return;
        if(/prefers-reduced-motion/.test(ln)) return;
        if(/!important/.test(ln)){
          out.push("  line "+(i+1)+": !important detected — fix specificity instead (flatten selectors, use @layer): "+trimmed.slice(0,70));
        }
      });
      out.slice(0,5).forEach(l=>console.log(l));
    ' "$FP" 2>/dev/null || true)"
    if [ -n "$imphits" ]; then
      problems+=("\\`!important\\` usage in \`$FP\` — this usually indicates a specificity problem. Fix the cascade instead:"$'\n'"$imphits")
    fi
    ;;
esac

# --- report --------------------------------------------------------------------
if [ ${#problems[@]} -gt 0 ]; then
  {
    echo "post-edit checks found issues that should be fixed before continuing:"
    echo
    for p in "${problems[@]}"; do
      echo "• $p"
      echo
    done
  } >&2
  exit 2     # PostToolUse: stderr is shown to Claude so it can fix the file
fi

exit 0
