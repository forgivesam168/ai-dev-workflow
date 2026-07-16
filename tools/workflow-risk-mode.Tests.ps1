BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent

    function Read-RepoFile {
        param([Parameter(Mandatory)][string]$RelativePath)

        return Get-Content -LiteralPath (Join-Path $script:RepoRoot $RelativePath) -Raw
    }

    $script:AdopterAgents = Read-RepoFile 'docs/AGENTS.template.md'
    $script:Workflow = Read-RepoFile 'WORKFLOW.md'
    $script:MaintainerAgents = Read-RepoFile 'AGENTS.md'
    $script:ProjectAgentDocuments = @(
        [pscustomobject]@{ Path = 'docs/AGENTS.template.md'; Content = $script:AdopterAgents }
        [pscustomobject]@{ Path = 'AGENTS.md'; Content = $script:MaintainerAgents }
    )
    $script:AgenticEval = Read-RepoFile 'skills/agentic-eval/SKILL.md'
    $script:StageRubrics = Read-RepoFile 'skills/agentic-eval/references/stage-rubrics.md'
    $script:LifecycleRouterPaths = @(
        'AGENTS.md',
        'docs/AGENTS.template.md',
        'WORKFLOW.md',
        'QUICKSTART.md',
        'agents/brainstorm.agent.md',
        'agents/plan.agent.md',
        'agents/pm.agent.md',
        'prompts/brainstorm.prompt.md',
        'prompts/workflow.prompt.md',
        'skills/workflow-orchestrator/SKILL.md',
        'skills/brainstorming/SKILL.md',
        'skills/explore/SKILL.md',
        'skills/specification/SKILL.md',
        'skills/implementation-planning/SKILL.md'
    )
}

