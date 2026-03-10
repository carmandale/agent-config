---
name: data-migration-safety
description: Safe data migration between tools, databases, or formats. Use when migrating SQLite databases, JSONL files, issue trackers, or any bulk data transformation. Covers format validation, WAL cleanup, ID normalization, multi-prefix detection, and verification strategies. Triggers on "migrate data", "switch tools", "import from", "bulk migration", "database migration".
---

# Data Migration Safety

Prevent data loss during bulk migrations between tools or formats.

## When to Use

- Migrating data from tool A to tool B (e.g., bd → br, v1 → v2)
- Bulk-importing JSONL/CSV/JSON into a new database
- Transforming identifiers across systems
- Any operation touching >10 records in a database

## Pre-Migration Checklist

### 1. Format Compatibility Audit

**Before writing any migration script**, test a single record end-to-end:

```bash
# Extract one record from source
head -1 source.jsonl > /tmp/test-record.jsonl

# Try importing into target
target-tool import /tmp/test-record.jsonl
```

Check for:
- **Case sensitivity**: Does the target lowercase identifiers? (br lowercases all prefixes)
- **Character restrictions**: Does the target reject characters the source allowed? (br rejects dots in IDs)
- **Format validation**: Does the target validate structure the source didn't? (strict prefix-hash format)
- **Field mapping**: Are all source fields recognized by the target?

### 2. SQLite WAL/SHM Cleanup

When replacing a SQLite database file, **always remove WAL and SHM files**:

```bash
mv database.db database.db.backup
# CRITICAL: clean WAL/SHM — stale WAL from old schema corrupts new init
trash database.db-wal 2>/dev/null
trash database.db-shm 2>/dev/null
# Now safe to create new database
new-tool init --force
```

**Why**: SQLite WAL (Write-Ahead Log) files contain pending transactions for the OLD schema. If left behind, the new tool opens the fresh database, replays the old WAL, and produces "database disk image is malformed" errors.

### 3. Data Normalization

Before importing, normalize source data to match target constraints:

```bash
# Example: lowercase IDs + replace invalid chars
jq -c '
  def normalize_id: ascii_downcase | gsub("\\."; "d");
  .id |= normalize_id |
  if .depends_on then .depends_on = [.depends_on[] | .id |= normalize_id] else . end
' source.jsonl > normalized.jsonl
```

**Always verify normalization is collision-free**:
```bash
original_count=$(wc -l < source.jsonl)
unique_normalized=$(jq -r '.id' normalized.jsonl | sort -u | wc -l)
[[ "$original_count" -eq "$unique_normalized" ]] || echo "COLLISION DETECTED"
```

### 4. Multi-Prefix Detection

Data from tool A may use multiple identifier prefixes. Detect before import:

```bash
jq -r '.id' data.jsonl | sed 's/-[^-]*$//' | sort -u | wc -l
```

If >1 prefix:
- Choose the majority prefix for initialization
- Use the target tool's rename/unify feature during import
- Verify count matches (not ID-set, since IDs change during rename)

### 5. Verification Strategy

**Choose verification method based on whether IDs changed:**

| Scenario | Method | Command |
|----------|--------|---------|
| IDs preserved | ID-set diff | `diff <(db_ids) <(source_ids)` — must be empty |
| IDs transformed (rename/normalize) | Count match + spot-check | Count must match; spot-check 5+ records |
| IDs regenerated | Count match only | Counts must match exactly |

**For large datasets (>50 records)**: Use `sqlite3` directly, not tool CLIs that may paginate/cap results.

```bash
# Direct count — no pagination limits
sqlite3 database.db "SELECT COUNT(*) FROM issues;"
# vs tool CLI which may cap at 50
tool list --all --json | jq length  # UNRELIABLE for large sets
```

## Anti-Patterns

- ❌ `rm database.db` then `tool init` (leaves WAL/SHM to corrupt new DB)
- ❌ Grep output for "error" to detect failures (use exit codes)
- ❌ Assume tool B accepts everything tool A produced (format audit first)
- ❌ ID-set diff after rename operations (IDs changed — use count)
- ❌ Skip dry-run on "simple" migrations (always dry-run first)

## Evidence

- **Spec 013 (bd→br fleet migration)**: 9/23 repos failed initial migration due to uppercase IDs + dot notation that br rejected. SQLite WAL contamination caused "malformed disk image" on 1 repo. Multi-prefix detection needed for 2 repos. Count-based verification needed for rename cases.
