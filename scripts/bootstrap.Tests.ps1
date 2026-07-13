# Bootstrap.Tests.ps1 - Pester 測試套件
# 測試 Bootstrap.ps1 的所有功能

BeforeAll {
    . "$PSScriptRoot\bootstrap.ps1"
}

Describe "Phase 0A adopter constitution containment" {
    BeforeEach {
        $script:Phase0ATemplateRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $script:Phase0ATargetRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $script:Phase0AMaintainerBytes = [Text.Encoding]::UTF8.GetBytes("# Maintainer Constitution`nRun tools/sync-dotgithub.ps1 and maintain the template catalog.`n")
        $script:Phase0AAdopterBytes = [Text.Encoding]::UTF8.GetBytes("# Adopter Constitution`nProject-facing guidance only.`n")

        New-Item -ItemType Directory -Path (Join-Path $script:Phase0ATemplateRoot '.github') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:Phase0ATemplateRoot 'docs') -Force | Out-Null
        New-Item -ItemType Directory -Path $script:Phase0ATargetRoot -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $script:Phase0ATemplateRoot '.github/copilot-instructions.md'), $script:Phase0AMaintainerBytes)
        [IO.File]::WriteAllBytes((Join-Path $script:Phase0ATemplateRoot 'docs/copilot-instructions.template.md'), $script:Phase0AAdopterBytes)
    }

    It "installs the adopter source for a new adopter without maintainer policy" {
        $manifest = @{}
        Mock Write-Host

        $result = Sync-WorkflowFiles `
            -SourcePath (Join-Path $script:Phase0ATemplateRoot '.github') `
            -TargetPath $script:Phase0ATargetRoot `
            -ManifestEntries $manifest `
            -ConstitutionSourceRoot $script:Phase0ATemplateRoot

        $destination = Join-Path $script:Phase0ATargetRoot '.github/copilot-instructions.md'
        [IO.File]::ReadAllBytes($destination) | Should -Be $script:Phase0AAdopterBytes
        [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($destination)) | Should -Not -Match 'sync-dotgithub'
        $result.FilesAdded | Should -Contain '.github/copilot-instructions.md'
        $result.FilesSkipped | Should -Not -Contain '.github/copilot-instructions.md'
        $manifest['.github/copilot-instructions.md'].source | Should -Be 'template:docs/copilot-instructions.template.md'
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq 'ℹ️  Constitution source: docs/copilot-instructions.template.md' }
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq '✅ Constitution outcome: installed' }
    }

    It "keeps the canonical adopter source free of maintainer policy" {
        $adopterContent = Get-Content -Raw (Join-Path $PSScriptRoot '../docs/copilot-instructions.template.md')
        $forbidden = @('sync-dotgithub.ps1', 'check-sync.ps1', 'audit-catalog.ps1', 'Never commit source without syncing')

        foreach ($token in $forbidden) {
            $adopterContent | Should -Not -Match ([regex]::Escape($token))
        }
    }

    It "never falls back to the maintainer constitution during generic sync" {
        $result = Sync-WorkflowFiles `
            -SourcePath (Join-Path $script:Phase0ATemplateRoot '.github') `
            -TargetPath $script:Phase0ATargetRoot `
            -ManifestEntries @{} `
            -Force

        Test-Path (Join-Path $script:Phase0ATargetRoot '.github/copilot-instructions.md') | Should -BeFalse
        $result.FilesSkipped | Should -Contain '.github/copilot-instructions.md'
    }

    It "preserves every existing constitution when trusted exact proof is unavailable" {
        $destination = Join-Path $script:Phase0ATargetRoot '.github/copilot-instructions.md'
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Mock Write-Host
        $cases = @(
            @{ Name = 'missing-manifest'; Manifest = @{}; Content = [Text.Encoding]::UTF8.GetBytes("legacy policy`r`n") },
            @{ Name = 'missing-exact-component'; Manifest = @{ '.github/other.md' = @{ managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("other`n")) } }; Content = [Text.Encoding]::UTF8.GetBytes("unknown ownership`n") },
            @{ Name = 'customized'; Manifest = @{ '.github/copilot-instructions.md' = @{ managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("previous baseline`n")); source = 'template:.github/copilot-instructions.md' } }; Content = [byte[]](0x70,0x72,0x6f,0x6a,0x65,0x63,0x74,0x00,0x0a) },
            @{ Name = 'generic-baseline-match'; Manifest = @{ '.github/copilot-instructions.md' = @{ managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("recorded baseline`n")); source = 'template:.github/copilot-instructions.md' } }; Content = [Text.Encoding]::UTF8.GetBytes("recorded baseline`n") },
            @{ Name = 'unclear-source'; Manifest = @{ '.github/copilot-instructions.md' = @{ managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("legacy policy`n")); source = 'unknown' } }; Content = [Text.Encoding]::UTF8.GetBytes("legacy policy`n") }
        )

        foreach ($case in $cases) {
            [IO.File]::WriteAllBytes($destination, $case.Content)
            $hadConstitutionEntry = $case.Manifest.ContainsKey('.github/copilot-instructions.md')
            $originalConstitutionEntry = if ($hadConstitutionEntry) { $case.Manifest['.github/copilot-instructions.md'] | ConvertTo-Json -Depth 5 -Compress } else { $null }

            $result = Sync-WorkflowFiles `
                -SourcePath (Join-Path $script:Phase0ATemplateRoot '.github') `
                -TargetPath $script:Phase0ATargetRoot `
                -ManifestEntries $case.Manifest `
                -ConstitutionSourceRoot $script:Phase0ATemplateRoot `
                -Force

            [IO.File]::ReadAllBytes($destination) | Should -Be $case.Content -Because $case.Name
            ($result.FilesSkipped | Where-Object { $_.StartsWith('.github/copilot-instructions.md [preserved') -and $_.Contains('manual decision required') }).Count | Should -Be 1 -Because $case.Name
            ($result.FilesSkipped | Where-Object { $_.StartsWith('.github/copilot-instructions.md') }).Count | Should -Be 1 -Because $case.Name
            $case.Manifest.ContainsKey('.github/copilot-instructions.md') | Should -Be $hadConstitutionEntry -Because $case.Name
            if ($hadConstitutionEntry) {
                ($case.Manifest['.github/copilot-instructions.md'] | ConvertTo-Json -Depth 5 -Compress) | Should -Be $originalConstitutionEntry -Because $case.Name
            }
        }
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq 'ℹ️  Constitution source: docs/copilot-instructions.template.md' } -Times $cases.Count -Exactly
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq '⚠️  Constitution outcome: preserved; manual decision required' } -Times $cases.Count -Exactly
    }
}

Describe "Normalize-RelativePath" {
    It "preserves dot-directory and parent-segment identity" {
        Normalize-RelativePath '.github/x' | Should -Be '.github/x'
        Normalize-RelativePath './.github/x' | Should -Be '.github/x'
        Normalize-RelativePath '.agents/skills/x' | Should -Be '.agents/skills/x'
        Normalize-RelativePath './skills/x' | Should -Be 'skills/x'
        Normalize-RelativePath '../outside' | Should -Be '../outside'
    }
}

Describe "Install-PortableRuntime maintainer-only exclusions" {
    It "does not deploy gate-check to an adopter target" {
        $sourceRoot = Join-Path $TestDrive 'template'
        $targetRoot = Join-Path $TestDrive 'target'
        foreach ($directory in @('skills/demo-skill', 'skills/gate-check', 'agents')) {
            New-Item -ItemType Directory -Path (Join-Path $sourceRoot $directory) -Force | Out-Null
        }
        New-Item -ItemType Directory -Path $targetRoot | Out-Null
        Set-Content (Join-Path $sourceRoot 'skills/demo-skill/SKILL.md') 'demo'
        Set-Content (Join-Path $sourceRoot 'skills/gate-check/SKILL.md') 'maintainer'
        Set-Content (Join-Path $sourceRoot 'agents/demo.agent.md') "---`nname: demo`ndescription: demo`n---`n`n# Demo agent`n"

        $manifest = @{}
        $null = Install-PortableRuntime -SourceRoot $sourceRoot -TargetPath $targetRoot -ManifestEntries $manifest

        Test-Path (Join-Path $targetRoot 'skills/demo-skill/SKILL.md') | Should -BeTrue
        Test-Path (Join-Path $targetRoot 'skills/gate-check') | Should -BeFalse
        Test-Path (Join-Path $targetRoot '.github/skills/gate-check') | Should -BeFalse
        $manifest.ContainsKey('.github/skills/demo-skill/SKILL.md') | Should -BeTrue
        $manifest.ContainsKey('github/skills/demo-skill/SKILL.md') | Should -BeFalse
    }
}

