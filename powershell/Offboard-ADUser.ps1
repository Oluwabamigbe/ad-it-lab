Import-Module ActiveDirectory

$username = Read-Host "Enter username to offboard"

# Find the user
$user = Get-ADUser -Filter "SamAccountName -eq '$username'" -Properties Department

if (-not $user) {
    Write-Host "User '$username' was not found."
    exit
}

Write-Host "Found user: $($user.Name)"
Write-Host "Department: $($user.Department)"

# Create Disabled Users OU if it does not already exist
$disabledOU = "OU=Disabled Users,DC=mydomain,DC=local"

$ouExists = Get-ADOrganizationalUnit `
    -Filter "Name -eq 'Disabled Users'" `
    -ErrorAction SilentlyContinue

if (-not $ouExists) {
    New-ADOrganizationalUnit `
        -Name "Disabled Users" `
        -Path "DC=mydomain,DC=local"

    Write-Host "Created Disabled Users OU."
}

# Disable the account
Disable-ADAccount -Identity $user

Write-Host "$username has been disabled."

# Groups we want to remove during offboarding
$companyGroups = @(
    "IT-Staff",
    "HR-Staff",
    "Finance-Staff",
    "All-Employees"
)

foreach ($group in $companyGroups) {

    $isMember = Get-ADGroupMember -Identity $group |
        Where-Object { $_.SamAccountName -eq $username }

    if ($isMember) {

        Remove-ADGroupMember `
            -Identity $group `
            -Members $user `
            -Confirm:$false

        Write-Host "Removed $username from $group"
    }
}

# Move account into Disabled Users OU
Move-ADObject `
    -Identity $user.DistinguishedName `
    -TargetPath $disabledOU

Write-Host "$username moved to Disabled Users OU."

# Record the action
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

"$timestamp - Offboarded $username ($($user.Name))" |
    Out-File "C:\Scripts\offboarding.log" -Append

Write-Host ""
Write-Host "Offboarding completed successfully."