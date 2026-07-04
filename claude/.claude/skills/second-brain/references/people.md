# People enrichment, dedup & pruning

There are ~430 `People/` notes, most auto-generated stubs ("First captured via the
daily digest… Read.ai meeting participant"). They drag down signal-to-noise. This
workflow turns the ones that matter into real profiles and clears the ones that don't.

## Tiering (decide effort per person)

- **Enrich** — anyone Ben deals with directly: clients, prospects, partners,
  investors, key team leads, recurring meeting counterparts.
- **Leave as stub** — one-off meeting participants, someone else's teammate who Ben
  rarely interacts with. A thin note is fine; don't spend cycles.
- **Prune / merge** — duplicates and noise (see below).

Don't try to enrich all 430. Prioritize by interaction frequency and strategic value.

## Enriching one person

1. Find every mention: `search_notes` the name (and variants) and `build_context` on
   their note to pull linked meetings.
2. Fill `_Templates/Person.md` from the record — **only facts that appear in the vault
   or that Ben confirms**:
   - `relationship`, `company`, `title`, `email` in frontmatter (correct, not "external").
   - **Context** — how Ben knows them, why they matter (1–2 real sentences).
   - **Recent interactions** — a dated list built from their linked meetings, newest first.
   - **Threads / open loops** — pull any open action items involving them from digests.
   - **Notes** — durable personal context (preferences, history) — only if known.
3. Ensure the note links to the relevant `[[Client]]` / `[[Initiative]]` and that
   those link back.

## Dedup & merge

Stubs fragment across name variants: "Robert S" / "Robert Sunleaf", "Benjamin Johnson" /
"Ben Johnson", first-name-only vs full name.

1. Detect: list `People/`, group by fuzzy/normalized name and by email.
2. For each cluster, pick the canonical note (most complete, full name).
3. Merge content into the canonical note; use `move_note` / update `[[links]]` so
   references point to the canonical name; then remove the duplicate.
4. **Show Ben the merge plan before executing** deletes/moves — never silently delete.

Note: the daily generator (`data/_digest_gen.py`) creates stubs from Read.ai attendee
names. To stop *future* fragmentation, normalize attendee → canonical name in the
generator (e.g. a name/email alias map), not just clean up after the fact.

## Pruning

A stub that is (a) a one-off participant, (b) has no open loops, and (c) isn't linked
from any client/initiative can be left as-is (harmless) or archived if Ben wants a
leaner graph. Default to leaving stubs; only prune on request. Never prune anyone with
open commitments or client/initiative links.

## Scale

Enriching/deduping hundreds of notes is a good Workflow fan-out (one agent per person
or per dedup cluster, worktree isolation not needed for reads; batch the writes) — but
run at that scale only when Ben explicitly asks. Otherwise do the top-priority handful.
