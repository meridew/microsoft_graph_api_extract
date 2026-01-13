@{
    # Script module file associated with this manifest
    RootModule        = 'ExtractGraphApiData.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author            = 'Daniel Meridew'

    # Company or vendor of this module
    CompanyName       = 'MERIDEW LTD'

    # Description of the functionality provided by this module
    Description       = 'PowerShell module for extracting Microsoft Graph API metadata and Intune configuration data.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(
        'Microsoft.Graph.Authentication'
    )

    # Functions to export from this module
    FunctionsToExport = @(
        'Get-GraphApiMetaData'
        'Get-GraphApiEndpoint'
        'Invoke-GraphApiQuery'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module for discoverability
            Tags       = @('Graph', 'API', 'Intune', 'Microsoft365')

            # A URL to the license for this module
            LicenseUri = ''

            # A URL to the main website for this project
            ProjectUri = ''

            # Release notes for this module
            ReleaseNotes = 'Initial release'
        }
    }
}