Describe 'Phase 1 Project AGENTS fallback contract' {
    It 'covers evidence and uncertainty' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $document.Content | Should -Match '(?is)Evidence and uncertainty.{0,500}facts.{0,120}assumptions.{0,120}inferences.{0,120}unknowns' -Because "$($document.Path) must carry the approved fallback rule"
            $document.Content | Should -Match '(?is)Evidence and uncertainty.{0,700}(?:must not|never).{0,120}(?:fabricate|invent).{0,160}(?:status|test results|sources|completion evidence)' -Because "$($document.Path) must carry the approved fallback semantics"
        }
    }

    It 'covers material assumptions' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $document.Content | Should -Match '(?is)Material assumptions.{0,700}(?:scope|contract).{0,160}security.{0,160}data.{0,160}migration.{0,160}verification' -Because "$($document.Path) must carry the approved fallback rule"
            $document.Content | Should -Match '(?is)Material assumptions.{0,700}(?:stop|clarif).{0,200}implementation path' -Because "$($document.Path) must carry the approved fallback semantics"
        }
    }

    It 'covers project context and SSOT conflicts' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $document.Content | Should -Match '(?is)Project context and SSOT.{0,700}(?:context|architecture).{0,160}(?:task/status SSOT|task and status SSOT)' -Because "$($document.Path) must carry the approved fallback rule"
            $document.Content | Should -Match '(?is)Project context and SSOT.{0,900}(?:conversation|plan).{0,160}spec.{0,160}code.{0,160}(?:vocabulary|glossary).{0,200}(?:stop|resolve)' -Because "$($document.Path) must carry the approved fallback semantics"
        }
    }

    It 'covers surgical scope control' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $document.Content | Should -Match '(?is)Surgical scope control.{0,600}(?:approved|authorized).{0,160}scope' -Because "$($document.Path) must carry the approved fallback rule"
            $document.Content | Should -Match '(?is)Surgical scope control.{0,700}drive-by refactor.{0,160}(?:format|formatting).{0,160}(?:speculative|unrequested|cross-phase)' -Because "$($document.Path) must carry the approved fallback semantics"
        }
    }

    It 'covers secrets and sensitive data' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $document.Content | Should -Match '(?is)Secrets and sensitive data.{0,700}secret.{0,100}credential.{0,100}token.{0,100}PII.{0,100}sensitive data' -Because "$($document.Path) must carry the approved fallback rule"
            $document.Content | Should -Match '(?is)Secrets and sensitive data.{0,900}(?:redact|mask).{0,180}(?:artifact|log|commit|remote)' -Because "$($document.Path) must carry the approved fallback semantics"
        }
    }

    It 'covers protected-action authorization without inferred approval' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $document.Content | Should -Match '(?is)Protected-action authorization.{0,900}commit.{0,100}push.{0,100}merge.{0,100}tag.{0,100}release.{0,160}branch deletion.{0,200}(?:deployment|production)' -Because "$($document.Path) must carry the approved fallback rule"
            $document.Content | Should -Match '(?is)Protected-action authorization.{0,1100}explicit.{0,100}current-task.{0,100}action-specific.{0,300}(?:must not|cannot).{0,160}(?:infer|imply).{0,200}(?:tool|agent)' -Because "$($document.Path) must carry the approved fallback semantics"
        }
    }

    It 'covers verification and deterministic blockers' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $document.Content | Should -Match '(?is)Verification and deterministic blockers.{0,900}targeted tests.{0,160}(?:full checks|full test).{0,160}static checks.{0,160}(?:project gates|project gate)' -Because "$($document.Path) must carry the approved fallback rule"
            $document.Content | Should -Match '(?is)Verification and deterministic blockers.{0,1100}(?:test|build).{0,120}lint.{0,120}security.{0,120}data-integrity.{0,200}blocking.{0,200}(?:self-evaluation|inference)' -Because "$($document.Path) must carry the approved fallback semantics"
        }
    }

    It 'covers risk escalation and rollback' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $document.Content | Should -Match '(?is)Risk escalation and rollback.{0,1000}auth.{0,100}security.{0,100}financial.{0,100}migration.{0,160}(?:public contract|public-contract).{0,160}destructive.{0,160}deployment.{0,160}production.{0,160}irreversible' -Because "$($document.Path) must carry the approved fallback rule"
            $document.Content | Should -Match '(?is)Risk escalation and rollback.{0,1300}(?:rollback|restore).{0,120}(?:compensation|safe-stop)' -Because "$($document.Path) must carry the approved fallback semantics"
        }
    }

    It 'covers honest completion states' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $document.Content | Should -Match '(?is)Honest completion.{0,700}approved scope.{0,160}verification.{0,160}delivery state' -Because "$($document.Path) must carry the approved fallback rule"
            $document.Content | Should -Match '(?is)Honest completion.{0,900}unverified.{0,100}unmerged.{0,100}partial.{0,100}Deferred.{0,100}blocked.{0,100}N/A.{0,160}(?:user decision|user-decision)' -Because "$($document.Path) must carry the approved fallback semantics"
        }
    }

    It 'contains exactly one standalone fallback block with exactly nine numbered rules in each Project AGENTS' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $blocks = [regex]::Matches($document.Content, '(?ms)^### Standalone Fallback Rules\s*$.*?(?=^##\s|\z)')
            $blocks.Count | Should -Be 1 -Because "$($document.Path) must have one standalone fallback block"
            [regex]::Matches($blocks[0].Value, '(?m)^\d+\. \*\*[^*]+\*\*:').Count | Should -Be 9 -Because "$($document.Path) fallback block must contain exactly nine numbered rules"
        }
    }

    It 'does not retain the superseded seven-part baseline in the same constitutional section' {
        foreach ($document in $script:ProjectAgentDocuments) {
            $constitutional = [regex]::Match($document.Content, '(?ms)^## (?:Cross-CLI )?Constitutional Baseline\s*$.*?(?=^##\s|\z)')
            $constitutional.Success | Should -BeTrue -Because "$($document.Path) must expose its constitutional section"
            $constitutional.Value | Should -Not -Match '(?m)^### [1-7]\. (?:Think Before Coding|Simplicity First|Surgical Changes|Goal-Driven Verification|Context Loading Order|Safety Floor|Communication Contract)\s*$' -Because "$($document.Path) must not keep a second fallback baseline"
        }
    }
}

