---
name: apple-notes
description: Search and query the user's Apple Notes collection by meaning. Use when the user asks to find notes, recall something from their notes, search Apple Notes, or asks a question that their notes might answer. Triggers on "search my notes", "what did I write about", "find in my notes", "check my notes for", "do I have a note about", "notes about".
---

# Apple Notes — Semantic Search & RAG

Search 7,500+ Apple Notes by meaning and ask questions answered from note content. Entirely local — nothing leaves the machine.

`notes` is on PATH (wrapper at `/usr/local/bin/notes`). No venv activation needed.

Ollama must be running (`nomic-embed-text` for embeddings, `qwen3.5` for RAG).

## Prefer `search` over `ask`

**Start with `search`.** It's fast (0.1s), gives you titles + scores + snippets, and is enough for most questions. Only escalate to `ask` when the user needs a synthesized answer across multiple notes.

Many notes are short bookmarks (a title + a link). `search` shows you exactly what's there. `ask` adds 10–30 seconds of LLM time and may just report "I only see titles" for thin notes.

## Commands

### Search notes by meaning

```bash
notes search "query" [--limit N] [--folder FOLDER] [--json]
```

Returns the top N notes ranked by similarity (0–1, higher = better). Default: 10.

- `--folder "Embodied Labs"` — filter to a specific folder
- `--json` returns: `[{id, title, folder, body, score, modified}, ...]`

**Examples:**
```bash
notes search "restaurant recommendations"
notes search "visionOS development" --limit 20
notes search "budget expenses" --json | jq '.[].title'
notes search "cast members" --folder "Embodied Labs"
```

### Ask a question answered from notes

```bash
notes ask "question" [--context N] [--folder FOLDER] [--model MODEL] [--json]
```

Retrieves relevant notes, feeds them to qwen3.5 locally, streams an answer with citations. Default: 10 context notes.

- `--json` returns: `{answer, sources: [{id, title, score}]}`
- `--context 20` gives the LLM more notes to work with

**Examples:**
```bash
notes ask "What machine learning resources have I saved?" --context 20
notes ask "Summarize my notes about home automation"
```

### Open a note in Apple Notes

```bash
notes open <id>
```

Takes a note ID (from search results) and opens it directly in Apple Notes.app. Useful for viewing attachments, images, and link previews that aren't in the text.

**Example workflow:**
```bash
notes search "framework for creating skills" --json | jq '.[0].id'
# → 14145
notes open 14145
```

### Sync the index

```bash
notes sync [--force]
```

Incremental — only re-embeds changed notes. ~0.3s if nothing changed, ~40s for full rebuild.

**Run sync before searching** if the user says they recently added or edited notes.

### Check index status

```bash
notes status
```

## Interpreting results

- **Scores 0.85+**: Strong semantic match.
- **Scores 0.70–0.85**: Relevant, worth showing.
- **Below 0.70**: Weak — probably not what the user wants.
- **55% of notes contain URLs** (mostly X/Twitter posts, GitHub repos, YouTube). The URL is in the body text and searchable.
- **Many notes are title + link bookmarks**: The user saves links from X, GitHub, etc. with short descriptive titles. Search works on both the title and URL text.
- **If a note body is very short** (just a title), the note likely has an image/screenshot/link-preview attachment. Suggest `notes open <id>` to view it in Apple Notes.
- **Folders**: Notes (7,574), Embodied Labs (6), IRS (1), GPJ (1). Almost everything is in "Notes".

## When to use which

| User intent | Command | Why |
|-------------|---------|-----|
| "Find notes about X" | `search` | Fast, shows what exists |
| "Do I have anything about X?" | `search --limit 5` | Quick existence check |
| "What did I write about X?" | `search` first, `ask` if notes have real content | Avoid slow RAG for title-only notes |
| "Summarize my notes on X" | `ask --context 20` | Needs synthesis across notes |
| "Open that note" | `open <id>` | View in Apple Notes with attachments |
| Pipe to another tool | `search --json` or `ask --json` | Structured output |

## Important

- **All local**: Ollama on localhost. No notes leave the machine.
- **Search is meaning-based**, not keyword. "dining spots" finds restaurant notes.
- **Short notes** (< 5 words) may cluster together in search — the embedding model needs context to differentiate very short texts.
- **First `ask` after idle may take 30–60s** — Ollama cold-loads qwen3.5 into GPU memory.
- **Source code**: `/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/apple-notes-export/`
