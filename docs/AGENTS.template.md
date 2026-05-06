# Project AI Workflow Guide

> Fill in the project sections below; the workflow reference is pre-configured.

## Project

| Field | Value |
|-------|-------|
| **Name** | <!-- Project name --> |
| **Domain** | <!-- HR / Financial / Legal / etc. --> |
| **Tech Stack** | <!-- Languages, frameworks, DB --> |
| **Test** | <!-- e.g., dotnet test / npm test --> |
| **Build** | <!-- e.g., dotnet build / npm run build --> |

## 6-Stage Workflow

| Stage | Trigger | Agent |
|-------|---------|-------|
| Brainstorm | `/brainstorming` | brainstorm-agent |
| Spec | `/specification` | spec-agent |
| Plan | `/implementation-planning` | plan-agent |
| Implement | `/tdd-workflow` | coder-agent |
| Review | `/code-security-review` | code-reviewer-agent |
| Archive | `/work-archiving` | — |

Use `/workflow` to auto-detect stage. Change packages → `changes/<slug>/`.
