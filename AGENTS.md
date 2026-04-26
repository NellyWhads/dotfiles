# AGENTS.md

## Purpose

This repository participates in a durable knowledge workflow. Agents should not leave important learnings trapped in chat when the learning is likely to matter later.

## Vault and default paths

- **Obsidian vault directory**: If the environment variable `OBSIDIAN_VAULT` is set to an absolute path, use it as the vault root. Otherwise, when working from this dotfiles repository, resolve the vault as the directory named `obsidian-vault` next to this repository (sibling of the `dotfiles` clone), e.g. `~/workspaces/public/obsidian-vault` when dotfiles lives at `~/workspaces/public/dotfiles`.
- **Default capture destination**: `{vault}/inbox/` unless the user specifies another path under the vault.
- **Other workspaces**: If the active project is not this dotfiles repo, do not assume the sibling heuristic; use `OBSIDIAN_VAULT` if set, or an explicit path the user gives.
- **Repo-only learnings**: If the note is specific to another repository that is the current workspace, keep the file in that project unless the user asks for the vault.
- **Verify vault before writing**: After resolving `{vault}`, confirm that path exists and is a directory (for example run `test -d` on it or list it). If it is missing, warn the user explicitly with the path you expected, remind them to clone the `obsidian-vault` repo beside this dotfiles clone or set `OBSIDIAN_VAULT`, and do not pretend notes were saved to the vault. You may still show the note in chat for copy-paste, or write only if the user supplies another valid directory.

## Memory behavior

When asked to save, remember, capture, log, document, distill, or summarize a learning:

- Create or update a Markdown note.
- Prefer file output over chat-only output.
- Use the templates and rules in `.cursor/rules/`.
- Default destination for vault notes: `{vault}/inbox/` as defined above.
- If the note is repo-specific, keep it in the repo.
- If the note is cross-project or evergreen, write it in the vault (or a path the user uses for Obsidian sync).

## Note-writing rules

- Output valid Markdown only.
- Use YAML frontmatter.
- Prefer concise bullets over long prose.
- Separate local details from reusable principles.
- Add wikilinks when there are obvious related concepts.
- Do not invent evidence. If uncertain, add an assumptions section.

## Note categories

- Capture note: raw durable learning from a task.
- Decision note: ADR-style record of an important choice.
- Concept note: reusable principle abstracted from a specific implementation.
- Source note: summary of an external article, doc, or research thread.

## Default filenames

- `YYYY-MM-DD-short-slug.md` for inbox notes.
- `ADR-YYYY-MM-DD-short-slug.md` for decisions.
- `concept-short-slug.md` for evergreen concepts.
- `source-short-slug.md` for research notes.

## Promotion heuristic

Promote a note from inbox to a permanent note if any of these are true:

- The lesson is likely to recur.
- The lesson changes a coding or architecture pattern.
- The lesson affects multiple repos or tools.
- The lesson would be hard to rediscover.

Suggested vault folders after promotion (see `obsidian/workflows/triage-workflow.md`): `concepts/`, `projects/`, `decisions/`, `sources/`.

## Style

Write for future retrieval, not for conversation replay.
