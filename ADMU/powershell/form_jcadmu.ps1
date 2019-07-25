$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptPath = Split-Path $Invocation.MyCommand.Path
. $scriptPath'\import_functions.ps1'

$formpath = $scriptPath + '\xaml.ps1'
$jcadmupath = $scriptPath + '\jcadmu.ps1'

$FormResults = & $formpath
If ($FormResults)
{
    $FormResults | Invoke-Expression -Command:($jcadmupath)
}
Else
{
    Write-Error ('Form did not return anything.')
}