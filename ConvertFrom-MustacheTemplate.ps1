#Requires -Version 5
enum MustacheTagType {
    Root
    Text
    Comment
    Interpolation
    Delimiter
    Partial
    SectionStart
    SectionEnd
    InvertedStart
}
class MustacheTag {
    [MustacheTag]$Parent = $null
    [MustacheTagType]$Type = [MustacheTagType]::Root
    [string]$Content = ''
    [array]$Childs = @()
    [bool]$Unescape = $false
}

class PSMustache {

    static [string]$DelimiterLeftDefault = '{{'
    static [string]$DelimiterRightDefault = '}}'
    static [string]$DelimiterLeftUnescapeDefault = '{'
    static [string]$DelimiterRightUnescapeDefault = '}'

    static [string]$regexTag = "\s*(?<Operator>[!>=#&^/])?\s*(?<TagContent>.+)"
    <#
        \s*                         # Whitespaces before Operator
        (?<Operator>[!>=#&^/])?     # Operator of Tag, if any
        \s*                         # Whitespaces after Operator
        (?<TagContent>.+)           # Tag-Content, normally Tag-Name (except comment-Tags)
    #>
    static [string] RenderTemplate([MustacheTag] $leaf, $valueStack, $partials) {
        $retValue = ''

        switch ($Leaf.Type) {
            Text { 
                $retValue = $Leaf.Content
                break
            }
            Interpolation {
                $retValue = [PSMustache]::GetValue($Leaf.Content, $ValueStack)
                if (-not $Leaf.Unescape) {
                    $retValue = [System.Web.HttpUtility]::HtmlEncode($retValue)
                }
                break
            }
            SectionStart {
                $sectionValue = [PSMustache]::GetValue($Leaf.Content, $ValueStack)
                
                if ($sectionValue -is [string]) {   # When string, check if the string is not empty, otherwise it is equal to false
                    if (-not [string]::IsNullOrEmpty($sectionValue)) {
                        $sectionValue = @($sectionValue)
                    } else {
                        $sectionValue = @()
                    }
                } elseif ($sectionValue -is [bool]) {   # When bool, check if it is true
                    if ($sectionValue) {
                        $sectionValue = @($sectionValue)
                    } else {
                        $sectionValue = @()
                    }
                }
                # Ensure it is an array, if not already
                if (-not ($sectionValue -is [array])) {
                    if ($null -ne $sectionValue) {
                        $sectionValue = @($sectionValue)
                    } else {
                        $sectionValue = @()
                    }
                }
                # Loop through each array variable
                foreach ($curVar in $sectionValue) {
                    # Attach each Child of the section template to the result set for each variable in the stack
                    foreach ($curChild in $Leaf.Childs) {
                        if ($curVar -is [array]) {  # Nested Arrays need to join as such
                            $retValue += [PSMustache]::RenderTemplate($curChild, @($curVar, $ValueStack), $partials)
                        } else {
                            $retValue += [PSMustache]::RenderTemplate($curChild, @($curVar) + $ValueStack, $partials)
                        } 
                    }
                }

                
            }
            InvertedStart {
                $sectionValue = [PSMustache]::GetValue($Leaf.Content, $ValueStack)
                if ($sectionValue -is [string]) {   # When string, check if the string is not empty, otherwise it is equal to false
                    $outputInverted = [string]::IsNullOrEmpty($sectionValue)
                } elseif ($sectionValue -is [bool]) {   # When bool, check if it is true
                    $outputInverted = -not $sectionValue
                } elseif ($sectionValue -is [array]) {
                    $outputInverted = $sectionValue.Length -eq 0
                } else {
                    $outputInverted = $null -eq $sectionValue
                }
                if ($outputInverted) {
                    foreach ($curChild in $Leaf.Childs) {
                        if ($sectionValue -is [array]) {  # Nested Arrays need to join as such
                            $retValue += [PSMustache]::RenderTemplate($curChild, @($sectionValue, $ValueStack), $partials)
                        } else {
                            $retValue += [PSMustache]::RenderTemplate($curChild, @($sectionValue) + $ValueStack, $partials)
                        } 
                    }
                }

            }
            Partial {
                $partial = $partials.($Leaf.Content.Trim())
                if (-not [string]::IsNullOrEmpty($partial)) {
                    if ($leaf.Childs.Length -gt 0) {    # Append intentation to every newline except the last one when ending with a newline
                        $partial = $partial -replace "(\n)(?!$)","`n$($leaf.Childs[0].Content)"
                    }
                    $tags = [PSMustache]::ParseTemplate($partial)
                    # Check if intendation Text Tag is appended
                    if ($leaf.Childs.Length -gt 0) {    # Prepend Intentation bevore the first element to preserve it
                        $tags.Childs = @($leaf.Childs[0]) + $tags.Childs
                    }
                    $retValue += [PSMustache]::RenderTemplate($tags, $ValueStack, $partials)
                }
            }
            Root {
                foreach ($curChild in $Leaf.Childs) {
                    $retValue += [PSMustache]::RenderTemplate($curChild, $ValueStack, $partials)
                }
            }
            Default {}
        }
        return $retValue
    }

    static [object] GetValue([string] $valueName, [array]$valueStack) {
        $valueName = $valueName.Trim()  # Remove Whitespaces from variable name

        if ($valueName -eq '.') {   # Return directly if dotted names
            if ($valueStack.Count -gt 1) {
                return $valueStack[0]
            }
            return $valueStack
        }

        # Loop through valueStack to find the value
        foreach ($curValue in $valueStack) {
            $curValueNamePart = $valueName.Split('.')
            # Lookup if first part of the name in in the current Stack position
            # If it matches, return the value down the dots, otherwise go stack up
            if (($curValue | Get-Member -MemberType NoteProperty | Where-Object Name -eq $curValueNamePart[0]).count -eq 1) {
                $curValueNamePart | ForEach-Object { $curValue = $curValue.$_ }
                return $curValue
            }
        }
        return $null
    }

    static [MustacheTag] ParseTemplate([string]$template) {
        # Evaluate newLine
        if ($Template -match "(?<newLine>\r?\n)") {
            $templateNewLine = $Matches['newLine']
        }
        else {
            $templateNewLine = $null
        }
        # Go with defaults
        return [PSMustache]::ParseTemplate($template, [PSMustache]::DelimiterLeftDefault, [PSMustache]::DelimiterRightDefault, [PSMustache]::DelimiterLeftUnescapeDefault, [PSMustache]::DelimiterRightUnescapeDefault, $templateNewLine)
    }
    static [MustacheTag] ParseTemplate([string]$template, [string]$delimiterLeft, [string]$delimiterRight, [string]$delimiterLeftUnescape, [string]$delimiterRightUnescape, [string]$templateNewLine) {
        $parseTree = [MustacheTag]@{
            Type = [MustacheTagType]::Root
        }

        $curParent = $parseTree

        $lastPosition = 0
        $openTagPosition = -1
        $closeTagPosition = 0
        while (($openTagPosition = $Template.IndexOf($delimiterLeft, $lastPosition)) -ge 0) {
            # Open Delimiter found, check if Unescape is used
            $isUnescapeByTriple = $openTagPosition -eq $Template.IndexOf($delimiterLeft + $delimiterLeftUnescape, $openTagPosition, ($delimiterLeft + $delimiterLeftUnescape).Length)
            if ($isUnescapeByTriple) {
                # Find Close Delimiter incl. Unescape-Delimiter
                $closeTagPosition = $Template.IndexOf($delimiterRight + $delimiterRightUnescape, $openTagPosition + $delimiterLeft.Length ) # Find Close Del, pos after Open Del
                # Get Content excl. Unescape-Delimiter
                $tagContent = $Template.Substring($openTagPosition + $delimiterLeft.Length + $delimiterLeftUnescape.Length, $closeTagPosition - $openTagPosition - $delimiterLeft.Length - $delimiterLeftUnescape.Length)
            }
            else {
                # Find Close Delimiter
                $closeTagPosition = $Template.IndexOf($delimiterRight, $openTagPosition + $delimiterLeft.Length) # Find Close Del, pos after Open Del
                $tagContent = $Template.Substring($openTagPosition + $delimiterLeft.Length, $closeTagPosition - $openTagPosition - $delimiterLeft.Length)
            }


            $tagContent -match [PSMustache]::regexTag | Out-Null
            $tagContentMatch = $Matches
            if (($null -eq $tagContentMatch['Operator']) -or ($tagContentMatch['Operator'] -eq '&')) {
                ## Interpolation

                # Text-Content before Tag, if any
                if ($openTagPosition - $lastPosition -gt 0) {
                    $curParent.Childs += [MustacheTag]@{
                        Parent  = $curParent
                        Type    = [MustacheTagType]::Text
                        Content = $Template.Substring($lastPosition, $openTagPosition - $lastPosition)
                    }
                }
                $curParent.Childs += [MustacheTag]@{
                    Parent   = $curParent
                    Type     = [MustacheTagType]::Interpolation
                    Content  = $tagContentMatch['TagContent']
                    Unescape = ($isUnescapeByTriple -or ($tagContentMatch['Operator'] -eq '&'))
                }
                # Set Position after closing Tag
                $lastPosition = $closeTagPosition + $delimiterRight.Length
                if ($isUnescapeByTriple) {
                    $lastPosition += $delimiterRightUnEscape.Length
                }
            }
            else {
                # On other Tags than Interpolation the complete Line should be removed if standalone in a line
                # Evaluate Position of previous and next Linebreak from perspective of captured Tag
                if (-not ([string]::IsNullOrEmpty($templateNewLine))) {
                    ## Variable previous LineBreak
                    # Pos. of previous Linebreak
                    $posPreviousLineBreak = $Template.LastIndexOf($templateNewLine, $openTagPosition)
                    # Pos of content beginning in current line
                    $posPreviousContentInLineBegin = -1
                    # Content in line before Opening Tag
                    $previousContentInLine = ''

                    ## Variables next linebreak
                    # Pos. of next LineBreak
                    $posNextLineBreak = $Template.IndexOf($templateNewLine, $closeTagPosition)
                    # Pos of content beginning after linebreak
                    $posNextLineBreakContentBegin = -1
                    # Content in line after Closing Tag
                    $nextContentInLine = ''

                    if ($posPreviousLineBreak -eq -1) {
                        # Begin of String, no previous newline
                        $posPreviousContentInLineBegin = 0
                    }
                    else {
                        # Content begin after the previous
                        $posPreviousContentInLineBegin = $posPreviousLineBreak + $templateNewLine.Length
                    }
                    $previousContentInLine = $Template.Substring($posPreviousContentInLineBegin, $openTagPosition - $posPreviousContentInLineBegin)

                    # Pos. of next Linebreak
                    if ($posNextLineBreak -eq -1) {
                        # No upcoming linebreak
                        $nextContentInLine = $Template.Substring($closeTagPosition + $delimiterRight.Length)
                    }
                    else {
                        $posNextLineBreakContentBegin = $posNextLineBreak + $templateNewLine.Length # Content begin after linebreak
                        $nextContentInLine = $Template.Substring($closeTagPosition + $delimiterRight.Length, ($posNextLineBreak - ($closeTagPosition + $delimiterRight.Length))) # Get Content till linebreak, but not including
                    }
                    # Join previous and trailing content in line to check if it constists only out of whitespaces
                    $isWhiteSpaceLine = ($previousContentInLine + $nextContentInLine) -match "^\s*$"
                    if ($isWhiteSpaceLine) {
                        $curParent.Childs += [MustacheTag]@{
                            Parent  = $curParent
                            Type    = [MustacheTagType]::Text
                            Content = $Template.Substring($lastPosition, $posPreviousContentInLineBegin - $lastPosition)
                        }
                        if ($posNextLineBreakContentBegin -eq -1) {
                            # Last line is a whitespace line, set lastPos to end of Template
                            $lastPosition = $Template.Length
                        }
                        else {
                            # Set LastPos to begin of Content after LineBreak
                            $lastPosition = $posNextLineBreakContentBegin
                        }
                    }
                }
                else {
                    $isWhiteSpaceLine = $false  # No Whitespace line, since single line
                    $previousContentInLine = '' # Used for partial tag
                }
                # If whitespace-Line, add the Text of the previous line until the previous LineBreak and set position after newline of current line
                if (-not $isWhiteSpaceLine) {
                    # No whitespace-Line, add content until opening tag and set lastpos after closing Tag
                    if ($openTagPosition - $lastPosition -gt 0) {
                        $curParent.Childs += [MustacheTag]@{
                            Parent  = $curParent
                            Type    = [MustacheTagType]::Text
                            Content = $Template.Substring($lastPosition, $openTagPosition - $lastPosition)
                        }
                    }
                    # Set Position after closing Tag
                    $lastPosition = $closeTagPosition + $delimiterRight.Length
                }
                # Add Tag itself
                switch ($tagContentMatch['Operator']) {
                    '!' {
                        # Comment
                        $curParent.Childs += [MustacheTag]@{
                            Parent  = $curParent
                            Type    = [MustacheTagType]::Comment
                            Content = $tagContent
                        }
                        break
                    }
                    '#' {
                        # Section start
                        $curParent.Childs += [MustacheTag]@{
                            Parent  = $curParent
                            Type    = [MustacheTagType]::SectionStart
                            Content = $tagContentMatch['TagContent']
                        }
                        # Set new Parent
                        $curParent = $curParent.Childs[$curParent.Childs.Length - 1]
                        break
                    }
                    '^' {
                        # Inverted start
                        $curParent.Childs += [MustacheTag]@{
                            Parent  = $curParent
                            Type    = [MustacheTagType]::InvertedStart
                            Content = $tagContentMatch['TagContent']
                        }
                        # Set new Parent
                        $curParent = $curParent.Childs[$curParent.Childs.Length - 1]
                        break
                    }
                    '/' {
                        # Section or inverted end
                        $curParent.Childs += [MustacheTag]@{
                            Parent  = $curParent
                            Type    = [MustacheTagType]::SectionEnd
                            Content = $tagContentMatch['TagContent']
                        }
                        # Revert Parent
                        $curParent = $curParent.Parent
                        break
                    }
                    '>' {
                        # Partials
                        $newPartial = [MustacheTag]@{
                            Parent  = $curParent
                            Type    = [MustacheTagType]::Partial
                            Content = $tagContentMatch['TagContent']
                        }
                        if ($isWhiteSpaceLine -and $previousContentInLine -match "(\s+)") { 
                            # Check if we have intended before the partial tag
                            $newPartial.Childs += [MustacheTag]@{
                                Parent  = $newPartial
                                Type    = [MustacheTagType]::Text
                                Content = $previousContentInLine
                            }
                        }
                        $curParent.Childs += $newPartial
                        break
                    }
                    '=' {
                        # Delimiters
                        if ($tagContentMatch['TagContent'] -match "^(?<delLeft>\S+)\s+(?<delRight>\S+)\s*=$") {
                            $delimiterLeft = $Matches['delLeft']
                            $delimiterRight = $Matches['delRight']
                            $curParent.Childs += [MustacheTag]@{
                                Parent  = $curParent
                                Type    = [MustacheTagType]::Delimiter
                                Content = $tagContentMatch['TagContent']
                            }
                        }
                    }
                }
            }
        }
        # Add trailing text
        if ($lastPosition -lt $template.Length) {
            $curParent.Childs += [MustacheTag]@{
                Parent  = $curParent
                Type    = [MustacheTagType]::Text
                Content = $Template.Substring($lastPosition)
            }
        }
        return $parseTree
    }
}
<#
.SYNOPSIS
Parses a Mustache-Template, renders it with the given values and returns the result 

.DESCRIPTION
PSMustache supports all mustache Tags excepts lambas.
Please refer to the official mustache documentation for more examples and details regarding the syntax.

Tag Reference in short:
- Interpolations: {{firstname}} is replaced by a value with name 'firstname'
- Sections: {{#persons}}Hi {{firstname}}! {{/persons}} is looped vor every member of the array 'persons'
- Inverteds: {{^persons}}No persons here.{{/persons}} is only rendered when a value with the name 'persons' does not exists or is empty
- Comments: {{! This is a comment }} will be removed
- Partials: {{> mypartial }} is replaced with the content of a partial with the name 'mypartial'
- Delimiters: {{=<% %>=}} set new delimiters which are used beyond that tag.

Details of the processing:
- Whitespaces in the tags are mostly ignored so {{ # persons    }} and {{#persons}} are equal.
- All Tags except interpolation are completely removed when placed in a standalone line with only whitespaces.
- When partials are intended, the intentation is applied to each linebreak in the partial to preserve the intentation.
- {{.}} Can be used as a shortcut for the current element in a section
- All content is HTML-Encoded, when not excluded by triple Delimiter {{{rawContent}}} or the ampersand {{& rawContent}}
- If the delimiters are changed to a two length variant with identical chars, the Unescape-Delimiter will also be changed
  e.g. {{=[[ ]]=}} changes the delimiters to [[content]] and [[[rawContent]]] for unescaped Content

.PARAMETER Template
A Mustache Template as string

.PARAMETER Values
All values which shall be used while rendering the template.
Values should be defined as hashtables and can include nested elements e.g.
@{
    'Name' = 'Joe',
    'Repos' = @('Repo1', 'Repo2', 'Repo3')
}

.PARAMETER Partials
Partials should be defined as hashtable, e.g. @{'myPartial' = 'Hi {{name}}'}

.EXAMPLE
An example

#>
function ConvertFrom-MustacheTemplate {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Template,
        [Parameter(Mandatory = $false)]
        $Values,
        [Parameter(Mandatory = $false)]
        [array]
        $Partials        
    )
    process {
        $parseTree = [PSMustache]::ParseTemplate($Template)
       return [PSMustache]::RenderTemplate($parseTree, $Values, $Partials)
    }
}