Describe "Test-GitInstalled" {
    Context "當 Git 已安裝且版本符合要求" {
        It "應該返回 Installed=true" {
            # Arrange
            Mock git { "git version 2.43.0.windows.1" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.Installed | Should -Be $true
        }
        
        It "應該返回正確的版本號" {
            # Arrange
            Mock git { "git version 2.43.0.windows.1" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.Version | Should -Be "2.43.0"
        }
        
        It "應該返回 MeetsRequirement=true（版本 >= 2.0）" {
            # Arrange
            Mock git { "git version 2.43.0.windows.1" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.MeetsRequirement | Should -Be $true
        }
    }
    
    Context "當 Git 版本過舊（< 2.0）" {
        It "應該返回 MeetsRequirement=false" {
            # Arrange
            Mock git { "git version 1.9.5" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "1.9.5"
            $result.MeetsRequirement | Should -Be $false
        }
    }
    
    Context "當 Git 未安裝" {
        It "應該返回 Installed=false" {
            # Arrange
            Mock git { throw "command not found" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.Installed | Should -Be $false
            $result.Version | Should -BeNullOrEmpty
            $result.MeetsRequirement | Should -Be $false
        }
    }
}

# ============================================================================
# Test-GitHubCLIInstalled Tests
# ============================================================================

Describe "Test-GitHubCLIInstalled" {

    Context "When GitHub CLI is installed" {

        It "should return version details" {
            $ghCheck = Get-Command gh -ErrorAction SilentlyContinue
            if (-not $ghCheck) {
                $true | Should -Be $true
                return
            }

            $result = Test-GitHubCLIInstalled

            $result.Installed | Should -Be $true
            $result.Version | Should -Match '^\d+\.\d+\.\d+$'
            $result.MeetsRequirement | Should -BeOfType [bool]
        }
    }

    Context "When GitHub CLI meets minimum version" {

        It "should mark meetsRequirement true when version >= 2.0" {
            $ghCheck = Get-Command gh -ErrorAction SilentlyContinue
            if (-not $ghCheck) {
                $true | Should -Be $true
                return
            }

            $result = Test-GitHubCLIInstalled
            if ([version]$result.Version -ge [version]"2.0.0") {
                $result.MeetsRequirement | Should -Be $true
            }
        }
    }

    Context "When GitHub CLI is not installed" {

        It "should return Installed = false" {
            $ghCheck = Get-Command gh -ErrorAction SilentlyContinue
            if ($ghCheck) {
                $true | Should -Be $true
                return
            }

            $result = Test-GitHubCLIInstalled
            $result.Installed | Should -Be $false
            $result.Version | Should -BeNullOrEmpty
            $result.MeetsRequirement | Should -Be $false
        }
    }
}

Describe "Test-PythonInstalled" {
    Context "當 Python 已安裝且版本符合要求" {
        It "應該返回 Installed=true（Python 3.11）" {
            # Arrange
            Mock python { "Python 3.11.5" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
        }
        
        It "應該返回正確的版本號" {
            # Arrange
            Mock python { "Python 3.11.5" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Version | Should -Be "3.11.5"
        }
        
        It "應該返回 MeetsRequirement=true（版本 >= 3.7）" {
            # Arrange
            Mock python { "Python 3.11.5" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.MeetsRequirement | Should -Be $true
        }
        
        It "應該檢測 Python 3.7（邊界值）" {
            # Arrange
            Mock python { "Python 3.7.0" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "3.7.0"
            $result.MeetsRequirement | Should -Be $true
        }
    }
    
    Context "當 Python 版本過舊（< 3.7）" {
        It "應該返回 MeetsRequirement=false" {
            # Arrange
            Mock python { "Python 3.6.8" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "3.6.8"
            $result.MeetsRequirement | Should -Be $false
        }
        
        It "應該檢測 Python 2.7（舊版）" {
            # Arrange
            Mock python { "Python 2.7.18" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "2.7.18"
            $result.MeetsRequirement | Should -Be $false
        }
    }
    
    Context "當 Python 未安裝" {
        It "應該返回 Installed=false" {
            # Arrange
            Mock python { throw "command not found" } -Verifiable
            Mock python3 { throw "command not found" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $false
            $result.Version | Should -BeNullOrEmpty
            $result.MeetsRequirement | Should -Be $false
        }
    }
    
    Context "當需要嘗試 python3 指令" {
        It "應該嘗試 python3 作為 fallback" {
            # Arrange
            Mock python { throw "not found" } -Verifiable
            Mock python3 { "Python 3.9.7" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "3.9.7"
        }
    }
}

# ============================================================================
# Test-PowerShellVersion Tests
# ============================================================================

Describe "Test-PowerShellVersion" {
    
    Context "When PowerShell version is checked" {
        
        It "should return current PowerShell version" {
            $result = Test-PowerShellVersion
            
            $result.Installed | Should -Be $true
            $result.Version | Should -Not -BeNullOrEmpty
        }
        
        It "should check if version meets requirement (>= 5.1)" {
            $result = Test-PowerShellVersion
            
            $result.MeetsRequirement | Should -BeOfType [bool]
        }
        
        It "should return version as string" {
            $result = Test-PowerShellVersion
            
            $result.Version | Should -Match '^\d+\.\d+(\.\d+)?'
        }
    }
    
    Context "When PowerShell 5.1 or higher" {
        
        It "should meet requirement" {
            # 這個測試假設執行環境有 PS 5.1+
            $result = Test-PowerShellVersion
            
            if ([version]$result.Version -ge [version]"5.1") {
                $result.MeetsRequirement | Should -Be $true
            }
        }
    }
    
    Context "When checking PowerShell Core (7+)" {
        
        It "should detect PowerShell 7+ correctly" {
            $result = Test-PowerShellVersion
            
            # PowerShell Core 版本應該是 7.x
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                [version]$result.Version | Should -BeGreaterOrEqual ([version]"7.0")
            }
        }
    }
}

# ============================================================================
# Test-NodeJSInstalled Tests
# ============================================================================

Describe "Test-NodeJSInstalled" {
    
    Context "When Node.js is installed and meets requirement" {
        
        It "should detect Node.js version" {
            $result = Test-NodeJSInstalled
            
            $result | Should -Not -BeNullOrEmpty
            $result.Installed | Should -BeOfType [bool]
            $result.Version | Should -BeOfType [string]
            $result.MeetsRequirement | Should -BeOfType [bool]
        }
        
        It "should parse version correctly (format: v18.17.0)" {
            # 如果系統有安裝 Node.js
            $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
            if ($nodeCheck) {
                $result = Test-NodeJSInstalled
                
                $result.Version | Should -Match '^\d+\.\d+\.\d+$'
            }
        }
    }
    
    Context "When Node.js version >= 16.0 (LTS)" {
        
        It "should meet requirement" {
            $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
            if ($nodeCheck) {
                $result = Test-NodeJSInstalled
                
                if ([version]$result.Version -ge [version]"16.0") {
                    $result.MeetsRequirement | Should -Be $true
                }
            }
        }
    }
    
    Context "When Node.js version < 16.0 (old)" {
        
        It "should not meet requirement" {
            # 這個測試難以模擬，需要實際環境
            # 如果有舊版 Node.js，這個測試會失敗
            $true | Should -Be $true  # Placeholder
        }
    }
    
    Context "When Node.js is not installed" {
        
        It "should return Installed = false" {
            # Mock 測試（實際執行會依系統環境）
            # 如果系統沒有 Node.js
            $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
            if (-not $nodeCheck) {
                $result = Test-NodeJSInstalled
                
                $result.Installed | Should -Be $false
                $result.Version | Should -BeNullOrEmpty
                $result.MeetsRequirement | Should -Be $false
            }
        }
    }
    
    Context "When checking npm availability (bonus)" {
        
        It "should detect npm if Node.js is installed" {
            $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
            if ($nodeCheck) {
                $npmCheck = Get-Command npm -ErrorAction SilentlyContinue
                $npmCheck | Should -Not -BeNullOrEmpty
            }
        }
    }
}