Describe 'Phase 1 lifecycle ownership and execution modes' {
    It 'declares WORKFLOW as the maintainer lifecycle SSOT without preselecting an adopter source' {
        $script:Workflow | Should -Match '(?is)lifecycle SSOT'
        $script:Workflow | Should -Match '(?is)maintainer.{0,200}WORKFLOW\.md.{0,300}(?:adopter-facing|adopter).{0,300}(?:Phase 3|separate approval).{0,300}(?:open|not selected|must not)'
    }

    It 'selects exactly one of only Simple, Standard, and High-Risk' {
        $script:Workflow | Should -Match '(?is)exactly one.{0,200}Simple.{0,100}Standard.{0,100}High-Risk'
        $script:Workflow | Should -Match '(?m)^### Simple\s*$'
        $script:Workflow | Should -Match '(?m)^### Standard\s*$'
        $script:Workflow | Should -Match '(?m)^### High-Risk\s*$'
    }

    It 'defines Simple as localized reversible work with reliable targeted verification and no mandatory full lifecycle package' {
        $script:Workflow | Should -Match '(?is)### Simple.{0,1200}localized.{0,160}reversible.{0,500}reliable.{0,160}targeted verification'
        $script:Workflow | Should -Match '(?is)### Simple.{0,1600}(?:does not require|no mandatory).{0,160}(?:six-stage|six stage).{0,200}Change Package'
    }

    It 'defines the exact Standard compact-package triggers and one SSOT default' {
        $script:Workflow | Should -Match '(?is)### Standard.{0,1400}(?:exactly one|one declared).{0,160}(?:plan/lifecycle SSOT|plan or lifecycle SSOT)'
        $script:Workflow | Should -Match '(?is)### Standard.{0,1800}cross-session.{0,100}cross-component.{0,100}contract-change.{0,160}independent-review.{0,160}migration/audit.{0,160}escalation-prone'
    }

    It 'defines High-Risk boundaries and full delivery evidence' {
        $script:Workflow | Should -Match '(?is)### High-Risk.{0,1600}security.{0,100}auth.{0,100}permission.{0,120}financial.{0,120}migration.{0,160}(?:breaking|public).{0,160}irreversible.{0,160}(?:deployment|production).{0,160}architecture'
        $script:Workflow | Should -Match '(?is)### High-Risk.{0,2200}full Workflow.{0,160}Change Package.{0,160}explicit approvals.{0,160}independent review.{0,160}rollback/migration.{0,160}operational evidence'
    }

    It 'requires escalation before continuing across a higher-risk boundary' {
        $script:Workflow | Should -Match '(?is)(?:Simple|Standard).{0,500}(?:stop|stops).{0,160}(?:reclassif|escalat).{0,300}before.{0,160}(?:further|continue)'
    }

    It 'does not emit Fast Path as an execution-mode label from lifecycle owners or routers' {
        foreach ($path in $script:LifecycleRouterPaths) {
            Read-RepoFile $path | Should -Not -Match '(?i)\bfast(?:[ -]+)path\b' -Because "$path must route only Simple, Standard, or High-Risk"
        }
    }

    It 'keeps PM as a thin router to canonical Workflow and Skill owners' {
        $pmAgent = Read-RepoFile 'agents/pm.agent.md'

        $pmAgent | Should -Match '(?is)WORKFLOW\.md.{0,400}Simple.{0,160}Standard.{0,160}High-Risk'
        $pmAgent | Should -Match '(?is)WORKFLOW\.md.{0,300}(?:canonical|SSOT).{0,300}(?:mode|artifact)'
        $pmAgent | Should -Match '(?i)\]\(\.\./skills/workflow-orchestrator/SKILL\.md\)'
        $pmAgent | Should -Not -Match '(?m)^## (?:Stage Detection|Execution Mode Routing)\s*$'
    }

    It 'keeps package stage-detection procedure out of the PM persona' {
        $pmAgent = Read-RepoFile 'agents/pm.agent.md'

        $pmAgent | Should -Match '(?is)read status.{0,240}recommend the next Agent only'
        $pmAgent | Should -Match '(?i)workflow-orchestrator'
        $pmAgent | Should -Not -Match '(?is)\|\s*File Present\s*\|\s*Stage\s*\|\s*Next Step\s*\|'
    }

    It 'allows Simple routing without treating an absent Change Package as a missing artifact' {
        $pmAgent = Read-RepoFile 'agents/pm.agent.md'

        $script:Workflow | Should -Match '(?is)### Simple.{0,1600}(?:does not require|no mandatory).{0,160}(?:six-stage|six stage).{0,200}Change Package'
        $pmAgent | Should -Match '(?is)WORKFLOW\.md.{0,300}whether an artifact is required'
        $pmAgent | Should -Match '(?is)absence of optional artifacts alone.{0,160}not an artifact gap'
    }

    It 'keeps readiness and completion evidence mode-aware' {
        $script:Workflow | Should -Match '(?is)Definition of Ready.{0,1000}Simple.{0,300}(?:inline|targeted verification).{0,500}(?:Standard|High-Risk).{0,400}(?:required artifact|Change Package)'
        $script:Workflow | Should -Match '(?is)Definition of Done.{0,1200}Simple.{0,350}(?:does not require|no mandatory).{0,200}(?:PR|Change Package).{0,500}(?:Standard|High-Risk).{0,500}(?:review|evidence)'
    }

    It 'keeps brainstorm artifact creation conditional on the selected mode' {
        $brainstormPrompt = Read-RepoFile 'prompts/brainstorm.prompt.md'
        $brainstormSkill = Read-RepoFile 'skills/brainstorming/SKILL.md'
        $brainstormPrompt | Should -Not -Match '(?im)^\s*\d+\.\s+Create the change package skeleton\s*$'
        $brainstormPrompt | Should -Match '(?is)canonical Workflow contract.{0,160}declared by Project AGENTS'
        $brainstormPrompt | Should -Not -Match '(?i)\]\(\.\./WORKFLOW(?:\.md)?\)'
        $brainstormPrompt | Should -Match '(?i)\]\(\.\./skills/brainstorming/SKILL\.md\)'
        $brainstormPrompt | Should -Not -Match '(?m)^### (?:Simple|Standard|High-Risk)\s*$'
        $script:Workflow | Should -Match '(?is)### Simple.{0,1600}(?:does not require|no mandatory).{0,160}(?:six-stage|six stage).{0,200}Change Package'
        $brainstormSkill | Should -Match '(?is)Simple.{0,300}does not require a Change Package'
    }

    It 'summarizes all three canonical modes without collapsing Standard into High-Risk' {
        $script:MaintainerAgents | Should -Match '(?is)## Workflow.{0,900}Simple.{0,300}Standard.{0,300}High-Risk'
        $script:MaintainerAgents | Should -Not -Match '(?i)For medium/high-risk changes:.{0,200}(?:six-stage|/brainstorm)'
    }

    It 'does not make package-only Spec and plan artifacts mandatory for Simple routing' {
        $brainstormAgent = Read-RepoFile 'agents/brainstorm.agent.md'
        $planAgent = Read-RepoFile 'agents/plan.agent.md'
        $planningSkill = Read-RepoFile 'skills/implementation-planning/SKILL.md'

        $brainstormAgent | Should -Not -Match '(?is)Completion Conditions.{0,200}`01-brainstorm\.md` 已建立'
        $planAgent | Should -Not -Match '(?im)^- \*\*Inputs\*\*: `03-spec\.md` \(required\)'
        $planningSkill | Should -Not -Match '(?is)\*\*Required\*\*:\s*- `03-spec\.md` with clear requirements'
        $planningSkill | Should -Match '(?is)mode-required.{0,200}(?:Spec|03-spec\.md)'
    }
}

