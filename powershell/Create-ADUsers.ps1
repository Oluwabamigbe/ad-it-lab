Import-Module ActiveDirectory

$users = Import-Csv "C:\Scripts\employees.csv"

# Match CSV department names to your actual AD group names
$groupMap = @{
    "IT"      = "IT-Staff"
    "HR"      = "HR-Staff"
    "Finance" = "Finance-Staff"
}

# Ask for the temporary password instead of storing it in the script
$defaultPassword = Read-Host "Enter temporary password for new users" -AsSecureString

foreach ($user in $users) {

    $firstName  = $user.FirstName
    $lastName   = $user.LastName
    $department = $user.Department

    # Example: James Carter -> jcarter
    $username = ($firstName.Substring(0,1) + $lastName).ToLower()

    $ouPath = "OU=$department,DC=mydomain,DC=local"

    # Avoid accidentally creating the same account twice
    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$username'"

    if ($existingUser) {	
        Write-Host "$username already exists. Skipping."
        continue
    }

    Write-Host "Creating $firstName $lastName ($username)..."

    New-ADUser `
        -Name "$firstName $lastName" `
        -GivenName $firstName `
        -Surname $lastName `
        -SamAccountName $username `
        -UserPrincipalName "$username@mydomain.local" `
        -Department $department `
        -Path $ouPath `
        -AccountPassword $defaultPassword `
        -Enabled $true `
        -ChangePasswordAtLogon $true

    # Add employee to their department group
    Add-ADGroupMember `
        -Identity $groupMap[$department] `
        -Members $username

    # Every employee also joins the company-wide group
    Add-ADGroupMember `
        -Identity "All-Employees" `
        -Members $username

    Write-Host "$username created successfully."
}