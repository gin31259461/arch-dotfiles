---
name: create-agentsmd
description: Create, rewrite, restructure, or audit scoped AGENTS.md coding instructions from repository evidence. Use when a root or nested project needs accurate ownership boundaries, side-effect guardrails, development and testing workflows, security rules, or clearer separation between agent instructions and README, domain, or migration documentation.
---

# Create AGENTS instructions

Produce a compact operational contract that helps coding agents change the
repository safely and correctly without repeating its user documentation.
Include only instructions that affect agent decisions.

## Determine scope first

1. Read all `AGENTS.md` files that apply from the filesystem or repository root
   to the target directory. The nearest file has the most specific scope.
2. Inspect the README, domain documentation, manifests, build files, task
   runners, CI, tests, configuration, and scripts relevant to that scope.
3. Check Git status and identify generated, sensitive, vendored, submodule, or
   externally owned paths.
4. Determine the repository's architecture, ownership seams, side effects, and
   supported workflows from evidence.
5. Preserve accurate project-specific rules from an existing `AGENTS.md`.

Create a root `AGENTS.md` by default. Add or rewrite a nested file only when a
subtree has materially different commands, ownership, safety constraints, or
language conventions. Do not create nested files merely because the repository
is a monorepo.

## Keep companion documents distinct

Use this division of responsibility:

| Document | Responsibility |
| --- | --- |
| `README.md` | User/developer entry point and current public behavior |
| `AGENTS.md` | Coding-agent ownership, safety, editing, and validation rules |
| Domain documentation | Architecture and operational relationships |
| Migration guide | A version-bounded transition that is not yet complete |
| Source/config/scripts | Authoritative inventories and executable policy |

Keep critical agent rules self-contained even when another document explains
the background. Link to the companion document for detail instead of copying a
long tutorial, architecture narrative, migration sequence, or inventory.

## Build an adaptive instruction set

Use `# AGENTS Instructions` as the root title unless an established repository
convention explicitly requires another title. Select only sections justified by
the repository. Common candidates are:

- project overview;
- ownership seam;
- high-signal repository layout;
- core commands;
- side-effect rules;
- configuration or domain rules;
- platform or package ownership;
- development workflow;
- testing instructions;
- code style and security; and
- documentation update rules.

Do not add placeholder or boilerplate sections. Omit setup, deployment,
database, coverage, pull-request, debugging, or release instructions when the
repository does not define them.

## Make ownership actionable

State the boundaries an agent cannot safely infer:

- which module or repository owns each important behavior or policy;
- which file is the source of truth for changing inventories;
- when shared code is appropriate and when behavior must remain owner-specific;
- which generated or externally owned files must not be edited;
- how monorepo packages, submodules, or bare worktrees must be handled; and
- which documentation must change with a public contract.

Prefer rules such as "service inventory belongs in this script" over a copied
list of services that can drift.

## Define safety and authorization boundaries

- Separate read-only validation from commands that mutate machines, services,
  package databases, remotes, cloud resources, or user data.
- Require explicit user authorization for live or destructive actions when the
  repository has such operations.
- Name sensitive paths or data classes only as precisely as needed to prevent
  exposure; instruct agents not to print or track secrets.
- Require fake runners, temporary directories, fixtures, or dry-run mechanisms
  for risky behavior when the repository provides them.
- Preserve unrelated dirty worktree changes and forbid destructive recovery
  commands unless explicitly authorized.
- Record repository-specific tool and editing constraints that materially
  affect safe work.

Do not copy generic safety prose that adds no repository-specific decision.

## Document real workflows

- Use exact commands from manifests, Makefiles, task runners, CI, or scripts.
- Explain when focused checks are sufficient and when the complete validation
  suite is required.
- Mark commands that depend on deployed configuration or external services.
- Do not test instructions by running live deployment, bootstrap, setup,
  cleanup, package installation, or destructive commands.
- Keep current commands in `AGENTS.md`; put unfinished migrations in a
  versioned migration guide.

For tests, protect stable contracts, schema invariants, destructive safety, and
non-trivial orchestration. Do not prescribe coverage-only tests for trivial
wrappers, getters, or private implementation shape unless the repository has a
documented requirement. When ownership moves, replace obsolete tests rather
than retaining parallel coverage at both owners.

## Write concise instructions

- Use imperative, specific language.
- Explain why only when it changes how an agent should act.
- Prefer compact bullets and exact code blocks over broad tutorials.
- Include high-signal paths, not a complete directory listing.
- Avoid personality prompts, ecosystem marketing, generic AI advice, and
  claims that are not verified from the repository.
- Avoid duplicating package, service, route, or configuration inventories whose
  authoritative source is executable.
- Preserve stable rules; remove completed plans and retired architecture.

## Validate the result

1. Verify every command, path, ownership statement, and tool name against the
   repository.
2. Confirm the instructions do not conflict with an applicable parent or
   nested `AGENTS.md`.
3. Run the repository's Markdown lint command when available.
4. Check links, placeholders, fenced blocks, tables, and `git diff --check`.
5. Confirm no unrelated or sensitive file was staged.
6. Re-read the README and AGENTS files together: keep only purposeful overlap
   and ensure each remains usable for its intended audience.

Finish with a concise summary of the scope, important guardrails, validation
performed, and any unresolved repository fact.
