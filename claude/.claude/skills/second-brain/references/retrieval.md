# Retrieval — answer from the brain, with citations

The vault is only worth feeding if it's used. Before answering any question about a
person, client, deal, commitment, decision, or past meeting, **query the vault first**
and answer from what's there — not from assumption or the model's guess.

## How to retrieve well

1. **Start broad, semantic**: `search_notes` with the natural-language question or the
   entity name. It's semantic, so phrase it like the answer you want.
2. **Follow the graph**: `build_context` on the most relevant note to pull everything
   linked to it (a client note → its people, meetings, decisions). This is the payoff
   of dense `[[wiki-links]]`.
3. **Time-scope when relevant**: `recent_activity` for "lately / this week / what's new".
4. **Check variants**: search name variants and both folders (a person may be in
   `People/` and referenced across `Meetings/`, `Clients/`, digests).

## How to answer

- **Cite the notes** you used as `[[links]]` so Ben can click through and trust it.
- **Distinguish record from inference**: state what the vault says vs. what you're
  inferring from it.
- **If the vault is silent, say so** — "nothing in the vault on X" — and offer to
  capture it. Never fill the gap with a plausible guess presented as fact.
- **Synthesize, don't dump**: for "what do I know about <client>", give the current
  state (stage, key people, open threads, last touch, next milestone), not a raw
  transcript of every meeting.

## Common retrieval shapes

- *"Brief me on my 2pm with <client>"* → client note + that person's note + last 2–3
  meetings + open commitments involving them → a 5-line brief.
- *"What did we decide about <topic>"* → search `Decisions/` + related meetings.
- *"What's open with <person>"* → their note's threads + open commitments in digests.
- *"What's the status of <initiative>"* → the initiative note + recent linked meetings.

For a broad, multi-angle question across the whole vault, a Workflow fan-out (parallel
searches by different angles, then synthesis) is appropriate — but only at Ben's
request for scale; a direct `search_notes` + `build_context` handles most asks.
