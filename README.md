# fabric-claude

A Claude Code plugin that brings [Fabric](https://github.com/danielmiessler/Fabric) prompt patterns into Claude Code sessions natively. Claude applies the patterns directly — no separate API key needed.

## Features

- **`/fabric` command** — Apply any of ~55 curated Fabric patterns to content
- **URL fetching** — Paste a YouTube or web URL to auto-fetch content
- **Obsidian output** — Every run saves a note with frontmatter for knowledge base / RAG
- **Follow-up suggestions** — Contextual pattern recommendations after each run
- **Degraded mode** — Works with 15 bundled patterns even without Fabric installed

## Install

```bash
git clone https://github.com/tylerc/fabric-claude.git ~/projects/fabric-claude
claude plugin add ~/projects/fabric-claude
```

### Optional dependencies (for full functionality)

```bash
# Pattern library (253 patterns)
go install github.com/danielmiessler/fabric/cmd/fabric@latest
fabric --setup

# YouTube transcript fetching
pipx install youtube-transcript-api

# Web content extraction
pipx install trafilatura
```

## Usage

```bash
/fabric --url https://youtube.com/watch?v=abc123          # Fetch + auto-select pattern
/fabric --url https://example.com/article --pattern summarize  # Fetch + specific pattern
/fabric --pattern extract_wisdom                           # Apply to conversation content
/fabric                                                    # Auto-select from context
/fabric --pattern review_code --no-save                    # Skip Obsidian output
```

## Obsidian Output

Notes save to `~/Documents/Projects/fabric-outputs/` with YAML frontmatter:

```yaml
source: "https://youtube.com/watch?v=abc123"
source_type: "youtube"
pattern: "extract_wisdom"
date: 2026-04-05
tags: [fabric, wisdom, youtube]
```

## Updating Patterns

After running `fabric --update` to pull new Fabric patterns:

```bash
bash ~/projects/fabric-claude/scripts/build-index.sh
```

## License

MIT
