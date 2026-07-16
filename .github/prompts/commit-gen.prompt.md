---
name: commit-gen
description: 'Propose a Conventional Commit message from the caller-provided staged diff without performing Git mutation.'
---

# Commit Message Command

## Entry

Use `/commit` with the intended scope and staged diff or an equivalent caller-provided change summary.

## Route

Follow [git-commit](../skills/git-commit/SKILL.md) for commit-message classification, wording, and validation.

## Authorization

This Prompt does not authorize staging, commit creation, push, or any other Git or remote mutation. It proposes message text only.

## Output

Return one proposed `type(scope): 繁體中文摘要` message with a concise Traditional Chinese body when needed. Keep technical identifiers in English and do not claim verification that was not provided.

## Handoff

Return the proposed text to the caller; the caller decides whether any separately authorized Git action occurs.
