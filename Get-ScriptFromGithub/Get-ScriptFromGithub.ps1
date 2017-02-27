[CmdletBinding()]
param
(
    [Parameter( Mandatory = $True,
                Position = 0)]
    [String] $Uri,

    [Parameter( Mandatory = $True,
                Position = 1)]
    [String] $Path
)
if (!(Test-Path -Path $Path))
{
    throw "$OutPath -- is not a valid path."
}
$FileName = Split-Path -Path $Uri -Leaf
$OutPath = Join-Path -Path $Path -ChildPath $FileName
try
{
    Invoke-WebRequest -Uri $Uri -OutFile $OutPath -Method Get -ErrorAction Stop | Out-Null
}
catch
{
    throw "$Uri -- could not download script"
}

$True
