# Inbox Triage Workflow

Use this workflow to turn raw captured notes into durable knowledge.

## Daily or session-end triage

1. Review new notes in `inbox/` (at the vault root).
2. Delete notes that are not durable.
3. Merge duplicates.
4. Promote important notes to one of:
   - `concepts/`
   - `projects/`
   - `decisions/`
   - `sources/`
5. Add or refine wikilinks.
6. Normalize tags.
7. Add one sentence explaining why the note matters.

## Promotion criteria

Promote a note when:

- it is likely to recur
- it teaches a reusable principle
- it explains a decision with long shelf life
- it connects multiple tools, repos, or ideas
- it would be annoying to rediscover

## Agent prompt for triage

```md
Review the notes in my inbox and help me triage them.

For each note:
- decide whether to delete, merge, keep in inbox, or promote
- propose the target folder
- improve tags and wikilinks
- preserve only durable knowledge

Output a concise action plan and updated Markdown where needed.
```
