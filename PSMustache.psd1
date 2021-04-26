#
# Module manifest for module 'PSMustache'
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSMustache.psm1'

# Version number of this module.
ModuleVersion = '1.2'

# Supported PSEditions
CompatiblePSEditions = @('Desktop','Core')

# ID used to uniquely identify this module
GUID = '3abbeb5e-4f15-4096-804c-838473285516'

# Author of this module
Author = 'Sascha Plumhoff'

# Copyright statement for this module
Copyright = '2021 Sascha Plumhoff'

# Description of the functionality provided by this module
Description = 'PSMustache is an implementation of the Mustache template system purely in PowerShell without any external dependencies.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
#FunctionsToExport = @('ConvertFrom-MustacheTemplate')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @('ConvertFrom-MustacheTemplate')

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'PowerShell', 'Template', 'Mustache', 'PSEdition_Core', 'PSEdition_Desktop', 'Windows', 'Linux', 'MacOS'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/splumhoff/PSMustache/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/splumhoff/PSMustache'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'See https://github.com/splumhoff/PSMustache for Release Notes'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

}

