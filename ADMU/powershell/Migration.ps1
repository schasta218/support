[CmdletBinding(DefaultParameterSetName = "cmd")]
Param (
    [Parameter(ParameterSetName = "cmd", Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][string]$DomainUserName
    , [Parameter(ParameterSetName = "cmd", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][string]$JumpCloudUserName
    , [Parameter(ParameterSetName = "cmd", Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][string]$TempPassword # TODO Use SecureString datatype
    , [Parameter(ParameterSetName = "cmd", Mandatory = $true, Position = 3, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][ValidateLength(40, 40)][string]$JumpCloudConnectKey
    # ,[Parameter(ParameterSetName="cmd",Mandatory = $true, Position = 4, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][ValidateLength(40, 40)][string]$JumpCloudApiKey
    , [Parameter(ParameterSetName = "cmd", Mandatory = $false, Position = 5, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][string]$AcceptEULA = $false
    , [Parameter(ParameterSetName = "form")][Object]$inputObject
)
Begin
{
    # Define misc static variables
    $adkSetupLink = 'https://go.microsoft.com/fwlink/?linkid=2086042'
    $adkPath = 'C:\adk\'
    $jcAdmuTempPath = 'C:\Windows\Temp\JCADMU\'
    $jcAdmuLogFile = 'C:\Windows\Temp\jcAdmu.log'
    $UserStateMigrationToolPath = $adkPath + 'Assessment and Deployment Kit\User State Migration Tool\'
    $UserStateMigrationToolx64Path = $UserStateMigrationToolPath + 'amd64'
    $UserStateMigrationToolx86Path = $UserStateMigrationToolPath + 'x86'
    $profileStorePath = $jcAdmuTempPath + 'store'
    $adksetupfile = 'adksetup.exe'
    $adkSetupPath = $jcAdmuTempPath + $adksetupfile
    $adkSetupArguments = '/installpath ' + $adkPath + ' /features OptionId.UserStateMigrationTool'
    $adkSetupArgumentsQuiet = '/quiet ' + $adkSetupArguments
    $msvc2013x64File = 'vc_redist.x64.exe'
    $msvc2013x86File = 'vc_redist.x86.exe'
    $msvc2013x86Link = 'http://download.microsoft.com/download/0/5/6/056dcda9-d667-4e27-8001-8a0c6971d6b1/vcredist_x86.exe'
    $msvc2013x64Link = 'http://download.microsoft.com/download/0/5/6/056dcda9-d667-4e27-8001-8a0c6971d6b1/vcredist_x64.exe'
    $msvc2013x86Install = "$jcAdmuTempPath$msvc2013x86File /install /quiet /norestart"
    $msvc2013x64Install = "$jcAdmuTempPath$msvc2013x64File /install /quiet /norestart"
    $CommandScanStateTemplate = 'cd "{0}"; .\ScanState.exe "{1}" /nocompress /i:"{0}\miguser.xml" /i:"{0}\migapp.xml" /l:"{1}\scan.log" /progress:"{1}\scan_progress.log" /o /ue:"*\*" /ui:"{2}\{3}" /c' # $UserStateMigrationToolVersionPath, $profileStorePath, $netBiosName, $DomainUserName
    $CommandLoadStateTemplate = 'cd "{0}"; .\LoadState.exe "{1}" /i:"{0}\miguser.xml" /i:"{0}\migapp.xml" /nocompress /l:"{1}\load.log" /progress:"{1}\load_progress.log" /ue:"*\*" /ui:"{2}\{3}" /laC:"{4}" /lae /c /mu:"{2}\{3}:{5}\{6}"' # $UserStateMigrationToolVersionPath, $profileStorePath, $netBiosName, $DomainUserName, $TempPassword, $localComputerName, $JumpCloudUserName
    # JumpCloud Agent Installation Variables
    $AGENT_PATH = "${env:ProgramFiles}\JumpCloud"
    $AGENT_CONF_FILE = "\Plugins\Contrib\jcagent.conf"
    $AGENT_BINARY_NAME = "JumpCloud-agent.exe"
    $AGENT_SERVICE_NAME = "JumpCloud-agent"
    $AGENT_INSTALLER_URL = "https://s3.amazonaws.com/JumpCloud-windows-agent/production/JumpCloudInstaller.exe"
    $AGENT_INSTALLER_PATH = "C:\windows\Temp\jcAdmu\JumpCloudInstaller.exe"
    $AGENT_UNINSTALLER_NAME = "unins000.exe"
    $EVENT_LOGGER_KEY_NAME = "hklm:\SYSTEM\CurrentControlSet\services\eventlog\Application\JumpCloud-agent"
    $INSTALLER_BINARY_NAMES = "JumpCloudInstaller.exe,JumpCloudInstaller.tmp"
    # Load functions
    . ((Split-Path -Path:($MyInvocation.MyCommand.Path)) + '\Functions.ps1')
    # Start script
    Write-Log -Message:('Script starting; Log file location: ' + $jcAdmuLogFile)
    Write-Log -Message:('Gathering system information')
    $WmiComputerSystem = Get-WmiObject -Class:('Win32_ComputerSystem')
    $WmiProduct = Get-WmiObject -Class:('Win32_Product') | Where-Object -FilterScript {$_.Name -like "User State Migration Tool*"}
    $WmiOperatingSystem = Get-WmiObject -Class:('Win32_OperatingSystem')
    $localComputerName = $WmiComputerSystem.Name
    $UserStateMigrationToolVersionPath = Switch ($WmiOperatingSystem.OSArchitecture)
    {
        '64-bit' {$UserStateMigrationToolx64Path}
        '32-bit' {$UserStateMigrationToolx86Path}
        Default {Write-Log -Message:('Unknown OSArchitecture') -Level:('Error')}
    }
}
Process
{
    # Conditional ParameterSet logic
    If ($PSCmdlet.ParameterSetName -eq "form")
    {
        $DomainUserName = $inputObject.DomainUserName
        $JumpCloudUserName = $inputObject.JumpCloudUserName
        $TempPassword = $inputObject.TempPassword
        $JumpCloudConnectKey = $inputObject.JumpCloudConnectKey
        $AcceptEULA = $inputObject.AcceptEula
    }
    $DomainName = $WmiComputerSystem.Domain
    $netBiosName = If (-not [System.String]::IsNullOrEmpty($DomainName))
    {
        $DomainName.Substring(0, $DomainName.IndexOf('.'))
    }
    Else
    {
        $null
    }
    # Check Domain Join Status
    If ($WmiComputerSystem.partOfDomain -eq $true)
    {
        Write-Log -Message:($localComputerName + ' is currently Domain joined to ' + $DomainName)
    }
    Else
    {
        Write-Log -Message:('System is NOT joined to a domain.') -Level:('Error')
        Exit;
    }
    # Start Of Console Output
    Write-Host ($Banner) -ForegroundColor:('Green')
    Write-Log -Message:('Windows Profile "' + $DomainName + '\' + $DomainUserName + '" going to be converted to "' + $localComputerName + '\' + $JumpCloudUserName + '"')
    # User State Migration Tool Install & EULA Check
    If (-not $WmiProduct -and -not (Test-Path -Path:($UserStateMigrationToolPath)))
    {
        # Remove existing jcAdmu folder
        If (Test-Path -Path:($jcAdmuTempPath))
        {
            Write-Log -Message:('Removing Temp Files & Folders')
            Remove-ItemIfExists -Path:($jcAdmuTempPath) -Recurse
        }
        # Create jcAdmu folder
        If (!(Test-Path -Path:($jcAdmuTempPath)))
        {
            New-Item -Path:($jcAdmuTempPath) -ItemType:('Directory') | Out-Null
        }
        # Download WindowsADK
        DownloadLink -Link:($adkSetupLink) -Path:($adkSetupPath)
        # Test Path
        If (Test-Path -Path:($adkSetupPath))
        {
            Write-Log -Message:('Download of Windows ADK Setup file completed successfully')
        }
        Else
        {
            Write-Log -Message:('Failed To Download Windows ADK Setup') -Level:('Error')
            Exit;
        }
        # Not Installed & Not In Right Dir
        If ($AcceptEULA -eq $false)
        {
            Write-Log -Message:('Installing Windows ADK at ' + $adkPath + ' please complete GUI prompts & accept EULA within 5 mins or it will Exit.')
            Start-NewProcess -pfile:($adkSetupPath) -arguments:($adkSetupArguments)
        }
        ElseIf ($AcceptEULA -eq $true)
        {
            Write-Log -Message:('Installing Windows ADK at ' + $adkPath + ' silently. By using "$AcceptEULA = "true" you are accepting the "Microsoft Windows ADK EULA". This process could take up to 3 mins if .net is required to be installed, it will timeout if it takes longer than 5 mins.')
            Start-NewProcess -pfile:($adkSetupPath) -arguments:($adkSetupArgumentsQuiet)
        }
    }
    ElseIf ($WmiProduct -and (-not (Test-Path -Path:($UserStateMigrationToolPath))))
    {
        # Installed But Not In Right Dir
        Write-Log -Message:('Microsoft Windows ADK is installed but User State Migration Tool cant be found in ' + $adkPath + '... directory - Please correct and Try again.') -Level:('Error')
        Exit;
    }
    # Test User State Migration Tool install path
    If (Test-Path -Path:($UserStateMigrationToolPath))
    {
        Write-Log -Message:('Microsoft Windows ADK - User State Migration Tool ready to be used.')
    }
    Else
    {
        Write-Log -Message:('Microsoft Windows ADK - User State Migration Tool not found in ' + $adkPath + '. Make sure it is installed correctly and in the required location.') -Level:('Error')
        Exit;
    }
    # ScanState Step
    Try
    {
        $CommandScanState = $CommandScanStateTemplate -f $UserStateMigrationToolVersionPath, $profileStorePath, $netBiosName, $DomainUserName
        Write-Log -Message:('Starting ScanState tool on user "' + $netBiosName + '\' + $DomainUserName + '"')
        Write-Log -Message:('ScanState tool is in progress. Command: ' + $CommandScanState)
        Invoke-Expression -command:($CommandScanState)
        Write-Log -Message:('ScanState tool completed for user "' + $netBiosName + '\' + $DomainUserName + '"')
    }
    Catch
    {
        Write-Log -Message:('ScanState tool failed for user "' + $netBiosName + '\' + $DomainUserName + '"') -Level:('Error')
        Exit;
    }
    # LoadState Step
    Try
    {
        $CommandLoadState = $CommandLoadStateTemplate -f $UserStateMigrationToolVersionPath, $profileStorePath, $netBiosName, $DomainUserName, $TempPassword, $localComputerName, $JumpCloudUserName
        Write-Log -Message:('Starting LoadState tool on user "' + $netBiosName + '\' + $DomainUserName + '"' + ' converting to "' + $localComputerName + '\' + $JumpCloudUserName + '"')
        Write-Log -Message:('LoadState tool is in progress. Command: ' + $CommandLoadState)
        Invoke-Expression -Command:($CommandLoadState)
        Write-Log -Message:('LoadState tool completed for user "' + $netBiosName + '\' + $DomainUserName + '"' + ' converting to "' + $localComputerName + '\' + $JumpCloudUserName + '"')
    }
    Catch
    {
        Write-Log -Message:('LoadState tool failed for user "' + $netBiosName + '\' + $DomainUserName + '"' + ' converting to "' + $localComputerName + '\' + $JumpCloudUserName + '"') -Level:('Error')
        Exit;
    }
    # Add User To Users Group For Login
    Try
    {
        Write-Log -Message:('Adding new user "' + $JumpCloudUserName + '" to Users group')
        Add-LocalUser -computer:($localComputerName) -group:('Users') -localusername:($JumpCloudUserName)
    }
    Catch
    {
        Write-Log -Message:('Failed To add new user "' + $JumpCloudUserName + '" to Users group') -Level:('Error')
        Exit;
    }
    # region SilentAgentInstall
    # Agent Install Helper Functions
Function AgentIsOnFileSystem()
{
    Test-Path -Path:(${AGENT_PATH} / ${AGENT_BINARY_NAME})
}
Function InstallAgent()
{
    $params = ("${AGENT_INSTALLER_PATH}", "-k ${JumpCloudConnectKey}", "/VERYSILENT", "/NORESTART", "/SUPRESSMSGBOXES", "/NOCLOSEAPPLICATIONS", "/NORESTARTAPPLICATIONS", "/LOG=$env:TEMP\jcUpdate.log")
    Invoke-Expression "$params"
}
Function DownloadAgentInstaller()
{
    (New-Object System.Net.WebClient).DownloadFile("${AGENT_INSTALLER_URL}", "${AGENT_INSTALLER_PATH}")
}
Function ForceRebootComputerWithDelay
{
    Param(
        [int]$TimeOut = 10
    )
    $continue = $true

    while ($continue)
    {
        If ([console]::KeyAvailable)
        {
            Write-Host "Restart Canceled by key press"
            Exit;
        }
        Else
        {
            Write-Host "Press any key to cancel... restarting in $TimeOut" -NoNewLine
            Start-Sleep -Seconds 1
            $TimeOut = $TimeOut - 1
            Clear-Host
            If ($TimeOut -eq 0)
            {
                $continue = $false
                $Restart = $true
            }
        }
    }
    If ($Restart -eq $True)
    {
        Write-Host "Restarting Computer..."
        Restart-Computer -ComputerName $env:COMPUTERNAME -Force
    }
}
    # Agent Installer Loop
    [int]$InstallReTryCounter = 0
    Do
    {
        $ConfirmInstall = DownloadAndInstallAgent -msvc2013x64link:($msvc2013x64Link) -msvc2013path:($msvc2013path) -msvc2013x64file:($msvc2013x64File) -msvc2013x64install:($msvc2013x64Install) -msvc2013x86link:($msvc2013x86Link) -msvc2013x86file:($msvc2013x86File) -msvc2013x86install:($msvc2013x86Install)
        $InstallReTryCounter++
        If ($InstallReTryCounter -eq 3)
        {
            Write-Log -Message:('JumpCloud agent installation failed') -Level:('Error')
            Exit;
        }
    } While ($ConfirmInstall -ne $true -and $InstallReTryCounter -le 3)
    # Leave Domain
    Write-Log -Message:('Leaving Domain')
    Try
    {
        $WmiComputerSystem.UnJoinDomainOrWorkGroup($null, $null, 0)
    }
    Catch
    {
        Write-Log -Message:('Unable to leave domain, JumpCloud agent will not start until resolved') -Level:('Error')
        Exit;
    }
    # Cleanup Folders Again Before Reboot
    Write-Log -Message:('Removing Temp Files & Folders.')
    Remove-ItemIfExists -Path:($jcAdmuTempPath) -Recurse
    # ForceRebootBootComputerWithDelay
    Write-Log -Message:('Forcing reboot of the PC now')
    ForceRebootComputerWithDelay
    #endregion
}
End
{
    Write-Log -Message:('Script finished; Log file location: ' + $jcAdmuLogFile)
}