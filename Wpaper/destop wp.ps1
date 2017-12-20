param (
    [string]$BackgroundsFolder = (Join-Path -Path  ([System.Environment]::GetFolderPath('Personal')) -ChildPath 'DesktopBackgrounds'),
    [int]$Limit = 200
)
function Get-Image {
    param ([string]$Path)
    if (Test-Path $Path) {
        $img = [System.Drawing.Image]::FromFile($Path)
        $img.Clone()
        [void]$img.Dispose()
    } else {
        Write-Log "Get-Image: File not found: $_"
    }
}
function Write-Log {
    param ([string]$Message)
    Write-Output ('{0:yyyy-MM-dd hh:mm:ss} {1}' -f (Get-Date), $Message) | Out-File $LogFile -Append
    Write-Host $Message -ForegroundColor Yellow
}
 
Set-StrictMode -Version Latest
if (-not (Test-Path $BackgroundsFolder)) {
    New-Item $BackgroundsFolder -ItemType Directory
} elseif (-not (Get-Item -Path $BackgroundsFolder).Attributes.ToString().Contains('Directory')) {
    throw "$BackgroundsFolder is not a directory"
}
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$LogFolder = ([System.Environment]::GetFolderPath('Personal'))
[string]$LogFile = Join-Path -Path $LogFolder -ChildPath 'DesktopBackgrounds.log'
[string]$DTBGListFile = Join-Path -Path $LogFolder -ChildPath 'DesktopBackgrounds.txt'
if (-not (Test-Path $DTBGListFile)) { New-Item $DTBGListFile }
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
$ImageUrlRE = '.*?="(https?://(?:orig..\.deviantart\.net|blogspot\.com|hdqwalls.com|i\.imgur\.com|i\.redd\.it)/[^"]*?)">'
$ImageExtensionRE = '\.(jpg|png)\z'
$RSSFeedUrl = 'https://www.reddit.com/r/WQHD_Wallpaper.rss'
#
# Copy images from the WQHD_Wallpaper subreddit to a folder
#
Get-ChildItem -Path $BackgroundsFolder\* -File -Include *.jpg, *.png |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $Limit |
    Remove-Item -Confirm:$false -Verbose
# Get the RSS feed from the subreddit
# look through post entries looking for links to imgur.com or redd.it
# download any jpg links to our backgrounds folder
([xml](Invoke-WebRequest -Uri $RSSFeedUrl)).feed.entry | % { $_.content.'#text' } | ? { $_ -match $ImageUrlRE } | % {
    [string]$Uri = $Matches[1]
    # Write-Log $Uri
    if ($Uri -match $ImageExtensionRE) {
        [string]$OutFile = Join-Path -Path $BackgroundsFolder -ChildPath ($Uri -replace '.*?/([^/]+)\z', '$1')
        # $LogFile contains the names of all files we've downloaded before
        # Skip the file if we've copied it before
        if ((-not (Select-String -Path $DTBGListFile -SimpleMatch -Pattern $Uri)) -and (-not (Test-Path $OutFile))) {
            Write-Log "Copying $Uri"
            try {
                Invoke-WebRequest -Uri $Uri -OutFile $OutFile
                # Add the name to our log file so if we delete it manually it won't be recopied in the future
                Add-Content -Path $DTBGListFile -Value $Uri
                # Check image to see if it's only some low-res crap
                [System.Drawing.Bitmap]$Image = Get-Image $OutFile
                if ($Image -and (($Image.Width -lt 1920) -or ($Image.Height -lt 1040))) {
                    Write-Log "$OutFile is low-res. Deleting..."
                    Remove-Item $OutFile
                } elseif (-not $Image) {
                    Write-Log "Could not get dimensions of $OutFile"
                }
            } catch {
                Write-Log "Copying file '$Uri' failed"
            }
        }
    }
}