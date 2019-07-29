$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptPath = Split-Path $Invocation.MyCommand.Path
. $scriptPath'\Functions.ps1'

$formpath = $scriptPath + '\xaml.ps1'
$jcadmupath = $scriptPath + '\jcadmu.ps1'

$FormResults = & $formpath
If ($FormResults) {
  $FormResults | Invoke-Expression -Command:($jcadmupath)
}
Else {
  Write-Error ('Form did not return anything.')
}

# Get script path
#$scriptPath = (Split-Path -Path:($MyInvocation.MyCommand.Path)) + '\'
# Define misc. variables
#$Template_Command = '& "{0}"'
# Define ref files
#$functionsPath = $Template_Command -f ($scriptPath + 'Functions.ps1')
#$xamlPath = $Template_Command -f ($scriptPath + 'xaml.ps1')
#$jcAdmuPath = $Template_Command -f ($scriptPath + 'jcadmu.ps1')
# Load functions
#Invoke-Expression -Command:($functionsPath)
# Load form
#$formResults = Invoke-Expression -Command:($xamlPath)
# Send form results to process
#If ($formResults)
#{
#    $formResults | Invoke-Expression -Command:($jcAdmuPath)
#}
#Else
#{
#    Write-Error ('Form did not return anything.')
#}





