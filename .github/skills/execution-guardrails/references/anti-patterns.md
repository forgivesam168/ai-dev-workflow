# Guardrail Anti-Patterns

Short examples of the failure modes this skill is meant to catch.

## 1. Hidden Assumptions

**Bad**
- User asks: "Add export"
- Agent decides: "Export all records as CSV into a background job"

**Why it fails**
- export target, scope, format, and privacy constraints were never confirmed

**Better**
- separate what is known from what is assumed
- ask for the missing boundary or state the assumption explicitly before proceeding

## 2. Overengineering

**Bad**
- User asks for a discount function
- Agent creates strategy interfaces, config objects, and multiple discount classes

**Why it fails**
- the design solves hypothetical future requirements instead of the current one

**Better**
- implement the smallest function that solves today's requirement
- refactor later if multiple discount behaviors really appear

## 3. Unrelated Edits

**Bad**
- User asks to fix one validation bug
- Agent also reformats the file, renames variables, rewrites comments, and adds extra validation

**Why it fails**
- the diff is no longer traceable to the request

**Better**
- change only the lines required to fix the reported behavior
- mention unrelated cleanup opportunities without bundling them into the same change

## 4. Weak Success Criteria

**Bad**
- Goal: "Make auth better"
- Implementation starts immediately with broad code changes

**Why it fails**
- "better" is not verifiable; there is no crisp definition of done

**Better**
- rewrite the task as a checkable target:
  - reproduce bug with a failing test
  - implement the smallest fix
  - prove no regression with existing tests
