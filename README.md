# PSMustache

PSMustache is an implementation of the [Mustache](https://mustache.github.io/) template system purely in PowerShell without any external dependencies. It requires at least PowerShell 5.1 and runs great in later Versions.
PSMustache currently passes all Spec-Tests up to the current [Mustache-Spec-Release 1.2.1.](https://github.com/mustache/spec), except the Parent-Tags.

In Reference to [mustache.js](https://github.com/janl/mustache.js):

Mustache is a logic-less template syntax. It can be used for HTML, config files, source code - anything. It works by expanding tags in a template using values provided in a hashtables, PSCustomObjects or even mixed.

We call it "logic-less" because there are no if statements, else clauses, or for loops. Instead there are only tags. Some tags are replaced with a value, some nothing, and others a series of values.

For a list of implementations and tips, see http://mustache.github.io/.

## Installation

The prefered way is to install the latest published version for PowershellGallary via
~~~PowerShell
Install-Module -Name PSMustache
~~~

Alternatively you can just clone this repo or download a release and import the Module via
~~~PowerShell
Import-Module .\PSMustache.psd1
~~~

## Usage

PSMustache has only one single but very powerfull CMDlet ```ConvertFrom-MustacheTemplate``` with the following parameters:
* ```-Template``` takes the Mustache-Template as a string. In more complex scenarios you'll usually get the template from e.g. a file
* ```-Values``` are the data as a hashtable or PSCustomObject. You can have as many nested levels as needed.
* ```-Partials``` You can think of partials as named subtemplates or includes. 

For a complete language-agnostic overview you can also refer to [mustache(5)](http://mustache.github.io/mustache.5.html)


### Interpolation
```{{Variable}}``` Interpolation with simple variables. 
~~~PowerShell
PS> ConvertFrom-MustacheTemplate -Template 'Hi {{Name}}!' -Values @{Name='Joe'}

Hi Joe
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

### Sections & Inverts
```{{#SectionName}}``` Sections are used to iterate through arrays when they are not empty. They must be  closed with the closing Tag ```{{/SectionName}}```. When a section is iterated, the current element can be accessed by the name or, if it containts only one element, through the dot-operator.

When you want to output something when an element is NOT found or is empty, you can use inverted sections. ```{{^SectionName}}``` which must also be closed with a closing Tag ```{{/SectionName}}```


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

### Comments
```{{! This is a comment}}``` Comment-Tags are just completely removed from the template. When they are the only content in a line, the whole line is removed

~~~PowerShell
PS> ConvertFrom-MustacheTemplate -Template 'Hi {{Name}}{{! This is a comment}}! ' -Values @{Name='Joe'}

Hi Joe
~~~

