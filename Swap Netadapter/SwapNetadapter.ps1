if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
$arguments = "& '" + $myinvocation.mycommand.definition + "'"
Start-Process powershell.exe -windowstyle hidden -Verb runAs -ArgumentList $arguments
Break
}

$Nics = @("Akershus-FK", "IKT-Fag")
$Adapter = Get-NetAdapter 

foreach ($NIC in $Nics)
{
    $CurrAdapter = $Adapter | Where-Object Name -eq $NIC
    if ($CurrAdapter.Status -eq "Disabled")
    {
        Enable-NetAdapter -Name $CurrAdapter.Name -Confirm:$False
        Start-Sleep -Seconds 1
        continue
    }
    if ($CurrAdapter.Status -eq "Up")
    {
        Disable-NetAdapter -Name $CurrAdapter.Name -Confirm:$False
        Start-Sleep -Seconds 1
    }   
}
