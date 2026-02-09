---
description: 'Generate a comprehensive specification document (PRD/Spec) for a feature. Transforms ideas into structured, testable requirements.'
---

# Spec Command

Use `/spec` after `/brainstorm` to transform clarified requirements into a formal specification document.

## When to Use
- After brainstorming session is complete
- When you have clear goals and chosen approach
- Before `/plan`

## Process

### Step 1: Clarifying Questions
If not already covered in brainstorm, ask about:
- The specific problem being solved
- Target users and their needs
- Core functionality requirements
- Success criteria and acceptance criteria
- Scope and boundaries (goals / non-goals)
- Technical constraints (security, performance, schema)

### Step 2: Generate Structured Spec

Create `changes/<...>/03-spec.md` with:

1. **Overview**: Brief description and context
2. **Goals**: Primary objectives and business value
3. **Non-Goals**: Explicitly excluded features
4. **User Stories**: Detailed scenarios with acceptance criteria
5. **Functional Requirements**: Specific features and capabilities
6. **Technical Considerations**:
   - Security requirements
   - Performance requirements
   - Schema/API contract requirements
7. **Success Metrics**: Measurable outcomes
8. **Open Questions**: Items requiring further clarification

## Quality Criteria
- Requirements are explicit and testable
- User stories include clear acceptance criteria
- Technical considerations address security and scalability
- All edge cases and error scenarios are covered
- Junior developer can understand and implement

## Financial Systems Additional Requirements
- Money fields: specify precision and storage format (integer minor units or decimal string)
- Idempotency requirements for transactions
- Audit trail requirements
- Timezone handling

## Next Step
After spec completion:
- Run `/plan` to break down into executable tasks
- Or use `/workflow` for guided progression

💡 Tip: Spec is complete when acceptance criteria are explicit and testable
