#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
FABRIC_PATTERNS_DIR="${HOME}/.config/fabric/patterns"
BUNDLE_DIR="$PLUGIN_ROOT/references/top-patterns"

# Top 15 most universally useful patterns
TOP_PATTERNS=(
  summarize
  extract_wisdom
  review_code
  explain_code
  analyze_claims
  youtube_summary
  extract_article_wisdom
  extract_insights
  summarize_meeting
  improve_writing
  create_flash_cards
  find_logical_fallacies
  analyze_paper
  create_5_sentence_summary
  extract_recommendations
)

if [ ! -d "$FABRIC_PATTERNS_DIR" ]; then
  echo "Error: Fabric patterns directory not found at $FABRIC_PATTERNS_DIR"
  exit 1
fi

MAX_SIZE=8192  # 8KB limit

bundled=0
skipped=0

for pattern in "${TOP_PATTERNS[@]}"; do
  src="$FABRIC_PATTERNS_DIR/$pattern/system.md"
  dest="$BUNDLE_DIR/$pattern.md"

  if [ ! -f "$src" ]; then
    echo "Warning: $pattern not found, skipping"
    skipped=$((skipped + 1))
    continue
  fi

  size=$(wc -c < "$src")
  if [ "$size" -gt "$MAX_SIZE" ]; then
    echo "Warning: $pattern is ${size}B (>${MAX_SIZE}B), truncating"
    # Truncate by lines first, then by bytes if still too large
    head -200 "$src" | head -c "$MAX_SIZE" > "$dest"
    echo "" >> "$dest"
    echo "# NOTE: This pattern was truncated for bundling. Install Fabric for the full version." >> "$dest"
  else
    cp "$src" "$dest"
  fi

  bundled=$((bundled + 1))
done

echo "Bundled $bundled patterns ($skipped skipped) to $BUNDLE_DIR"
