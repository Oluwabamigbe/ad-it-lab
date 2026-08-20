Import-Module ActiveDirectory

$reportFolder = "C:\Scripts\Reports"

# Create the reports folder if it does not exist
if (-not (Test-Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder | Out-Null
}

# Create a timestamp so old reports are not overwritten
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$reportPath = "$reportFolder\AD-User-Audit-$timestamp.csv"

Write-Host "Generating Active Directory user audit..."

$users = Get-ADUser -Filter * `
    -Properties Department, Enabled, LastLogonDate, PasswordLastSet, WhenCreated

$report = foreach ($user in $users) {

    # Get user's AD group memberships
    $groups = Get-ADPrincipalGroupMembership -Identity $user |
        Select-Object -ExpandProperty Name

    [PSCustomObject]@{
        Name              = $user.Name
        Username          = $user.SamAccountName
        Enabled           = $user.Enabled
        Department        = $user.Department
        LastLogon         = $user.LastLogonDate
        PasswordLastSet   = $user.PasswordLastSet
        AccountCreated    = $user.WhenCreated
        Groups            = ($groups -join "; ")
        DistinguishedName = $user.DistinguishedName
    }
}

$report |
    Sort-Object Department, Name |
    Export-Csv -Path $reportPath -NoTypeInformation

Write-Host ""
Write-Host "Audit complete."
Write-Host "Report saved to:"
Write-Host $reportPath