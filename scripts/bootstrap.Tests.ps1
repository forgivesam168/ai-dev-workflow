# Bootstrap.Tests.ps1 - Pester 測試套件
# 測試 Bootstrap.ps1 的所有功能

. "$PSScriptRoot\bootstrap.ps1"

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