Describe 'Phase 1 named High-Risk gate contract' {
    It 'names the same four High-Risk gates in every direct policy owner' {
        $owners = @($script:Workflow, $script:MaintainerAgents, $script:AdopterAgents, $script:AgenticEval, $script:StageRubrics)
        $gateNames = @(
            'Architecture Decision Exit',
            'Pre-Implementation Readiness',
            'Pre-Delivery Verification',
            'Migration / Deployment Readiness'
        )

        foreach ($owner in $owners) {
            foreach ($gateName in $gateNames) {
                $owner | Should -Match ([regex]::Escape($gateName))
            }
        }
    }

    It 'defines Architecture Decision Exit blocking and warning-only conditions' {
        $script:Workflow | Should -Match '(?is)Architecture Decision Exit.{0,1800}Blocking conditions.{0,1300}unresolved safety or authorization.{0,300}(?:fabricated|unverified).{0,300}irreversible.{0,300}(?:rollback|migration|compensation).{0,300}contract conflict'
        $script:Workflow | Should -Match '(?is)Architecture Decision Exit.{0,2600}Warning-only.{0,500}maintainability.{0,500}(?:documentation|naming).{0,300}(?:correctness|security|reversibility|contract)'
    }

    It 'defines Pre-Implementation Readiness blocking and warning-only conditions' {
        $script:Workflow | Should -Match '(?is)Pre-Implementation Readiness.{0,1900}Blocking conditions.{0,1400}(?:AC|acceptance).{0,200}scope.{0,200}decision.{0,200}prerequisite.{0,300}protected-action approval.{0,400}(?:migration|rollback|recovery).{0,400}(?:RED/GREEN|verifiable path).{0,400}ownership'
        $script:Workflow | Should -Match '(?is)Pre-Implementation Readiness.{0,3000}Warning-only.{0,500}optional documentation.{0,400}(?:presentation|wording).{0,300}(?:safe|verifiable)'
    }

    It 'defines Pre-Delivery Verification deterministic, evidence, invariant, scope, and review blockers' {
        $script:Workflow | Should -Match '(?is)Pre-Delivery Verification.{0,2300}Blocking conditions.{0,1800}(?:test|build).{0,180}lint.{0,180}static check.{0,180}required gate.{0,350}(?:requirement|AC).{0,250}evidence.{0,350}security.{0,180}authorization.{0,180}financial.{0,180}data-integrity.{0,180}migration.{0,350}scope leakage.{0,300}generated drift.{0,300}working[- ]?tree.{0,350}independent review.{0,300}Critical.{0,100}High'
        $script:Workflow | Should -Match '(?is)Pre-Delivery Verification.{0,4200}Warning-only.{0,500}style.{0,300}presentation.{0,300}clarity.{0,300}(?:correctness|auditability)'
    }

    It 'defines Migration / Deployment Readiness as separately authorized and otherwise N/A' {
        $script:Workflow | Should -Match '(?is)Migration / Deployment Readiness.{0,2600}Blocking conditions.{0,2000}explicit.{0,120}current-task.{0,120}action-specific.{0,250}scope.{0,200}target.{0,200}batch.{0,250}affected population.{0,350}(?:rollback|restore|compensation|safe-stop).{0,400}rehearsal.{0,250}recovery validation.{0,300}operational signal.{0,400}ownership.{0,200}backup.{0,200}reversibility.{0,200}failure handling'
        $script:Workflow | Should -Match ([regex]::Escape('N/A — no migration or deployment execution is authorized in this Phase.'))
    }

    It 'enforces cross-gate blocking warning N/A and no-score semantics' {
        foreach ($owner in @($script:Workflow, $script:MaintainerAgents, $script:AdopterAgents, $script:AgenticEval)) {
            $owner | Should -Match '(?is)deterministic failure.{0,180}(?:always|is).{0,120}blocking'
            $owner | Should -Match '(?is)warning.{0,300}(?:must not|cannot).{0,200}(?:promot|become).{0,300}blocking condition'
            $owner | Should -Match '(?is)N/A.{0,180}(?:reason|rationale)'
            $owner | Should -Match '(?is)(?:no|does not use|introduces no).{0,160}aggregate.{0,160}(?:score|numeric threshold)'
        }
        $script:AgenticEval | Should -Match '(?is)named High-Risk gates.{0,600}(?:do not use|must not use|not applicable).{0,260}(?:score|numeric threshold|general-purpose scoring)'
    }

    It 'keeps agentic-eval self-evaluation separate from deterministic checks and independent review' {
        foreach ($owner in @($script:Workflow, $script:MaintainerAgents, $script:AdopterAgents, $script:AgenticEval, $script:StageRubrics)) {
            $owner | Should -Match '(?is)agentic-eval.{0,300}self-evaluation.{0,300}(?:not|never).{0,160}independent review'
            $owner | Should -Match '(?is)agentic-eval.{0,500}(?:cannot|must not|never).{0,200}(?:override|replace).{0,250}(?:test|build|deterministic)'
        }
        $script:AgenticEval | Should -Match '(?is)Simple.{0,160}not required.{0,300}Standard.{0,200}risk-triggered.{0,300}High-Risk.{0,300}(?:named|explicitly named) gates'
    }

    It 'preserves the Phase 3 lifecycle-source and Phase 4 Manifest-schema approval guards' {
        $script:Workflow | Should -Match '(?is)Phase 3.{0,300}adopter.{0,300}(?:open|separate user approval|not selected)'
        $script:Workflow | Should -Match '(?is)Phase 4.{0,300}Manifest schema.{0,300}(?:not approved|unapproved|separate approval)'
    }
}

