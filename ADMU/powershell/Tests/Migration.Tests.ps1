Describe 'Migration' {

    Context 'Domain Join Status'{

       It 'partOfDomain is $true' {

        Mock -CommandName Get-WmiObject
        $WmiComputerSystem = [PSCustomObject]@{}
        Add-Member -InputObject:($WmiComputerSystem) -MemberType:('NoteProperty') -Name:('partOfDomain') -Value:($true)

        $WmiComputerSystem.partOfDomain | Should Be $true
       }
    }
}