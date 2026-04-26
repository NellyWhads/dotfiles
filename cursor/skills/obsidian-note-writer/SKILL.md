---
name: obsidian-note-writer
description: >-
  Create Obsidian-compatible Markdown notes from research, coding sessions, project decisions, and durable learnings.
  Use when asked to save a learning, create a knowledge note, distill a concept, or produce a Markdown note for a vault.
  Default vault per dotfiles AGENTS.md — sibling directory obsidian-vault next to the dotfiles clone, or OBSIDIAN_VAULT if set.
---

# Obsidian Note Writer

## Purpose

Create concise, durable Markdown notes that work well in Obsidian and can be linked into a knowledge graph.

## Vault path

Match `AGENTS.md` in the dotfiles repository: use `OBSIDIAN_VAULT` when set; otherwise the sibling folder `obsidian-vault` next to the `dotfiles` checkout. Write new captures under `{vault}/inbox/` unless the user specifies otherwise.

## Instructions

1. Output valid Markdown only.
2. Use YAML frontmatter with: `id`, `title`, `date`, `source_tool`, `source_project`, `tags`, `status`, and optional `aliases`.
3. Prefer durable knowledge over conversational recap.
4. Use bullets where possible.
5. Add likely wikilinks when related concepts are obvious.
6. Separate local details from reusable principles.
7. Keep code snippets minimal and relevant.

## Note modes

### Capture note

Use sections:

- Summary
- What happened
- Key learning
- Reusable pattern
- Evidence or code
- Related notes
- Next actions

### Decision note

Use sections:

- Context
- Decision
- Alternatives considered
- Consequences
- Revisit when
- Related notes

### Concept note

Use sections:

- Principle
- When this matters
- Common failure modes
- Heuristics
- Minimal example
- Related notes

## Quality bar

The output should be understandable to future-you in under one minute and should be useful even after the original chat is gone.

## Installing this skill globally (Cursor)

Copy or symlink this folder to `~/.cursor/skills/obsidian-note-writer/` so the skill is available outside the dotfiles workspace.