Describe 'Phase 1 generated runtime parity' {
    It 'keeps every changed canonical Agent Prompt and Skill byte-equal to its generated mirror' {
        $canonicalPaths = @(
            'agents/brainstorm.agent.md',
            'agents/plan.agent.md',
            'prompts/brainstorm.prompt.md',
            'prompts/workflow.prompt.md',
            'skills/workflow-orchestrator/SKILL.md',
            'skills/brainstorming/SKILL.md',
            'skills/explore/SKILL.md',
            'skills/specification/SKILL.md',
            'skills/implementation-planning/SKILL.md',
            'skills/agentic-eval/SKILL.md',
            'skills/agentic-eval/references/stage-rubrics.md'
        )

        foreach ($canonicalPath in $canonicalPaths) {
            $canonical = [IO.File]::ReadAllBytes((Join-Path $script:RepoRoot $canonicalPath))
            $derived = [IO.File]::ReadAllBytes((Join-Path $script:RepoRoot ".github/$canonicalPath"))
            [Linq.Enumerable]::SequenceEqual($canonical, $derived) | Should -BeTrue -Because "$canonicalPath must be generator-owned and byte-equal"
        }
    }

    It 'keeps every Phase 2 changed canonical Agent Skill Prompt and Instruction byte-equal to its generated mirror' {
        $canonicalPaths = @(
            'agents/architect.agent.md',
            'agents/brainstorm.agent.md',
            'agents/code-reviewer.agent.md',
            'agents/coder.agent.md',
            'agents/dba.agent.md',
            'agents/frontend-designer.agent.md',
            'agents/plan.agent.md',
            'agents/pm.agent.md',
            'agents/spec.agent.md',
            'skills/backend-patterns/SKILL.md',
            'skills/frontend-patterns/SKILL.md',
            'skills/code-security-review/SKILL.md',
            'skills/implementation-planning/SKILL.md',
            'prompts/archive.prompt.md',
            'prompts/brainstorm.prompt.md',
            'prompts/code-review.prompt.md',
            'prompts/commit-gen.prompt.md',
            'prompts/create-plan.prompt.md',
            'prompts/spec.prompt.md',
            'prompts/tdd.prompt.md',
            'prompts/workflow.prompt.md',
            'instructions/code-review.instructions.md',
            'instructions/python.instructions.md',
            'instructions/playbooks/architect.md',
            'instructions/playbooks/database-reviewer.md',
            'instructions/playbooks/planner.md',
            'instructions/playbooks/security-reviewer.md',
            'instructions/playbooks/tdd-guide.md'
        )

        foreach ($canonicalPath in $canonicalPaths) {
            $canonical = [IO.File]::ReadAllBytes((Join-Path $script:RepoRoot $canonicalPath))
            $derived = [IO.File]::ReadAllBytes((Join-Path $script:RepoRoot ".github/$canonicalPath"))
            [Linq.Enumerable]::SequenceEqual($canonical, $derived) | Should -BeTrue -Because "$canonicalPath must be generator-owned and byte-equal"
        }
    }
}
