# PSMustache

PSMustache is an implementation of the [Mustache](https://mustache.github.io/) template system written in PowerShell with no external dependencies. It requires PowerShell 5.1 or later (including PowerShell 7+) and runs on Windows, macOS, and Linux.

PSMustache passes the Mustache spec tests up to v1.4.3 ([Mustache-Spec-Release](https://github.com/mustache/spec)). Note: Parent-tags are not supported.

In reference to [mustache.js](https://github.com/janl/mustache.js):

Mustache is a logic-less template syntax. It can be used for HTML, configuration files, source code — anything. It works by expanding tags in a template using values provided in hashtables, PSCustomObjects, or mixed data structures.

We call it "logic-less" because there are no if statements, else clauses, or for loops. Instead there are only tags: some tags are replaced with a value, some with nothing, and others with a series of values.

For a language-agnostic overview see http://mustache.github.io/.

[![codecov](https://codecov.io/gh/splumhoff/PSMustache/graph/badge.svg?token=C4DFTPKQP7)](https://codecov.io/gh/splumhoff/PSMustache)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/PSMustache?style=flat&link=https%3A%2F%2Fwww.powershellgallery.com%2Fpackages%2FPSMustache)](https://www.powershellgallery.com/packages/PSMustache)
[![Spectra Assure Community Badge](https://secure.software/psgallery/badge/psmustache)](https://secure.software/psgallery/packages/psmustache)

## Installation

The preferred way is to install the latest released version from the PowerShell Gallery:

~~~PowerShell
Install-Module -Name PSMustache
~~~

Alternatively, clone this repository or download a release and import the module locally:

~~~PowerShell
Import-Module .\PSMustache.psd1
~~~

## Usage

PSMustache exposes a primary cmdlet, `ConvertFrom-MustacheTemplate`, with the most common parameters:
- `-Template`: the Mustache template as a string. For larger templates you will typically load the template from a file.
- `-Values`: the data to render, provided as a hashtable or `PSCustomObject`. Nested structures and arrays are supported.

Optional parameters:
- `-Partials`: a hashtable of named partial templates (includes)
- `-DelimiterLeft`: set a different opening delimiter when `{{` is already used in your content
- `-DelimiterRight`: set a different closing delimiter when `}}` is already used in your content

If you provide custom delimiters, set both `-DelimiterLeft` and `-DelimiterRight` together.

For a complete language-agnostic overview you can also refer to [Mustache(5)](http://mustache.github.io/mustache.5.html)

### Additional Cmdlet

PSMustache also provides `Get-MustacheTemplate` for pre-parsing templates. This is useful when rendering the same template multiple times with different values and can improve performance when reusing a template.

~~~PowerShell
$template = Get-MustacheTemplate 'Hi {{Name}}!'
$values | ForEach-Object { ConvertFrom-MustacheTemplate -Template $template -Values $_ }
~~~


### Interpolation
```{{Variable}}``` — Interpolation with simple variables:

~~~PowerShell
PS> ConvertFrom-MustacheTemplate -Template 'Hi {{Name}}!' -Values @{Name='Joe'}

Hi Joe!
~~~

```{{Variable}}``` Interpolation with different delimiters. 
~~~PowerShell
PS> ConvertFrom-MustacheTemplate -Template 'Hi [[Name]], {{keepThisUntouched}}!' -Values @{Name='Joe'} -DelimiterLeft '[[' -DelimiterRight ']]'

Hi Joe, {{keepThisUntouched}}!
~~~

Interpolation with nested hashtables
~~~PowerShell
PS> $values = @{
    person = @{
        name = 'Joe'
        country = 'Germany'
    }
}
PS> ConvertFrom-MustacheTemplate -Template 'Hi {{person.name}} from {{person.country}}!' -Values $values

Hi Joe from Germany!
~~~

### Unescaped Interpolation
By default Mustache escapes HTML-sensitive characters. To render unescaped content use triple mustaches or the ampersand form:

~~~PowerShell
PS> ConvertFrom-MustacheTemplate -Template 'Raw: {{{Html}}}' -Values @{Html='<b>bold</b>'}

Raw: <b>bold</b>
~~~

This renders the `Html` value without HTML escaping.

### Lambdas
PSMustache supports Mustache lambdas as PowerShell scriptblocks. Lambdas can be used for computed values or simple templating helpers.

Variable lambda example:

~~~PowerShell
PS> $values = @{ name = { 'Joe'.ToUpper() } }
PS> ConvertFrom-MustacheTemplate -Template 'Hello {{name}}!' -Values $values

Hello JOE!
~~~

Section lambda example:

~~~PowerShell
PS> $values = @{ bold = { param($text) "<b>$text</b>" } }
PS> ConvertFrom-MustacheTemplate -Template 'This is {{#bold}}important{{/bold}}.' -Values $values

This is <b>important</b>.
~~~

The section lambda receives the raw inner content and can return a transformed string that is parsed and rendered by PSMustache.

### Sections & Inverted Sections

`{{#SectionName}}` Sections are used to iterate through arrays when they are not empty. They must be closed with the closing tag `{{/SectionName}}`. When a section is iterated, the current element can be accessed by its name or, if it contains only one element, through the dot-operator `{{.}}`.

When you want to output something when an element is NOT found or is empty, you can use inverted sections. `{{^SectionName}}` which must also be closed with a closing tag `{{/SectionName}}`.


~~~PowerShell
PS> $values = @{
    persons = @(
        @{
            name = 'Joe'
            Repos = @('FirstRepo', 'SecondRepo')
        },
        @{
            name = 'James'
        }
    )
}
PS> $template = @"
Known Repo List
----------------
{{#persons}}
 * {{Name}}:
 {{#repos}}
   + {{.}}
 {{/repos}}
 {{^repos}}
   - No repos
 {{/repos}}
{{/persons}}
"@
PS> ConvertFrom-MustacheTemplate -Template $template -Values $values

Known Repo List
----------------
 * Joe:
   + FirstRepo
   + SecondRepo
 * James:
   - No repos
~~~

### Partials
Partials are named sub-templates that you can provide via the `-Partials` parameter. For example:

~~~PowerShell
$template = 'Header:\n{{>header}}\nBody: {{body}}'
$partials = @{ header = 'Site Header - {{title}}' }
ConvertFrom-MustacheTemplate -Template $template -Values @{title='My Site'; body='Hello'} -Partials $partials
~~~

This will render the `header` partial in place of `{{>header}}`.

### Advanced Partials
Partials are rendered against the current context and may be nested. This is useful for layouts, repeating item templates, and preserving indentation.

~~~PowerShell
$template = @"
{{>header}}
{{#items}}
  {{>item}}
{{/items}}
{{>footer}}
"@

$partials = @{
  header = 'Report: {{title}}'
  item   = " - {{name}`n"
  footer = 'Total: {{count}} items'
}

$values = @{ title = 'Tasks'; count = 2; items = @(@{name='Build'}, @{name='Test'}) }

ConvertFrom-MustacheTemplate -Template $template -Values $values -Partials $partials
~~~

With this example, each `item` partial is rendered for the current item context inside the `items` section.

Standalone partials also preserve indentation when the partial content spans multiple lines.

### Dynamic Partials
Dynamic partials let you choose which partial to include at runtime using a value from the current context. Use the `{{>*partialName}}` syntax, where the value of `partialName` resolves to the name of the partial in the `-Partials` hashtable.

~~~PowerShell
PS> $template = 'Message: {{>*partialName}}'
PS> $values = @{partialName = 'myPartial'; Name = 'World'}
PS> $partials = @{myPartial = 'Hello {{Name}}!'}
PS> ConvertFrom-MustacheTemplate -Template $template -Values $values -Partials $partials
Message: Hello World!
~~~

This is useful for templates that need to select a partial dynamically based on values or application state.

### Custom Delimiters
You can change delimiters when your content uses `{{`/`}}`. Example shown above; set `-DelimiterLeft` and `-DelimiterRight` together.

### Using files and `Get-MustacheTemplate`
Load templates from files when working with larger templates:

~~~PowerShell
$template = Get-MustacheTemplate (Get-Content -Raw -Path 'templates/mytemplate.mustache')
ConvertFrom-MustacheTemplate -Template $template -Values (Get-Content values.json | ConvertFrom-Json)
~~~

### Comments
```{{! This is a comment}}``` Comment-Tags are just completely removed from the template. When they are the only content in a line, the whole line is removed

~~~PowerShell
PS> ConvertFrom-MustacheTemplate -Template 'Hi {{Name}}{{! This is a comment}}! ' -Values @{Name='Joe'}

Hi Joe
~~~

### License
This project is licensed under the terms of the [MIT license](LICENSE.md).

### Supported platforms
PSMustache requires PowerShell 5.1 or later; it runs on Windows and on PowerShell Core (7+) for macOS and Linux.

### Contributing & Running Tests
- Contributions are welcome. Please open issues or pull requests against this repository.

### Known limitations
- Parent-tags from the Mustache spec are not supported.
