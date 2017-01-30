$Path = "C:\Users\admin\Documents\GitHub\Legge til vlan pa vHoster\Json"
$ExportPath = "C:\Users\admin\Documents\GitHub\Legge til vlan pa vHoster\Json\ALL.csv"

$Content = Get-ChildItem -Path $Path

$Collection = @()
$Content | foreach {
    $JsonPath = $_.FullName
    $Json = Get-Content -Path $JsonPath -raw
    $Obj = $Json | ConvertFrom-Json
    $Collection += $Obj
}

$Collection | Export-Csv -Path $ExportPath `
                -NoTypeInformation -Force -Delimiter ";"
$Collection
