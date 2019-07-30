$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptPath = Split-Path $Invocation.MyCommand.Path
. $scriptPath'\Functions.ps1'

$formpath = $scriptPath + '\xaml.ps1'
$jcadmupath = $scriptPath + '\jcadmu.ps1'

& $formpath
If ($FormResults) {
& $jcadmupath -inputobject $formResults
}
Else {
  Write-Error ('Form did not return anything.')
}
