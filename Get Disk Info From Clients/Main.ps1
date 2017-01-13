Import-Module ActiveDirectory

## Change this
$OU = "OU=Netlab,OU=Datamaskiner,OU=IKT-FAG,DC=IKT-FAG,DC=no"
$CsvPath = "C:\Users\admin\Desktop\DiskSpaceClients.csv"
###

$Ping = New-Object System.Net.NetworkInformation.Ping

$NETLAB = Get-ADComputer -Filter * -SearchBase $OU | select DnsHostName

$Col = @()

foreach ($DNSHostName in $NETLAB) {

    $Hostname = $DNSHostName.DnsHostName   

    $Reply = $Ping.Send($Hostname)
    if ($Reply.Status -eq "Success")
    {
        $Obj = [PSCustomObject]@{
            "Hostname" = $Hostname
            "GbTotal" = "000,00"
            "GbUsed" = "000,00"
            "GbFree" = "000,00"
            "Status" = ""
        }

        try
        {
        Get-CimInstance -ComputerName $Hostname win32_logicaldisk -ErrorAction Stop | `
            where caption -eq "C:" | `
                foreach-object {
                    $GbTotal = $('{0:N2}' -f ($_.Size/1gb))
                    $GbFree = $('{0:N2}' -f ($_.FreeSpace/1gb))
                    $GbUsed = ($GbTotal -replace ",", ".") - ($GbFree -replace ",", ".")

                    $Obj.GbTotal = $GbTotal
                    $Obj.GbFree = $GbFree
                    $Obj.GbUsed = $GbUsed
                    $Obj.Status = "Success"
                }
        }
        catch
        {
            $Obj.Status = "Failed"
        }
    }
    else
    {
        $Obj.Status = "Failed"
    }

    $Col += $Obj
}

$Col

$Col | `
    select Hostname, GbTotal, GbUsed, GbFree, Status | `
        Export-Csv -Path  -Delimiter ";" -Force -NoTypeInformation
