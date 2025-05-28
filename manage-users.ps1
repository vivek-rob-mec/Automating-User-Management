# Reads the users.csv file
$users = Import-Csv -Path "D:\DevOps_HandsOn\Automating User Management\Users.csv"

$logFile = "D:\DevOps_HandsOn\Automating User Management\users_management_log.txt"
# will generate users_management_log.txt file

# Function to log action
function Log-Action {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logMessage
    
}

# Reiterate through each user in the present in the file
foreach ($user in $users){
    $username = $user.Username
    $password = $user.Password
    $role = $user.Role

    $existingUser = Get-LocalUser -Name $username -ErrorAction SilentlyContinue

    if($existingUser){
        Log-Action "User '$username' exists. Updating the account"

        Set-LocalUser -Name $username -Password (ConvertTo-SecureString -AsPlainText $password -Force)

        #check if a particular user is a part of Administrator or not
        $groupMembers = Get-LocalGroupMember -Group 'Administrators'

        if ($role -eq 'Administrators'){
            if (-not ($groupMembers | Where-Object { $_.Name -eq $username })){
                Add-LocalGroupMember -Group "Administrators" -Member $username
                Log-Action "The username '$username' is added to the Administrator group."
            }else {
                Log-Action "The username '$username' is already member of Administrator group."
            }
        }elseif ($role -eq 'Standard User') {
            if ($groupMembers | Where-Object { $_.Name -eq $username }) {
                Remove-LocalGroupMember -Group "Administrators" -Member $username
                Log-Action "Removed '$username' from the Administrator group."
            }else {
                Log-Action "'$username' is not a member of Administrator group."
            }
        } 
    }else {
        Log-Action "Creating a new user '$username'"
        
        # Creating New User
        New-LocalUser -Name $username -Password (ConvertTo-SecureString -AsPlainText $password -Force) -FullName $username -Description "Created the new user in your system"
        Log-Action "User '$username' Created Successfully"

        # Assigning the role to user
        if ($role -eq 'Administrators'){
            Add-LocalGroupMember -Group "Administrators" -Member $username
            Log-Action "Added '$username' to the 'Administrators' group"
        }elseif ($role -eq 'Standard User') {
            Add-LocalGroupMember -Group "Users" -Member $username
            Log-Action "Added '$username' to the 'Users' group"
        }

        # Create a home directory and set permissiion for the user
        $homeDir = "C:\Users\$username"
        if (-not (Test-Path -Path $homeDir)){
            New-Item -Path $homeDir -ItemType Directory
            Log-Action "Created home directory for user: '$username' at '$homeDir'."
        }

        # Setting up the permission
        $acl = Get-Acl -Path $homeDir
        $fqUser = "$env:COMPUTERNAME\$username"
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($fqUser,"FullControl","Allow")
        $acl.AddAccessRule($accessRule)
        Set-Acl -Path $homeDir -AclObject $acl
        Log-Action "Set full control permissions for '$username' on their home directory."
    }
}