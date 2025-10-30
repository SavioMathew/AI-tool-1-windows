<powershell>

# ===============================================
# Terraform Windows User Setup Script
# ===============================================
# This script runs automatically at first boot.
# It creates a local user, sets permissions, and enables RDP login.
# Logs are saved to C:\Windows\Temp\userdata.log
# ===============================================

# Start logging to file
Start-Transcript -Path "C:\Windows\Temp\userdata.log" -Append

# Variables passed by Terraform template
$newUser = "${windows_username}"
$passwordPlain = "${windows_password}"

Write-Output "Starting user creation for: $newUser"

# Convert plain password to secure string
$securePass = ConvertTo-SecureString -String $passwordPlain -AsPlainText -Force

# Create local user if it doesn't exist
if (-not (Get-LocalUser -Name $newUser -ErrorAction SilentlyContinue)) {
    Write-Output "Creating new local user: $newUser"
    New-LocalUser -Name $newUser -Password $securePass -PasswordNeverExpires:$true -UserMayNotChangePassword:$false -AccountNeverExpires:$true
} else {
    Write-Output "User $newUser already exists. Updating password."
    $u = Get-LocalUser -Name $newUser
    $u | Set-LocalUser -Password $securePass
}

# Add user to local groups
Write-Output "Adding $newUser to local groups"
Add-LocalGroupMember -Group "Users" -Member $newUser -ErrorAction SilentlyContinue
Add-LocalGroupMember -Group "Administrators" -Member $newUser -ErrorAction SilentlyContinue

# Enable RDP access for the new user
Write-Output "Granting RDP access to $newUser"
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $newUser -ErrorAction SilentlyContinue

# Create application folder and set permissions
$folderPath = "C:\app"
if (-not (Test-Path $folderPath)) {
    Write-Output "Creating folder: $folderPath"
    New-Item -Path $folderPath -ItemType Directory | Out-Null
}

Write-Output "Setting ACLs for $folderPath"
icacls $folderPath /grant "${newUser}:(OI)(CI)F" /T
icacls $folderPath /grant "Users:(OI)(CI)F" /T
icacls $folderPath /grant "Everyone:(OI)(CI)RX" /T

Write-Output "User $newUser setup and ACL configuration complete."

# Stop logging
Stop-Transcript

</powershell>
