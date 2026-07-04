# Synthesis — records → durable knowledge

This is the highest-leverage workflow. The vault captures thousands of meetings but
almost never distills them. Your job: find the durable signal and give it a home in
`Decisions/`, `Concepts/`, or `Topics/`.

## When to run

- After a meeting or digest that clearly produced a **decision** or a **reusable idea**.
- On request: "log this decision", "capture this idea", "what did we decide about X".
- As a periodic backfill pass over recent `Meetings/` (see the loop at the bottom).

## Decisions (the main output)

**Detect a decision** when a meeting/thread shows: a choice made, a direction set, a
person/vendor/tool/price selected, a commitment to an approach, or an explicit
"we've decided…". Action items are *not* decisions — a decision is the *choice*, the
action item is the *follow-through*.

Create `Decisions/YYYY-MM-DD - <Short Title>.md` from `_Templates/Decision.md`:

- `status:` = `decided` (or `proposed` if still open). Tag `#decided` / `#proposed`.
- **Context** — what forced the decision. Link the source meeting.
- **Options considered** — only if they were actually weighed; don't invent options.
- **Decision** — what was chosen and why, in Ben's voice.
- **Consequences** — what it commits P41 to, what's given up.
- **Revisit when** — the trigger that would reopen it.
- **Related** — `[[Initiative]]`, `[[Meeting]]`, `[[People]]`.

Then link back: add the decision to the source meeting's note and the relevant
`Initiatives/` note's "## Decisions" section.

**Do not fabricate.** If a meeting *implies* a decision but nobody clearly made it,
list it as a candidate for Ben to confirm rather than writing a `#decided` note.

## Concepts (durable thinking)

Create a `Concepts/` note when Ben articulates — or repeatedly leans on — a framework,
mental model, or reusable principle (e.g. "Agentic Software Factory", a pricing model,
a hiring philosophy). Use `_Templates/Concept.md`: definition in Ben's words, when it
changes how he'd act, where it came from, and links to the initiatives/decisions it
informed. One concept per note; keep it long-lived and edit it as thinking evolves.

## Topics (cross-cutting focus areas)

Create/maintain a `Topics/` note for an ongoing area that cuts across many meetings and
people (hiring, fundraising, a specific GTM motion, "Collection Gaps"). Use
`_Templates/Topic.md`. The key section is **"Current state of my thinking"** — keep it
current; it's the running synthesis. Link active threads to initiatives and questions.

## Backfill loop (periodic synthesis pass)

To catch up or stay current, sweep recent meetings for un-synthesized decisions:

1. `recent_activity` or list `Meetings/` for the period (e.g. last 7 days).
2. For each meeting, scan the Summary + Action items for decision signals.
3. Collect **candidate** decisions/concepts. Deduplicate against existing `Decisions/`.
4. Present the candidate list to Ben for a yes/no per item (don't auto-write —
   decisions carry weight).
5. Write the confirmed ones from the template, fully linked.

For a large backfill, this is a good fit for a Workflow fan-out (one agent per meeting
proposing candidates, then a synthesis step) — but only when Ben has asked for scale.

## Automating it

The durable win is to teach the daily routine to emit a **"Candidate decisions"**
section in the Daily Digest (extracted from that day's meetings) so Ben triages them
into `Decisions/` daily. See `references/review.md` and `data/_digest_gen.py`.
