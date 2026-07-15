BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent
    $script:SkillPath = Join-Path $script:RepoRoot 'skills/work-archiving/SKILL.md'
    $script:SkillMirrorPath = Join-Path $script:RepoRoot '.github/skills/work-archiving/SKILL.md'
    $script:PromptPath = Join-Path $script:RepoRoot 'prompts/archive.prompt.md'
    $script:PromptMirrorPath = Join-Path $script:RepoRoot '.github/prompts/archive.prompt.md'
    $script:WorkflowPath = Join-Path $script:RepoRoot 'WORKFLOW.md'

    $script:SkillText = Get-Content -LiteralPath $script:SkillPath -Raw
    $script:PromptText = Get-Content -LiteralPath $script:PromptPath -Raw
    $script:WorkflowText = Get-Content -LiteralPath $script:WorkflowPath -Raw
    $script:ArchiveTexts = @($script:SkillText, $script:PromptText)

    function Get-FencedCodeBlocks {
        param([string]$Text)

        return @([regex]::Matches($Text, '(?ms)```[^\r\n]*\r?\n(.*?)```') |
            ForEach-Object { $_.Groups[1].Value })
    }

    function Get-ExecutableProtectedCommandMatches {
        param([string]$Text)

        $commandPatterns = @(
            '(?im)^\s*(?:git|gh)\s+add\b.*$',
            '(?im)^\s*(?:git|gh)\s+commit\b.*$',
            '(?im)^\s*(?:git|gh)\s+push\b.*$',
            '(?im)^\s*(?:git|gh)\s+tag\b.*$',
            '(?im)^\s*(?:git|gh)\s+merge\b.*$',
            '(?im)^\s*(?:git|gh)\s+branch\s+-[dD]\b.*$',
            '(?im)^\s*gh\s+pr\s+merge\b.*$',
            '(?im)^\s*gh\s+pr\s+close\b.*$',
            '(?im)^\s*gh\s+issue\s+close\b.*$',
            '(?im)^\s*git\s+push\s+\S+\s+--delete\b.*$',
            '(?im)^\s*(?:run|execute|use|perform|invoke|then)\b.*\b(?:git|gh)\s+(?:add|commit|push|tag|merge|branch|pr|issue)\b.*$'
        )

        $matches = [System.Collections.Generic.List[string]]::new()
        foreach ($block in Get-FencedCodeBlocks -Text $Text) {
            foreach ($pattern in $commandPatterns) {
                foreach ($match in [regex]::Matches($block, $pattern)) {
                    $matches.Add($match.Value.Trim())
                }
            }
        }

        $nonFencedText = [regex]::Replace($Text, '(?ms)```[^\r\n]*\r?\n(.*?)```', '')
        foreach ($pattern in $commandPatterns) {
            foreach ($match in [regex]::Matches($nonFencedText, $pattern)) {
                $matches.Add($match.Value.Trim())
            }
        }

        return $matches.ToArray()
    }
}

