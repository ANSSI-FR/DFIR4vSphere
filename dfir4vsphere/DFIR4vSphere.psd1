#
# Module manifest for module 'DevFIROps'
#

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\DFIR4vSphere.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# Supported PSEditions
CompatiblePSEditions = 'Desktop'

# ID used to uniquely identify this module
GUID = '5a74413e-6a91-4668-bc19-58b37cd7cc71'

# Author of this module
Author = 'leonard.savina@ssi.gouv.fr'

# Company or vendor of this module
CompanyName = 'CERT-FR'

# Description of the functionality provided by this module
Description = 'The DFIR4vSphere module aims to help the DFIR analyst in VMWare vSphere investigations'


# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'



# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
    @{ModuleName = 'VMware.VimAutomation.Core'; ModuleVersion = '12.0.0.15947286'}
    )



# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess

NestedModules = @(
    'Start-VC_Investigation.ps1',
    'Start-ESXi_Investigation.ps1'
 
)

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport =  'Write-Log', 'Test-VCconnection', 'Get-VIEventPlus', 'Start-VC_Investigation', 'Start-ESXi_Investigation'
# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()


# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("VMWare", "ESXi", "Vcenter", "Forensics","DFIR","vSphere","ESX")


        # ReleaseNotes of this module
        ReleaseNotes ='
        1.0.0 - Initial release
         '


    } # End of PSData hashtable

} # End of PrivateData hashtable



}
