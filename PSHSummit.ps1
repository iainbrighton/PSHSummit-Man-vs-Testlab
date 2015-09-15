
Push-Location '~\OneDrive\Documents\PSHSummit\Man vs Test Lab'
Import-Module VirtualEngineLab -Force
Get-Command -Module VirtualEngineLab
Get-LabHostDefaults
Set-LabHostDefaults -ConfigurationPath D:\TestLab\Configurations -DifferencingVhdPath 'D:\TestLab\VM Disks' -HotfixPath D:\TestLab\Hotfixes -IsoPath D:\TestLab\ISOs -ParentVhdPath 'D:\TestLab\Parent Disks' -ResourcePath D:\TestLab\Resources;

<#
    Test host configuration and start configuration if necessary (Start-LabConfiguration calls Test-LabConfiguration anyway!) #>
Test-LabHostConfiguration -Verbose
Start-LabHostConfiguration -Verbose

<#
    Import configuration into session and generate the MOFs #>
. .\TLGBaseConfiguration.ps1
TLGBaseConfiguration -OutputPath D:\TestLab\Configurations -ConfigurationData .\TLGVirtualEngineLab.psd1

<#
    Set the lab VM defaults, create the lab and start the VMs #>
Get-LabVMDefaults
Set-LabVMDefaults -SystemLocale en-GB -InputLocale 0809:00000809 -UserLocale en-GB -RegisteredOrganization 'Virtual Engine' -StartupMemory 1.5GB
Start-LabConfiguration -ConfigurationData .\TLGVirtualEngineLab.psd1 -Path D:\TestLab\Configurations -Verbose;

## ADD ADDITIONAL NIC
Add-VMNetworkAdapter -VMName EDGE1 -SwitchName Internet

<# Start Lab #>
Start-Lab -ConfigurationData .\TLGVirtualEngineLab.psd1 -Verbose

<#
    List available 'included' media #>
Get-LabMedia | Select Id, Description, Filename

<#
    List (currently) configured images #>
Get-LabImage | Select Id, ImagePath

<# Stop Lab #>
Stop-Lab -ConfigurationData .\TLGVirtualEngineLab.psd1 -Verbose




<# Reset lab #>
Import-Module VirtualEngineLab -Force
Remove-LabConfiguration -ConfigurationData ~\Documents\TLGVirtualEngineLab.psd1 -RemoveSwitch -Verbose
Remove-Item -Path $env:ALLUSERSPROFILE\VirtualEngineLab -Force -Recurse
