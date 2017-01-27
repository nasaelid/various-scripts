Import-Module ActiveDirectory

## These need to be changed
$Computers = Get-ADGroupMember -Identity Elevmaskiner
$Cred = Get-Credential
$DomainName = ".ikt-fag.no"

$Ping = New-Object System.Net.NetworkInformation.Ping

foreach ($Computer in $Computers)
{
    $Hostname = $Computer.name + $DomainName
    Write-Output $Hostname

    try
    {
        $Response = $Ping.Send($Hostname)
        if($Response.Status -eq "Failed" -or $Response.Status -eq "TimedOut")
        {
            Write-Output "Failed to Ping $Hostname"
            continue
        }
    }
    catch
    {
        Write-Output "Failed to Ping $Hostname"
        continue
    }

    Invoke-Command -ComputerName $Hostname -Credential $Cred -ScriptBlock {
        
        Get-Service -Name wuauserv | Stop-Service -Force
        
        Remove-Item -Path "C:\WINDOWS\SoftwareDistribution" -Recurse -Force

        cmd.exe /c "wuauclt /resetauthorization /detectnow"
        cmd.exe /c "wuauclt /reportnow"

        Get-Service -Name wuauserv | Start-Service
    } -ErrorAction Continue
}
