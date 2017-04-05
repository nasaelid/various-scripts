Import-Module ActiveDirectory

$Credential = Get-Credential
$ADComputers = Get-ADComputer -Filter * | Where Name -like "*netlab*"
$LicenseKey = ""

$FinishedPath = ".\finished.txt"
if (!(Test-Path -Path $FinishedPath))
{
    New-Item -ItemType file -Path $FinishedPath
}

$Ping = New-Object System.Net.NetworkInformation.Ping

foreach ($Computer in $ADComputers.DNSHostName)
{
    Write-Output "$Computer -- current computer"

    ## If $Finished contains the current computer, this means that
    ## the current computer has already been licensed. Skip it.
    $Finished = Get-Content -Path $FinishedPath
    if ($Finished -contains $Computer)
    {
        Write-Output "$Computer -- is already licensed"
        continue
    }

    ## Skip computer if ping fails
    try
    {
        $Reply = $Ping.Send($Computer)
        if ($Reply.Status -eq "Failed" -or $Reply.Status -eq "TimedOut")
        {
            Write-Output "$Computer -- ping failed"
            continue
        }
    }
    catch
    {
        Write-Output "$Computer -- ping failed"
        continue
    }

    ## License the current computer
    $Output = Invoke-Command -ArgumentList $Computer, $LicenseKey -Credential $Credential -ComputerName $Computer `
    -ScriptBlock {
        $Computer = $args[0]
        $LicenseKey = $args[1]

        Start-Process cmd.exe /c "slmgr /ipk $LicenseKey" -Wait | Out-Null
        Start-Process cmd.exe /c "slmgr /ato" -Wait | Out-Null
        
        Write-Output $Computer
    }

    ## Output the computer to finished.txt, since it's complete
    [string]$Output | Out-File -FilePath $FinishedPath -Append
}
