---
name: create-readme
description: Create, rewrite, restructure, or audit a repository README.md as concise, evidence-backed documentation for users and developers. Use when a project needs a new README, a substantial README refresh, factual command and configuration documentation, or clearer separation from AGENTS.md, domain documentation, and migration guides.
---

# Create a repository README

Produce a concise entry point that explains the project's current purpose,
first successful workflow, public interface, and relevant development path.
Derive every claim from repository evidence.

## Discover the project

1. Read every applicable `AGENTS.md` before editing.
2. Inspect the existing README and nearby domain or migration documentation.
3. Inspect manifests, build files, task runners, CI, CLI usage, configuration
   schemas, tests, and executable scripts relevant to documented workflows.
4. Check Git status and preserve unrelated changes.
5. Classify the repository by its actual role, such as CLI, library,
   application, infrastructure, dotfiles, internal tool, or monorepo.
6. Identify the intended readers and the shortest path to a useful result.

Prefer executable source and current configuration over historical prose. When
documents conflict, resolve the claim from source or report the uncertainty;
do not guess.

## Set the documentation boundary

Keep each document responsible for one kind of information:

| Document | Responsibility |
| --- | --- |
| `README.md` | User/developer entry point and current public behavior |
| `AGENTS.md` | Coding-agent ownership, safety, editing, and validation rules |
| Domain documentation | Architecture and operational relationships |
| Migration guide | A version-bounded transition that is not yet complete |
| Source/config/scripts | Authoritative inventories and executable policy |

Allow only small, purposeful overlap: project identity, the most important
commands, a short ownership summary, and critical user-facing warnings. Link to
an existing companion document instead of copying its complete content.

Do not create additional documentation merely to satisfy this model unless the
user requested it or the repository clearly needs the split.

## Preserve current truth

- Preserve accurate, project-specific material from an existing README.
- Remove retired workflows, stale examples, duplicated inventories, and
  implementation history that no longer helps the reader.
- Document the system as it works now. Put unfinished transitions in a
  versioned migration guide rather than the main README.
- Use real command names, flags, paths, package/group keys, and configuration
  fields found in the repository.
- Point to an authoritative source for changing inventories instead of
  maintaining another hand-written list.
- Describe ownership and architecture at the level needed to use or develop the
  project; leave coding-agent guardrails to `AGENTS.md`.

## Choose sections from evidence

Use the project name as the top-level heading. Select only sections that serve
the identified readers. Common candidates include:

- a one-paragraph outcome and ownership summary;
- supported environments when support is intentionally bounded;
- installation or first-run instructions;
- task-oriented usage with a few verified examples;
- public configuration and its source of truth;
- a compact architecture or ownership explanation;
- development and validation commands; and
- troubleshooting for established, actionable failure modes.

Omit empty, speculative, or inapplicable sections. Do not force deployment,
database, API, coverage, pull-request, or troubleshooting content into every
project.

## Write in the Homebase style

- Lead with outcomes, then provide the shortest verified path to use them.
- Use plain, factual language and compact paragraphs.
- Prefer small code blocks and tables only when they clarify exact mappings.
- Use GitHub-flavored Markdown and admonitions only for material warnings.
- Avoid marketing copy, generic claims, excessive headings, badges, and emoji.
- Use a logo or screenshot only when it already exists, is meant for public
  use, and materially improves identification or understanding.
- Do not add `License`, `Contributing`, or `Changelog` sections when dedicated
  files own that content.
- Avoid bare URLs when a descriptive Markdown link is clearer.
- Keep examples reproducible and free of secrets, credentials, and
  machine-specific private data.

## Validate without causing side effects

1. Verify documented commands and values against source.
2. Run only safe, relevant checks allowed by the applicable `AGENTS.md`.
3. Do not run deployment, bootstrap, package installation, setup, cleanup,
   sync, or other live mutations merely to validate prose.
4. Run the repository's Markdown lint command when available.
5. Check relative links, fenced blocks, tables, and placeholders.
6. Run `git diff --check`.
7. Re-read the finished README for duplicated companion content, stale
   inventory, invented behavior, and unnecessary sections.

Finish with a concise summary of what changed, what was validated, and any
claim that could not be verified.
