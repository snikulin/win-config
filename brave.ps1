# PowerShell Script to Install Brave and Configure Extensions on Windows

Write-Host "Starting Brave setup..."

# 1. Install Brave using Winget
Write-Host "Checking for Brave installation..."
$braveApp = winget list --id BraveSoftware.BraveBrowser --accept-source-agreements | Select-String -Pattern "BraveSoftware.BraveBrowser"
if ($braveApp) {
    Write-Host "Brave is already installed."
} else {
    Write-Host "Installing Brave using Winget..."
    winget install --id BraveSoftware.BraveBrowser --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install Brave. Please check Winget logs or install manually."
        # Optional: Exit if Brave install fails
        # exit 1
    } else {
        Write-Host "Brave installed successfully."
    }
}

# 2. Configure Extensions via Registry
#    Using HKEY_LOCAL_MACHINE applies to all users on the machine. Requires Admin rights.
#    Alternatively, use HKEY_CURRENT_USER for only the current user (might not need Admin).
#    Registry Path for Brave Policies:
#    HKLM\Software\Policies\BraveSoftware\Brave
#    HKCU\Software\Policies\BraveSoftware\Brave
#    We will use HKCU for closer similarity to home-manager's user-specific nature.

$policyPath = "Registry::HKEY_CURRENT_USER\Software\Policies\BraveSoftware\Brave"
$forceInstallListPath = "$policyPath\ExtensionInstallForcelist"

# Ensure the base policy path exists
if (-not (Test-Path $policyPath)) {
    Write-Host "Creating Brave policy registry key: $policyPath"
    New-Item -Path $policyPath -Force | Out-Null
}

# Ensure the ExtensionInstallForcelist key exists
if (-not (Test-Path $forceInstallListPath)) {
    Write-Host "Creating Brave ExtensionInstallForcelist registry key: $forceInstallListPath"
    New-Item -Path $forceInstallListPath -Force | Out-Null
}

Write-Host "Configuring mandatory extensions..."

# Define extensions (ID;OptionalUpdateURL)
# Default Update URL for Chrome Web Store extensions: https://clients2.google.com/service/update2/crx
$defaultUpdateUrl = "https://clients2.google.com/service/update2/crx"
$extensions = @{
    "1"  = "cjpalhdlnbpafiamejdnhcphjbkeiagm;$defaultUpdateUrl" # ublock origin
    "2"  = "aeblfdkhhhdcdjpifhhbdiojplfjncoa;$defaultUpdateUrl" # 1Password
    "3"  = "mnjggcdmjocbbbhaepdhchncahnbgone;$defaultUpdateUrl" # SponsorBlock for YouTube
    "4"  = "kcpnkledgcbobhkgimpbmejgockkplob;$defaultUpdateUrl" # Tracking Token Stripper
    "5"  = "gebbhagfogifgggkldgodflihgfeippi;$defaultUpdateUrl" # Return YouTube Dislike
    "6"  = "naepdomgkenhinolocfifgehidddafch;$defaultUpdateUrl" # Browserpass
    "7"  = "enamippconapkdmgfgjchkhakpfinmaj;$defaultUpdateUrl" # DeArrow
    "8"  = "fcphghnknhkimeagdglkljinmpbagone;$defaultUpdateUrl" # YouTube AutoHD
    "9"  = "hipekcciheckooncpjeljhnekcoolahp;$defaultUpdateUrl" # Tabliss
    "10" = "edibdbjcniadpccecjdfdjjppcpchdlm;$defaultUpdateUrl" # I still don't care about cookies
    "11" = "dcpihecpambacapedldabdbpakmachpb;https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/src/updates/updates.xml" # Bypass Paywalls (with custom update URL)
}

# Apply extension settings to the registry
$extensions.GetEnumerator() | ForEach-Object {
    $regName = $_.Name
    $regValue = $_.Value
    Write-Host "Setting registry value '$regName' for extension '$($regValue.Split(';')[0])'"
    Set-ItemProperty -Path $forceInstallListPath -Name $regName -Value $regValue -Type String -Force
}

# Optional: Clean up old numbered entries if you remove extensions from the list above
# Get current registry value names (1, 2, 3...)
$currentRegEntries = (Get-ItemProperty -Path $forceInstallListPath).PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } | Select-Object -ExpandProperty Name
# Get desired registry value names from our list
$desiredRegEntries = $extensions.Keys
# Find entries to remove
$entriesToRemove = $currentRegEntries | Where-Object { $desiredRegEntries -notcontains $_ }
if ($entriesToRemove) {
    Write-Host "Removing obsolete extension registry entries..."
    foreach ($entry in $entriesToRemove) {
        Write-Host "Removing registry value '$entry'"
        Remove-ItemProperty -Path $forceInstallListPath -Name $entry -Force
    }
}


Write-Host "Brave setup script finished. Restart Brave for changes to take full effect."
Write-Host "Note: Extensions configured via policy might not be removable by the user."

# 3. Configure Default Search Engine to Google
Write-Host "Configuring default search provider for Brave..."

$searchProvider = @{
    Enabled    = 1 # DWORD 1=True
    Name       = "Google"
    Keyword    = "google.com" # Or just "google"
    SearchURL  = "https://www.google.com/search?q={searchTerms}"
    SuggestURL = "https://www.google.com/complete/search?client=chrome&q={searchTerms}"
    IconURL    = "https://www.google.com/favicon.ico"
}

# Set the registry values for the default search provider
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderEnabled" -Value $searchProvider.Enabled -Type DWord -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderName" -Value $searchProvider.Name -Type String -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderKeyword" -Value $searchProvider.Keyword -Type String -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderSearchURL" -Value $searchProvider.SearchURL -Type String -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderSuggestURL" -Value $searchProvider.SuggestURL -Type String -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderIconURL" -Value $searchProvider.IconURL -Type String -Force

Write-Host "Default search provider set to Google for Brave."

# 4. Configure Notification Settings
Write-Host "Configuring notification settings for Brave..."
# DefaultNotificationsSetting: 1 = Allow sites to ask, 2 = Block all notifications
$notificationSetting = 2
Set-ItemProperty -Path $policyPath -Name "DefaultNotificationsSetting" -Value $notificationSetting -Type DWord -Force
Write-Host "Notifications blocked for Brave via policy."


Write-Host "Brave setup script finished. Restart Brave for changes to take full effect."
Write-Host "Note: Settings configured via policy might not be changeable by the user through the UI."

