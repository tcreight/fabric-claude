#!/usr/bin/env bash
set -euo pipefail

# Build the pattern index by merging Fabric pattern files with curation metadata.
# Reads: scripts/pattern-curation.json
# Writes: data/pattern-index.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CURATION_FILE="${SCRIPT_DIR}/pattern-curation.json"
OUTPUT_FILE="${PROJECT_ROOT}/data/pattern-index.json"
FABRIC_PATTERNS_DIR="${HOME}/.config/fabric/patterns"

# --- Validation ---

if [[ ! -d "${FABRIC_PATTERNS_DIR}" ]]; then
  echo "ERROR: Fabric patterns directory not found: ${FABRIC_PATTERNS_DIR}" >&2
  echo "       Install Fabric first: https://github.com/danielmiessler/fabric" >&2
  exit 1
fi

if [[ ! -f "${CURATION_FILE}" ]]; then
  echo "ERROR: Curation config not found: ${CURATION_FILE}" >&2
  exit 1
fi

mkdir -p "${PROJECT_ROOT}/data"

# --- Build the index using Python ---
# Python handles the JSON parsing and description extraction cleanly.

python3 - "${CURATION_FILE}" "${FABRIC_PATTERNS_DIR}" "${OUTPUT_FILE}" <<'PYEOF'
import json
import os
import re
import sys
from datetime import date

curation_file = sys.argv[1]
patterns_dir  = sys.argv[2]
output_file   = sys.argv[3]

with open(curation_file) as f:
    curation = json.load(f)

def extract_description(system_md_path: str) -> str:
    """Pull the first substantive sentence from the IDENTITY/PURPOSE section."""
    try:
        with open(system_md_path) as f:
            content = f.read()
    except OSError:
        return ""

    # Find the IDENTITY and PURPOSE section (or just IDENTITY)
    match = re.search(
        r'#\s*IDENTITY(?:\s+and\s+PURPOSE)?.*?\n+(.*?)(?:\n#|\Z)',
        content,
        re.IGNORECASE | re.DOTALL,
    )
    if not match:
        return ""

    section_text = match.group(1).strip()

    # Walk lines and grab the first non-empty, non-list paragraph line
    for line in section_text.splitlines():
        line = line.strip()
        if not line:
            continue
        # Skip markdown list items and Take a step back / step by step boilerplate
        if line.startswith(('-', '*', '#')):
            continue
        if re.match(r'^take a step back', line, re.IGNORECASE):
            continue
        # Truncate at sentence boundary around 200 chars
        if len(line) > 200:
            sentence_end = re.search(r'[.!?]', line[:200])
            if sentence_end:
                line = line[:sentence_end.end()].strip()
            else:
                line = line[:200].rstrip() + '...'
        return line

    return ""

patterns = []
warned = 0

for name, meta in curation.items():
    system_md = os.path.join(patterns_dir, name, "system.md")

    if not os.path.isfile(system_md):
        print(f"WARNING: pattern not found on disk, skipping: {name}", file=sys.stderr)
        warned += 1
        continue

    size_bytes = os.path.getsize(system_md)
    description = extract_description(system_md)

    patterns.append({
        "name":             name,
        "category":         meta["category"],
        "description":      description,
        "related_patterns": meta["related_patterns"],
        "content_types":    meta["content_types"],
        "size_bytes":       size_bytes,
    })

# Sort alphabetically within each category for consistent output
patterns.sort(key=lambda p: (p["category"], p["name"]))

index = {
    "version":       "1.0",
    "generated":     date.today().isoformat(),
    "pattern_count": len(patterns),
    "patterns":      patterns,
}

with open(output_file, "w") as f:
    json.dump(index, f, indent=2)
    f.write("\n")

print(f"Indexed {len(patterns)} patterns ({warned} warnings) -> {output_file}")
PYEOF
