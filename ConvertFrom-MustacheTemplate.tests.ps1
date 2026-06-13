[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'oldCulture', Justification = 'Test setup/teardown')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'oldUICulture', Justification = 'Test setup/teardown')]
param()

BeforeAll {
    Import-Module .\PSMustache.psd1

    # Tests are written for en-US-Formatting.
    $oldCulture = [cultureinfo]::CurrentCulture
    $oldUICulture = [cultureinfo]::CurrentUICulture
    [cultureinfo]::CurrentCulture = 'en-US'
    [cultureinfo]::CurrentUICulture = 'en-US'
}

Describe "Mustache Tests from GIT" {
    $areas = @(
        @{Name = "Comments";        FileName = Join-Path $PSScriptRoot '.\spec\specs\comments.json' }
        @{Name = "Interpolation";   FileName = Join-Path $PSScriptRoot '.\spec\specs\interpolation.json'}
        @{Name = "Sections";        FileName = Join-Path $PSScriptRoot '.\spec\specs\sections.json'}
        @{Name = "Inverted";        FileName = Join-Path $PSScriptRoot '.\spec\specs\inverted.json'}
        @{Name = "Partials";        FileName = Join-Path $PSScriptRoot '.\spec\specs\partials.json'}
        @{Name = "Delimiters";      FileName = Join-Path $PSScriptRoot '.\spec\specs\delimiters.json'}
        @{Name = "Lambdas";         FileName = Join-Path $PSScriptRoot '.\spec\specs\~lambdas.json'}
        @{Name = "DynamicNames";    FileName = Join-Path $PSScriptRoot '.\spec\specs\~dynamic-names.json'}
    )

    Context "<Name> (as PSObject)" -Foreach $areas {
        $tests = @()
        foreach ($curTest in (Get-Content $_.FileName | ConvertFrom-Json).tests) {
            if (!($curTest.data -is [System.Array]) -and ($null -ne $curTest.data.lambda)) {
                $curTest.data.lambda = [scriptblock]::Create($curTest.data.lambda.pwsh)
            }
            $tests += @{
                Name        = $curTest.name;
                Template    = $curTest.template;
                Expected    = $curTest.expected;
                Values      = $curTest.data;
                Partials    = $curTest.partials;
            }
        }
        It -Name "Test: <name>" -TestCases $tests {
            $template = $_.template
            $expected = $_.expected
            ConvertFrom-MustacheTemplate -template $template -Values $_.Values -Partials $_.Partials | Should -Be $expected
        }
    }

    if ($PSEdition -eq "Core") {
        Context "<Name> (as HashTable)" -Foreach $areas {
            $tests = @()
            foreach ($curTest in (Get-Content $_.FileName | ConvertFrom-Json -AsHashtable).tests) {
                if (!($curTest.data -is [System.Array]) -and ($null -ne $curTest.data.lambda)) {
                    $curTest.data.lambda = [scriptblock]::Create($curTest.data.lambda.pwsh)
                }
                $tests += @{
                    Name        = $curTest.name;
                    Template    = $curTest.template;
                    Expected    = $curTest.expected;
                    Values      = $curTest.data;
                    Partials    = $curTest.partials;
                }
            }
            It -Name "Test: <name>" -TestCases $tests {
                $template = $_.template
                $expected = $_.expected
                ConvertFrom-MustacheTemplate -template $template -Values $_.Values -Partials $_.Partials | Should -Be $expected
            }
        }
    }

    Context "<Name> (as PSObject with cached Template and Values from Pipeline)" -Foreach $areas {
        $tests = @()
        foreach ($curTest in (Get-Content $_.FileName | ConvertFrom-Json).tests) {
            if (!($curTest.data -is [System.Array]) -and ($null -ne $curTest.data.lambda)) {
                $curTest.data.lambda = [scriptblock]::Create($curTest.data.lambda.pwsh)
            }
            $tests += @{
                Name        = $curTest.name;
                Template    = $curTest.template;
                Expected    = $curTest.expected;
                Values      = $curTest.data;
                Partials    = $curTest.partials;
            }
        }
        It -Name "Test: <name>" -TestCases $tests {
            if ($_.Values -is [array]) {
                Set-ItResult -Skipped -Because 'Root-Level Arrays through Pipeline would be iterated'
                return
            }
            $template = $_.template
            $expected = $_.expected
            $cachedTemplate = Get-MustacheTemplate -template $template
            $_.Values | ConvertFrom-MustacheTemplate -Template $cachedTemplate -Partials $_.Partials | Should -Be $expected
        }
    }
}

