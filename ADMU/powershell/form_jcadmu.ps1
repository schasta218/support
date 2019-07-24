$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptPath = Split-Path $Invocation.MyCommand.Path
. $scriptPath'\import_functions.ps1'

$formpath = $scriptPath + '\xaml.ps1'
$jcadmupath = $scriptPath + '\jcadmu.ps1'

& $formpath
if ($null -eq $FormResults){
& $jcadmupath -inputobject $FormResults
}
