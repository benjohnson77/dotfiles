# Capture & triage

Most capture is automated (the daily routine → Meetings, People stubs, Digest, Daily
note). This workflow covers the *manual* captures — a thing Ben wants remembered — and
triaging the Inbox.

## Manual capture ("remember this", "add to my notes")

1. **Classify** — which note type fits?
   - A choice was made → `Decisions/` (see synthesis.md).
   - A framework / durable idea → `Concepts/`.
   - A person → `People/` (enrich, don't just stub — see people.md).
   - A customer/prospect fact → the `Clients/` note.
   - A strategic bet → `Initiatives/`.
   - A cross-cutting focus area → `Topics/`.
   - A quick thought with no home yet → `Inbox/` as a dated capture, to triage later.
2. **Dedup** — search for an existing note first; enrich it rather than create a new one.
3. **Write** from the matching `_Templates/` file; copy frontmatter shape (quoted
   dates, `permalink: main/<folder>/<slug>`) from a recent note of that type.
4. **Link** — connect to ≥1 existing person/client/initiative/meeting, and add a
   back-link from the most relevant existing note. No orphans.
5. **Confirm** what you captured and where (`[[link]]`).

## Triaging the Inbox

`Inbox/` holds the auto Daily Digests and any quick captures. Triage = move signal
into its durable home:

- **Commitments** in the digest → these are tracked in the digest itself; when one
  implies a decision or a new initiative, spin out the durable note.
- **New people** mentioned → enrich if they matter (people.md).
- **Decisions** surfaced → `Decisions/` (synthesis.md).
- **Quick captures** → route to the right folder per the classify step above.
- Leave the digest note itself intact (it's a generated dated record); triage *out of*
  it, don't rewrite it.

## Quality bar for any captured note

- Correct type + frontmatter + permalink.
- At least one inbound and one outbound `[[link]]`.
- Written in Ben's voice, factual, no fabrication.
- Answers "will this make Ben smarter later?" — if it's pure transaction log with no
  durable value, a stub or a digest line is enough; don't over-invest.
