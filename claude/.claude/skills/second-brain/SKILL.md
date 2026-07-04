---
name: second-brain
description: Ben's Particle41 CEO second brain — the basic-memory vault at /Users/benjohnson/basic-memory. Use whenever capturing, retrieving, or maintaining Ben's knowledge: "remember this", "add to my notes", "what do I know about <person/client/deal>", "log a decision", "weekly review", "clean up my people notes", triaging the daily digest, or any work inside the vault (Meetings, People, Clients, Decisions, Concepts, Topics, Daily, Inbox). Turns captured records into durable knowledge and keeps entities high-signal.
---

# Second Brain

Ben's second brain is the basic-memory vault at `/Users/benjohnson/basic-memory`. It
is the single source of truth for everything he runs as CEO of Particle41. The vault's
`CLAUDE.md` is the always-loaded operating manual; **this skill is the detailed
playbook** for the five workflows below.

## The core insight

Capture is already automated and excellent (a scheduled routine lands Meetings, People
stubs, a Daily Digest, and a Daily note every day). The value you add is in the two
weak layers:

- **Synthesis** — turning records into durable knowledge (Decisions, Concepts, Topics).
- **Curation** — keeping entities high-signal (enrich People, dedup, prune, link).

Guiding question for any note: *"A year from now, does this make Ben smarter, or just
remind him something happened?"* Aim for the former.

## Access

- Working directory is the vault root → read/edit/write files directly.
- `basic-memory` MCP for retrieval and clean writes: `search_notes`, `read_note`,
  `build_context` (follows `[[links]]`), `recent_activity`, `write_note`, `edit_note`.
- Always match conventions in `_Templates/` and a recent note of the same type:
  quoted dates, `permalink: main/<folder>/<slug>`, dense `[[wiki-links]]`, correct tags.

## The five workflows

Pick the one that matches the request. Each has a detailed reference file — read it
before doing that kind of work.

1. **Capture & triage** — turning raw input (a request, a thought, an Inbox digest)
   into the right note(s) in the right place. → `references/capture.md`
2. **Synthesis** — extracting Decisions / Concepts / Topics from meetings, digests,
   and Ben's thinking. The highest-leverage workflow. → `references/synthesis.md`
3. **People enrichment** — turning auto-stubs into real profiles; dedup; prune.
   → `references/people.md`
4. **Review rituals** — weekly review, commitment reconciliation, daily reflection.
   → `references/review.md`
5. **Retrieval** — answering "what do I know about X" from the vault, with citations.
   → `references/retrieval.md`

## Non-negotiables

- **Never fabricate.** Synthesis means extracting what's in the record. If unsure
  whether something is a real decision/fact, surface it to Ben — don't write it.
- **Never delete or overwrite** a substantive note without showing Ben first.
  Enriching an auto-stub in place is fine.
- **Never orphan a note** — every new note links to ≥1 person, client, initiative,
  or meeting.
- **Always dedup before creating** — search for the entity first, including name
  variants ("Robert S" vs "Robert Sunleaf").
- **Retrieve before you answer** — search the vault before answering questions about
  people, clients, deals, or commitments. Cite the notes. If the vault is silent, say so.