Describe 'Phase 0D archive authorization' {
    It 'declares local archive documentation as the only Archive-authorized scope' {
        foreach ($text in $script:ArchiveTexts) {
            $text | Should -Match '(?i)Archive (?:request|invocation).{0,100}(?:only|authorizes only).{0,100}local archive documentation'
            $text | Should -Match '(?i)(?:create|update).{0,80}archive (?:document|summary)'
            $text | Should -Match '(?i)(?:read-only|readonly).{0,80}(?:commit|PR|Issue).{0,80}evidence'
        }
    }

    It 'requires explicit current-task action-specific approval for protected actions' {
        foreach ($text in $script:ArchiveTexts) {
            $text | Should -Match '(?i)explicit.{0,80}current-task.{0,80}action-specific.{0,100}(?:approval|authorization)'
            $text | Should -Match '(?i)one approval.{0,100}(?:does not|cannot).{0,100}another'
            $text | Should -Match '(?i)approval for commit.{0,80}(?:does not|cannot).{0,80}push'
            $text | Should -Match '(?i)approval for push.{0,80}(?:does not|cannot).{0,80}tag'
            $text | Should -Match '(?i)approval for merge.{0,80}(?:does not|cannot).{0,80}branch deletion'
            $text | Should -Match '(?i)approval for documentation.{0,80}(?:does not|cannot).{0,80}remote closure'
        }
    }

    It 'lists every protected action separately' {
        $requiredActions = @(
            'commit',
            'push',
            'tag',
            'merge',
            'local branch deletion',
            'remote branch deletion',
            'remote Issue closure',
            'remote PR closure'
        )

        foreach ($text in $script:ArchiveTexts) {
            foreach ($action in $requiredActions) {
                $text | Should -Match "(?i)$([regex]::Escape($action))"
            }
        }
    }

    It 'defines safe stop, reporting, and handoff behavior when approval is missing' {
        foreach ($text in $script:ArchiveTexts) {
            $text | Should -Match '(?i)(?:without|missing|lack).{0,100}(?:approval|authorization)'
            $text | Should -Match '(?i)do not execute'
            $text | Should -Match '(?i)report.{0,100}(?:specific|exact|required).{0,100}(?:action|approval)'
            $text | Should -Match '(?i)(?:safe|local).{0,100}(?:handoff|stop)'
        }
    }

    It 'does not contain executable protected Git or gh command examples' {
        foreach ($text in $script:ArchiveTexts) {
            $matches = @(Get-ExecutableProtectedCommandMatches -Text $text)
            $matches | Should -BeNullOrEmpty
        }
    }

    It 'does not retain legacy unsafe Archive imperatives' {
        $legacyPatterns = @(
            '(?i)handles\s+git\s+commits',
            '(?i)all\s+changes\s+(?:must\s+be\s+)?committed\s+and\s+pushed',
            '(?i)commit\s+and\s+tag',
            '(?i)close\s+related\s+(?:issues|PRs|pull requests)',
            '(?i)remove\s+temporary\s+branches',
            '(?i)push\s+changes\s+to\s+remote\s+before\s+(?:finalizing|archiving|archive)'
        )

        foreach ($text in $script:ArchiveTexts) {
            foreach ($pattern in $legacyPatterns) {
                $text | Should -Not -Match $pattern
            }
        }
    }

    It 'removes elevated privilege signals from the Archive Prompt frontmatter' {
        $frontmatter = ([regex]::Match($script:PromptText, '(?ms)^---\s*(.*?)\s*---')).Groups[1].Value
        $frontmatter | Should -Not -Match '(?i)\[Admin\]'
        $frontmatter | Should -Not -Match '(?i)\b(?:admin|elevated|autonomous|implicit permission)\b'
    }

    It 'keeps Archive mapped only to work-archiving in WORKFLOW' {
        $archiveRow = ([regex]::Matches($script:WorkflowText, '(?im)^\|\s*6\.\s*Archive\s*\|.*$') | Select-Object -First 1).Value
        $archiveRow | Should -Match '(?i)work-archiving'
        $archiveRow | Should -Not -Match '(?i)git-commit'
        $script:WorkflowText | Should -Match '(?i)Archive does not grant Git or remote authorization'
        $script:WorkflowText | Should -Match '(?i)protected actions require separate current-task approval'
    }

    It 'preserves Stage 6, after-merge timing, filename, ADR criteria, and data guards' {
        $allText = $script:ArchiveTexts -join "`n"
        $allText | Should -Match '(?i)Stage 6\s*\(Archive\)'
        $allText | Should -Match '(?i)after PR is merged'
        $allText | Should -Match '99-archive\.md'
        $allText | Should -Match '(?i)Hard to reverse'
        $allText | Should -Match '(?i)Future confusion'
        $allText | Should -Match '(?i)Real trade-off'
        $allText | Should -Match '(?i)All three must be true'
        $allText | Should -Match '(?i)secrets'
        $allText | Should -Match '(?i)(?:sensitive data|PII)'
        $allText | Should -Match '(?i)historical Archive artifacts.{0,80}readable'
    }

    It 'preserves the requested local documentation writes without treating them as Git authorization' {
        foreach ($text in $script:ArchiveTexts) {
            $text | Should -Match '(?i)(?:create|update).{0,100}(?:archive document|archive summary)'
            $text | Should -Match '(?i)work log'
            $text | Should -Match '(?i)CHANGELOG'
            $text | Should -Match '(?i)documentation.{0,100}(?:does not|cannot).{0,100}(?:authorize|grant).{0,100}(?:commit|push|remote)'
        }
    }

    It 'keeps canonical and derived Archive Skill and Prompt files byte-for-byte equal' {
        $skillCanonical = [IO.File]::ReadAllBytes($script:SkillPath)
        $skillDerived = [IO.File]::ReadAllBytes($script:SkillMirrorPath)
        $promptCanonical = [IO.File]::ReadAllBytes($script:PromptPath)
        $promptDerived = [IO.File]::ReadAllBytes($script:PromptMirrorPath)

        [Linq.Enumerable]::SequenceEqual($skillCanonical, $skillDerived) | Should -BeTrue
        [Linq.Enumerable]::SequenceEqual($promptCanonical, $promptDerived) | Should -BeTrue
    }
}
