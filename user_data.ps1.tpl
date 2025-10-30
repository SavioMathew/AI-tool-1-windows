```powershell
#cloud-config
<powershell>

# Variables passed by template: windows_username, windows_password

# Create local user
$newUser = "${windows_username}"
$passwordPlain = "${windows_password}"

# Convert plain password to secure string
$securePass = ConvertTo-SecureString -String $passwordPlain -AsPlainText -Force

# Create local user if it doesn't exist
if (-not (Get-LocalUser -Name $newUser -ErrorAction SilentlyContinue)) {
    Write-Output "Creating local user $newUser"
    New-LocalUser -Name $newUser -Password $securePass -PasswordNeverExpires:$true -UserMayNotChangePassword:$false -AccountNeverExpires:$true
} else {
    Write-Output "User $newUser already exists. Setting password."
    $u = Get-LocalUser -Name $newUser
    $u | Set-LocalUser -Password $securePass
}

# Optionally, add to 'Users' group; do NOT add to Administrators by default.
Add-LocalGroupMember -Group "Users" -Member $newUser -ErrorAction SilentlyContinue

# Create a folder to set ACLs on
$folderPath = "C:\app"
if (-not (Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory | Out-Null
}

# Map POSIX 775 to NTFS:
# - Owner (the new user) => FullControl
# - Group (Users) => FullControl
# - Everyone => ReadAndExecute

# Grant FullControl to owner (the new user)
icacls $folderPath /grant "${newUser}:(OI)(CI)F" /T

# Grant FullControl to Users group
icacls $folderPath /grant "Users:(OI)(CI)F" /T

# Grant Read & Execute to Everyone
icacls $folderPath /grant "Everyone:(OI)(CI)RX" /T

# Remove inheritance and preserve inherited permissions if desired (optional)
# icacls $folderPath /inheritance:r

Write-Output "User and ACL setup complete"
</powershell>
