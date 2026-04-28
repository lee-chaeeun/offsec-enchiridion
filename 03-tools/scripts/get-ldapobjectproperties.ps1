function Get-LDAPObjectProperties {
    param (
        [string]$ObjectName
    )

    $PDC = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner.Name
    $DistinguishedName = ([adsi]'').distinguishedName

    $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$PDC/$DistinguishedName")
    $DirectorySearcher = New-Object System.DirectoryServices.DirectorySearcher($DirectoryEntry)

    $DirectorySearcher.Filter = "(name=$ObjectName)"

    $Results = $DirectorySearcher.FindAll()

    foreach ($Result in $Results) {
        foreach ($Property in $Result.Properties.PropertyNames) {
            Write-Host "$Property : $($Result.Properties[$Property])"
        }

        Write-Host "-------------------------------"
    }
}
