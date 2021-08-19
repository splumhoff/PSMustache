BeforeAll {
    Import-Module .\PSMustache.psd1

    # Tests are written for en-US-Formatting.
    $oldCulture = [cultureinfo]::CurrentCulture
    $oldUICulture = [cultureinfo]::CurrentUICulture
    [cultureinfo]::CurrentCulture = 'en-US'
    [cultureinfo]::CurrentUICulture = 'en-US'
}

Describe "Mustache Tests from GIT " {
    $areas = @(
        @{Name = "Comments";        FileName = Join-Path $PSScriptRoot '.\spec\specs\comments.json' }
        @{Name = "Interpolation";   FileName = Join-Path $PSScriptRoot '.\spec\specs\interpolation.json'}
        @{Name = "Sections";        FileName = Join-Path $PSScriptRoot '.\spec\specs\sections.json'}
        @{Name = "Inverted";        FileName = Join-Path $PSScriptRoot '.\spec\specs\inverted.json'}
        @{Name = "Partials";        FileName = Join-Path $PSScriptRoot '.\spec\specs\partials.json'}
        @{Name = "Delimiters";      FileName = Join-Path $PSScriptRoot '.\spec\specs\delimiters.json'}
        @{Name = "Lambdas";         FileName = Join-Path $PSScriptRoot '.\spec\specs\~lambdas.json'}
    )

    Context "<Name> (as PSObject)" -Foreach $areas {
        $tests = @()
        foreach ($curTest in (Get-Content $_.FileName | ConvertFrom-Json).tests) {
            if ($null -ne $curTest.data.lambda) {
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
                if ($null -ne $curTest.data.lambda) {
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
            if ($null -ne $curTest.data.lambda) {
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
            $cachedTemplate = Get-MustacheTemplate -template $template
            $_.Values | ConvertFrom-MustacheTemplate -Template $cachedTemplate -Partials $_.Partials | Should -Be $expected
        }
    }
}

AfterAll {
    Remove-Module PSMustache
    # Revert after Tests
    [cultureinfo]::CurrentCulture = $oldCulture
    [cultureinfo]::CurrentUICulture = $oldUICulture
}