Describe "PowerShell specific Tests" {
    $areas = @(
        @{Name = "Delimiters";      FileName = Join-Path $PSScriptRoot '.\tests\delimiters-outside.json'}
    )

    Context "<Name> (as PSObject)" -Foreach $areas {
        $tests = @()
        foreach ($curTest in (Get-Content $_.FileName | ConvertFrom-Json).tests) {
            if (!($curTest.data -is [System.Array]) -and ($null -ne $curTest.data.lambda)) {
                $curTest.data.lambda = [scriptblock]::Create($curTest.data.lambda.pwsh)
            }
            $tests += @{
                Name            = $curTest.name;
                Template        = $curTest.template;
                Expected        = $curTest.expected;
                Values          = $curTest.data;
                Partials        = $curTest.partials;
                DelimiterLeft   = $curTest.delimiterLeft;
                DelimiterRight  = $curTest.delimiterRight;
            }
        }
        It -Name "Test: <name>" -TestCases $tests {
            $template = $_.template
            $expected = $_.expected
            ConvertFrom-MustacheTemplate -template $template -Values $_.Values -Partials $_.Partials -DelimiterLeft $_.DelimiterLeft -DelimiterRight $_.DelimiterRight | Should -Be $expected
        }
    }

    if ($PSEdition -eq "Core") {
        Context "<Name> (as HashTable)" -Foreach $areas {
            $tests = @()
            foreach ($curTest in (Get-Content $_.FileName | ConvertFrom-Json -AsHashtable).tests) {
                if (!($curTest.data -is [System.Array]) -and ($null -ne $curTest.data.lambda)) {
                    $curTest.data.lambda = [scriptblock]::Create($curTest.data.lambda.pwsh)
                }
                $tests += @{
                    Name        = $curTest.name;
                    Template    = $curTest.template;
                    Expected    = $curTest.expected;
                    Values      = $curTest.data;
                    Partials    = $curTest.partials;
                    DelimiterLeft   = $curTest.delimiterLeft;
                    DelimiterRight  = $curTest.delimiterRight;
                }
            }
            It -Name "Test: <name>" -TestCases $tests {
                $template = $_.template
                $expected = $_.expected
                ConvertFrom-MustacheTemplate -template $template -Values $_.Values -Partials $_.Partials -DelimiterLeft $_.DelimiterLeft -DelimiterRight $_.DelimiterRight | Should -Be $expected
            }
        }
    }

    Context "<Name> (as PSObject with cached Template and Values from Pipeline)" -Foreach $areas {
        $tests = @()
        foreach ($curTest in (Get-Content $_.FileName | ConvertFrom-Json).tests) {
            if (!($curTest.data -is [System.Array]) -and ($null -ne $curTest.data.lambda)) {
                $curTest.data.lambda = [scriptblock]::Create($curTest.data.lambda.pwsh)
            }
            $tests += @{
                Name        = $curTest.name;
                Template    = $curTest.template;
                Expected    = $curTest.expected;
                Values      = $curTest.data;
                Partials    = $curTest.partials;
                DelimiterLeft   = $curTest.delimiterLeft;
                DelimiterRight  = $curTest.delimiterRight;
            }
        }
        It -Name "Test: <name>" -TestCases $tests {
            $template = $_.template
            $expected = $_.expected
            $cachedTemplate = Get-MustacheTemplate -template $template -DelimiterLeft $_.DelimiterLeft -DelimiterRight $_.DelimiterRight
            $_.Values | ConvertFrom-MustacheTemplate -Template $cachedTemplate -Partials $_.Partials | Should -Be $expected
        }
    }
}

Describe "Error Handling Tests" {
    Context "ConvertFrom-MustacheTemplate produces Write-Error for invalid lambda" {
        It "Should throw an exception via Write-Error when lambda is invalid and error action preference is Stop" {
            $template = 'Hello {{name}}!'
            $values = @{
                name = { throw 'Intentional lambda error' }
            }
            { ConvertFrom-MustacheTemplate -Template $template -Values $values -ErrorAction Stop } | Should -throw
        }

        It "Should continue when lambda is invalid and error action preference is SilentlyContinue" {
            $template = 'Hello {{name}}!'
            $values = @{
                name = { throw 'Intentional lambda error' }
            }
            ConvertFrom-MustacheTemplate -Template $template -Values $values -ErrorAction SilentlyContinue  | Should -Be 'Hello ERROR!'
        }
    }

    Context "ConvertFrom-MustacheTemplate parameter validation" {
        It "Should throw when template is null" {
            { ConvertFrom-MustacheTemplate -template $null -Values @{} } | Should -Throw
        }

        It "Should throw when template is empty string" {
            { ConvertFrom-MustacheTemplate -template '' -Values @{} } | Should -Throw
        }

        It "Should throw when Values is null" {
            { ConvertFrom-MustacheTemplate -template 'hello' -Values $null } | Should -Throw
        }
    }

    Context "ConvertFrom-MustacheTemplate pipeline input error handling" {
        It "Should handle pipeline input with valid data without error" {
            @{ name = 'World' } | ConvertFrom-MustacheTemplate -template 'Hello {{name}}!' | Should -Be 'Hello World!'
        }

        It "Should handle pipeline input with array values correctly" {
            $values = @(
                @{ name = 'Alice' },
                @{ name = 'Bob' }
            )
            $template = '{{#names}}{{name}}{{/names}}'
            $arrayValues = @{
                names = $values
            }
            $arrayValues | ConvertFrom-MustacheTemplate -template $template | Should -Be 'AliceBob'
        }
    }
}

AfterAll {
    Remove-Module PSMustache
    # Revert after Tests
    [cultureinfo]::CurrentCulture = $oldCulture
    [cultureinfo]::CurrentUICulture = $oldUICulture
}