Import-Module ActiveDirectory

## Change this
$Filter = "*lab-*"
##############

$DateT = Get-Date -Format dd-MM-yyy
$LogString = "$($DateT)_ShutdownLogs.txt"
$LogPath = "C:\Logs\$LogString"

Start-Transcript -Path $LogPath -Force

try
{
    Write-Information "Attempting to get computers with filter: $Filter"
    $ADComputers = Get-ADComputer -Filter { DNSHostName -like $Filter } -ErrorAction Stop
}
catch
{
    Write-Error "Failed to get computers from AD `r`n" + $Error[0].Exception.Message
}

Write-Information "Got AD computers with filter: $Filter"

foreach ($Computer in $ADComputers)
{
    $CN = $Computer.DNSHostName
    Write-Information "Shutting down: $CN"
    try
    {
        Stop-Computer -ComputerName $Computer -ErrorAction Stop
        Write-Host "SHUT DOWN $CN"
        Write-Host "SUCCESS: Shut down: $CN"
    }
    catch
    {
        Write-Error "Failed to shut down $CN `r`n" + $Error[0].Exception.Message
    }
}
Write-Host "SUCCESS: Finished shutting down computers."
Write-Host "**********************"

$ADComputers | % {
    Write-Host $_.DNSHostName
    #Write-Host "`r`n"
}

Stop-Transcript
