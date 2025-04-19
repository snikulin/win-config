
$apps = @(
    "Microsoft.VisualStudioCode",
    "Microsoft.PowerShell",
    "Microsoft.WindowsTerminal",
    "Mozilla.Firefox",
    "CPUID.CPU-Z",
    "Docker.DockerDesktop",
    "Git.Git",
    "REALiX.HWiNFO",
    "LizardByte.Sunshine",
    "VideoLAN.VLC",
    "WireGuard.WireGuard",
    "Zoom.Zoom",
    "AgileBits.1Password",
    "Adobe.Acrobat.Reader.64-bit",
    "TheDocumentFoundation.LibreOffice",
    "Transmission.Transmission",
    "SyncTrayzor.SyncTrayzor",
    "OBSProject.OBSStudio",
    "Valve.Steam",
    "DigitalScholar.Zotero",
    "EpicGames.EpicGamesLauncher",
    "Microsoft.PowerToys",
    "Discord.Discord",
    "Postman.Postman",
    "Obsidian.Obsidian",
    "Telegram.TelegramDesktop",
    "Microsoft.WindowsTerminal"
)


Write-Host "Installing Usefull Apps"
foreach ($app in $apps) {
    Write-Host "Installing $app..."
    winget install --id $app --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install $app. Please check Winget logs or install manually."
        # Optional: Exit if app install fails
        # exit 1
    } else {
        Write-Host "$app installed successfully."
    }
}

# Brave installation is handled in brave.ps1

# Brave installation is handled in brave.ps1
Write-Host "Running Brave installation script..."
.\brave.ps1

Write-Host "Running Edge installation script..."
.\edge.ps1