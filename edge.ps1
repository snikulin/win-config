# PowerShell Script to Install/Update Microsoft Edge and Configure Extensions on Windows

Write-Host "Starting Microsoft Edge setup..."

# 1. Install/Update Microsoft Edge using Winget
Write-Host "Checking/Updating Microsoft Edge installation..."
# Winget 'install' will install or update Edge to the latest stable version
winget install --id Microsoft.Edge --exact --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Winget command for Edge finished with exit code $LASTEXITCODE. This might be okay if Edge was already up-to-date or couldn't be closed."
    # Unlike Brave, Edge is often running/integrated, so errors here might not be critical failures.
    # We'll proceed with policies anyway. Check Edge manually if concerned.
} else {
    Write-Host "Microsoft Edge install/update command completed successfully."
}


# 2. Configure Extensions via Registry
#    Using HKEY_LOCAL_MACHINE applies to all users on the machine. Requires Admin rights.
#    Alternatively, use HKEY_CURRENT_USER for only the current user (might not need Admin).
#    Registry Path for Edge Policies:
#    HKLM\Software\Policies\Microsoft\Edge
#    HKCU\Software\Policies\Microsoft\Edge
#    We will use HKCU for closer similarity to home-manager's user-specific nature.

$policyPath = "Registry::HKEY_CURRENT_USER\Software\Policies\Microsoft\Edge"
$forceInstallListPath = "$policyPath\ExtensionInstallForcelist"

# Ensure the base policy path exists
if (-not (Test-Path $policyPath)) {
    Write-Host "Creating Edge policy registry key: $policyPath"
    New-Item -Path $policyPath -Force | Out-Null
}

# Ensure the ExtensionInstallForcelist key exists
if (-not (Test-Path $forceInstallListPath)) {
    Write-Host "Creating Edge ExtensionInstallForcelist registry key: $forceInstallListPath"
    New-Item -Path $forceInstallListPath -Force | Out-Null
}

Write-Host "Configuring mandatory extensions for Edge..."

# Define extensions (ID;OptionalUpdateURL)
# Edge can install extensions from the Chrome Web Store using their IDs.
# Default Update URL for Chrome Web Store extensions: https://clients2.google.com/service/update2/crx
$defaultUpdateUrl = "https://edge.microsoft.com/extensionwebstorebase/v1/crx"
$extensions = @{
    "1"  = "odfafepnkmbhccpbejgmiehpchacaeak;$defaultUpdateUrl" # ublock origin
    "2"  = "dppgmdbiimibapkepcbdbmkaabgiofem;$defaultUpdateUrl" # 1Password
    "3"  = "mbmgnelfcpoecdepckhlhegpcehmpmji;$defaultUpdateUrl" # SponsorBlock for YouTube
    "4"  = "mbhhijmdgnjdckplligicmjadcpndioj;$defaultUpdateUrl" # Tracking Token Stripper
    "5"  = "ggnepcoiimddpmjaoejhdfppjbcnfaom;$defaultUpdateUrl" # YouTube AutoHD
    "6"  = "lklaendlmlfkaabeleddanafeinnenih;$defaultUpdateUrl" # Tabliss
    "7" = "kkacdgacpkediooahopgcbdahlpipheh;$defaultUpdateUrl" # I still don't care about cookies
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
    Write-Host "Removing obsolete extension registry entries for Edge..."
    foreach ($entry in $entriesToRemove) {
        Write-Host "Removing registry value '$entry'"
        Remove-ItemProperty -Path $forceInstallListPath -Name $entry -Force
    }
}

Write-Host "Microsoft Edge setup script finished. Restart Edge for changes to take full effect."
Write-Host "Note: Extensions configured via policy might not be removable by the user."
Write-Host "You might need to enable 'Allow extensions from other stores' in edge://extensions/ if you haven't already, although policy installs often bypass this."

# 3. Configure Default Search Engine to Google
Write-Host "Configuring default search provider for Edge..."

$searchProvider = @{
    Enabled    = 1 # DWORD 1=True
    Name       = "Google"
    Keyword    = "google.com" # Or just "google"
    SearchURL  = "https://www.google.com/search?q={searchTerms}"
    SuggestURL = "https://www.google.com/complete/search?client=chrome&q={searchTerms}" # Using Chrome suggestion URL, generally works
    IconURL    = "https://www.google.com/favicon.ico"
}

# Set the registry values for the default search provider
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderEnabled" -Value $searchProvider.Enabled -Type DWord -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderName" -Value $searchProvider.Name -Type String -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderKeyword" -Value $searchProvider.Keyword -Type String -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderSearchURL" -Value $searchProvider.SearchURL -Type String -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderSuggestURL" -Value $searchProvider.SuggestURL -Type String -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderIconURL" -Value $searchProvider.IconURL -Type String -Force

Write-Host "Default search provider set to Google for Edge."

# 4. Configure Startup Page (Keep existing setting)
# Change startup page to New tab page
$startupPageValue = 0 # 0 = New tab page, 1 = Specific page, 2 = Previous pages
# Note: Policy for this is RestoreOnStartupUrls (list of URLs) and RestoreOnStartup (action)
# Setting RestoreOnStartup to 5 forces the New Tab Page via policy.
Write-Host "Configuring startup behavior for Edge..."
Set-ItemProperty -Path $policyPath -Name "RestoreOnStartup" -Value 5 -Type DWord -Force
Write-Host "Startup behavior set to 'Open the new tab page' via policy."


# 5. Configure Notification Settings
Write-Host "Configuring notification settings for Edge..."
# DefaultNotificationsSetting: 1 = Allow sites to ask, 2 = Block all notifications
$notificationSetting = 2
Set-ItemProperty -Path $policyPath -Name "DefaultNotificationsSetting" -Value $notificationSetting -Type DWord -Force
Write-Host "Notifications blocked for Edge via policy."


Write-Host "Microsoft Edge setup script finished. Restart Edge for changes to take full effect."
Write-Host "Note: Settings configured via policy might not be changeable by the user through the UI."

