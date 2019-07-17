[CmdletBinding(DefaultParameterSetName = "cmd")]
param (

  [parameter (ParameterSetName = "cmd", Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][string]$DomainUserName,
  [Parameter(ParameterSetName = "cmd", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][string]$JumpCloudUserName, 
  [Parameter(ParameterSetName = "cmd", Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][string]$TempPassword, # TODO Use SecureString datatype 
  [Parameter(ParameterSetName = "cmd", Mandatory = $true, Position = 3, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][ValidateLength(40, 40)][string]$JumpCloudConnectKey,
  #[Parameter(ParameterSetName="cmd",Mandatory = $true, Position = 4, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][ValidateLength(40, 40)][string]$JumpCloudApiKey, 
  [Parameter(ParameterSetName = "cmd", Mandatory = $false, Position = 5, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][string]$AcceptEULA = $false,
  [parameter(ParameterSetName = "form")]
  [Object]$inputobject
)

#import_functions
$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptPath = Split-Path $Invocation.MyCommand.Path
. $scriptPath'\import_functions.ps1'

if ($PSCmdlet.ParameterSetName -eq "form") {
  #load gui vars

  $DomainUserName = $inputobject.DomainUserName
  $JumpCloudUserName = $inputobject.JumpCloudUserName
  $TempPassword = $inputobject.TempPassword
  $JumpCloudConnectKey = $inputobject.JumpCloudConnectKey
  #TODO - $JumpCloudApiKey = $inputobject.$JumpCloudApiKey
  $AcceptEULA = $inputobject.AcceptEula
}

#vars
$domainname = (Get-WmiObject win32_computersystem).Domain
$netbiosname = $domainname.Substring(0, $domainname.IndexOf('.'))
$localcomputername = (Get-WmiObject Win32_ComputerSystem).Name
$adksetuplink = 'https://go.microsoft.com/fwlink/?linkid=2086042'
$adksetuppath = 'C:\windows\Temp\JCADMU\'
$adksetupfile = 'adksetup.exe'

#msvc2013 vars
$msvc2013path = 'C:\Windows\Temp\JCADMU\'
$msvc2013x64file = 'vc_redist.x64.exe'
$msvc2013x86file = 'vc_redist.x86.exe'
$msvc2013x86link = 'http://download.microsoft.com/download/0/5/6/056dcda9-d667-4e27-8001-8a0c6971d6b1/vcredist_x86.exe'
$msvc2013x64link = 'http://download.microsoft.com/download/0/5/6/056dcda9-d667-4e27-8001-8a0c6971d6b1/vcredist_x64.exe'
$msvc2013x86install = "$msvc2013path$msvc2013x86file" + " /install /quiet /norestart" 
$msvc2013x64install = "$msvc2013path$msvc2013x64file" + " /install /quiet /norestart"


#check domain join status
if ((gwmi win32_computersystem).partofdomain -eq $true) {
  Write-Log -Message ($localcomputername + ' is currently Domain joined to ' + $domainname)
}
else {
  Write-Log -Message ('System is NOT joined to a domain.') -Level Error
  exit
}

#TODO - domain verification checks
# if ($VerifyDomainUserName -eq 'true') {
#   try {
#     $domainaccexists = VerifyAccount -username $DomainUserName -domain $netbiosname
#   }
#   catch {
#     Write-Log -Message ('Domain Username ' + $domainname + '\' + $DomainUserName + ' Could not be verified on domain ' + $domainname) -Level Error
#     exit
#   }
# }
# else {
#   $domainaccexists = 'False'
# }

# if ($VerifyDomainUserName -eq 'true') {
#   Write-Log -Message ($DomainUserName + ' exists in domain ' + $domainname + ' = ' + $domainaccexists)
# }
# else {
#   Write-Log -Message ($DomainUserName + ' is not being verified against the domain.')
# }

#Banner Herestring
Write-Host $Banner -ForegroundColor Green

Write-Log -Message ('Windows Profile ' + $domainname + '\' + $DomainUserName + ' going to be converted to ' + $localcomputername + '\' + $JumpCloudUserName)
Write-Log -Message ('Starting')

#cleanup folders first
Write-Log -Message ('Removing Temp Files & Folders')
try {
  Remove-ItemSafely -Path 'c:\windows\temp\JCADMU\' -Recurse
}
catch {
  Write-Log -Message ('Removal Of Temp Files & Folders Failed') -Level Warn
}



#USMT install & EULA check
if ((-not (Get-WmiObject -Class Win32_Product | Where-Object -FilterScript {$_.Name -like "User State Migration Tool*"})) -And (-not (Test-Path 'C:\adk\Assessment and Deployment Kit\User State Migration Tool\'))) {
  #DOWNLOAD ADK IF NEEDED

  #recreate blank JCADMU folder
  New-Item -ItemType directory -Path 'C:\Windows\Temp\JCADMU\'

  #Download WindowsADK
  DownloadLink -Link $adksetuplink -Path ($adksetuppath + $adksetupfile)

  #Test path
  if (Test-Path $adksetuppath) {
    Write-Log -Message 'Download of Windows ADK Setup file completed successfully'
  }
  else {
    Write-Log -Message ('Failed To Download Windows ADK Setup') -Level Error
    exit
  }

  #not installed and not in right dir
  if ($AcceptEULA -eq $false) {
    Write-Log -Message 'Installing Windows ADK at c:\adk\ please complete GUI prompts & accept EULA within 5mins or it will exit.'
    start-newprocess -pfile 'C:\Windows\Temp\JCADMU\adksetup.exe' -arguments '/installpath c:\adk /features OptionId.UserStateMigrationTool'
  }
  elseif ($AcceptEULA -eq $true) {
    Write-Log -Message 'Installing Windows ADK at c:\adk\ silently. By using "$AcceptEULA = "true" you are accepting the "Microsoft Windows ADK EULA". This process could take up to 3mins if .net is required to be installed, it will timeout if it takes longer than 5mins.'
    start-newprocess -pfile 'C:\Windows\Temp\JCADMU\adksetup.exe' -arguments '/quiet /installpath c:\adk /features OptionId.UserStateMigrationTool'
  }
}
elseif ((Get-WmiObject -Class Win32_Product | Where-Object -FilterScript {$_.Name -like "User State Migration Tool*"}) -And (-not (Test-Path 'C:\adk\Assessment and Deployment Kit\User State Migration Tool\'))) {
  #installed but not in the right dir
  Write-Log -Message ('Microsoft Windows ADK is installed but USMT cant be found in c:\adk\... directory - Please correct and try again.') -Level Error
  exit
}

#Test USMT install path
if (Test-Path 'C:\adk\Assessment and Deployment Kit\User State Migration Tool\') {
  Write-Log -Message 'Microsoft Windows ADK - User State Migration Tool ready to be used.'
}
else {
  Write-Log -Message ('Microsoft Windows ADK - User State Migration Tool not found in c:\adk. Make sure it is installed correctly and in the required location.') -Level Error
  exit
}

#scanstate
Write-Log -Message ('Starting scanstate tool on user ' + $netbiosname + '\' + $DomainUserName)

try {
  Write-Log -Message ('Scanstate Command: .\scanstate.exe c:\Windows\Temp\JCADMU\store /nocompress /i:miguser.xml /i:migapp.xml /l:c:\Windows\Temp\JCADMU\store\scan.log /progress:c:\Windows\Temp\JCADMU\store\scan_progress.log /o /ue:*\* /ui: $netbiosname /c' )
  Invoke-Command -Scriptblock {
    if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq '64-bit') {
      cd "C:\adk\Assessment and Deployment Kit\User State Migration Tool\amd64\"
    }
    else {
      cd "C:\adk\Assessment and Deployment Kit\User State Migration Tool\x86\"
    }
    Write-Log -Message ('Scanstate tool is in progres')
    .\scanstate.exe c:\Windows\Temp\JCADMU\store /nocompress /i:miguser.xml /i:migapp.xml /l:c:\Windows\Temp\JCADMU\store\scan.log /progress:c:\Windows\Temp\JCADMU\store\scan_progress.log /o /ue:*\* /ui:$netbiosname\$DomainUserName /c
  } -ArgumentList {$netbiosname, $DomainUserName}
}
catch {
  Write-Log -Message ('Failed to complete scanstate tool') -Level Error
  exit 1
}
Write-Log -Message ('Scanstate tool completed on user ' + $netbiosname + '\' + $DomainUserName)

Write-Log -Message ('Starting loadstate tool on user ' + $netbiosname + '\' + $DomainUserName + ' converting to ' + $localcomputername + '\' + $JumpCloudUserName)

#loadstate
try {
  Write-Log -Message ('Loadstate Command:.\loadstate.exe c:\Windows\Temp\JCADMU\store /i:miguser.xml /i:migapp.xml /nocompress /l:c:\Windows\Temp\JCADMU\store\load.log /progress:c:\Windows\Temp\JCADMU\store\load_progress.log /ue:*\* /ui:' + $netbiosname + '\' + $DomainUserName + '/lac:$TEMPPASSWORD /lae /c /mu:' + $netbiosname + '`\' + $DomainUserName + '`:' + $localcomputername + '\' + $JumpCloudUserName)
  Invoke-Command -Scriptblock {
    if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq '64-bit') {
      cd "C:\adk\Assessment and Deployment Kit\User State Migration Tool\amd64\"
    }
    else {
      cd "C:\adk\Assessment and Deployment Kit\User State Migration Tool\x86\"
    }

    .\loadstate.exe c:\Windows\Temp\JCADMU\store /i:miguser.xml /i:migapp.xml /nocompress /l:c:\Windows\Temp\JCADMU\store\load.log /progress:c:\Windows\Temp\JCADMU\store\load_progress.log /ue:*\* /ui:$netbiosname\$DomainUserName /lac:$TempPassword /lae /c /mu:$netbiosname`\$DomainUserName`:$localcomputername\$JumpCloudUserName
  } -ArgumentList {$netbiosname, $DomainUserName, $localcomputername, $JumpCloudUserName, $TempPassword}
}
catch {
  Write-Log -Message ('Failed to complete loadstate tool') -Level Error
  exit 1
}

#add user to Users Group for login
Write-Log -Message ('Adding new user ' + $JumpCloudUserName + ' to Users group')
try {
  Add-LocalUser -computer $localcomputername -group 'Users' -localusername $JumpCloudUserName
}
catch {
  Write-Log -Message ('Failed To add new user ' + $JumpCloudUserName + ' to Users group') -Level Error
  exit
}

# Silent JumpCloud Agent Installation Script
#region agentinstall

# JumpCloud Agent Installation Variables
$AGENT_PATH = "${env:ProgramFiles}\JumpCloud"
$AGENT_CONF_FILE = "\Plugins\Contrib\jcagent.conf"
$AGENT_BINARY_NAME = "jumpcloud-agent.exe"
$AGENT_SERVICE_NAME = "jumpcloud-agent"
$AGENT_INSTALLER_URL = "https://s3.amazonaws.com/jumpcloud-windows-agent/production/JumpCloudInstaller.exe"
$AGENT_INSTALLER_PATH = "c:\Windows\Temp\JCADMU\JumpCloudInstaller.exe"
$AGENT_UNINSTALLER_NAME = "unins000.exe"
$EVENT_LOGGER_KEY_NAME = "hklm:\SYSTEM\CurrentControlSet\services\eventlog\Application\jumpcloud-agent"
$INSTALLER_BINARY_NAMES = "JumpCloudInstaller.exe,JumpCloudInstaller.tmp"

# Agent Install Helper Functions
Function AgentIsInstalled() {
  $inServiceMgr = AgentIsInServiceManager
  $onFileSystem = AgentIsOnFileSystem
  $inServiceMgr -Or $onFileSystem
}

Function AgentIsInServiceManager() {
  try {
    $services = Get-Service -Name "${AGENT_SERVICE_NAME}" -ErrorAction Stop
    $true
  }
  catch {
    $false
  }
}

Function AgentIsOnFileSystem() {
  Test-Path ${AGENT_PATH}/${AGENT_BINARY_NAME}
}

Function AgentInstallerExists() {
  Test-Path ${AGENT_INSTALLER_PATH}
}

Function InstallAgent() {
  $params = ("${AGENT_INSTALLER_PATH}", "-k ${JumpCloudConnectKey}", "/VERYSILENT", "/NORESTART", "/SUPRESSMSGBOXES", "/NOCLOSEAPPLICATIONS", "/NORESTARTAPPLICATIONS", "/LOG=$env:TEMP\jcUpdate.log")
  Invoke-Expression "$params"
}

Function AgentIsInstalled() {
  $inServiceMgr = AgentIsInServiceManager
  $onFileSystem = AgentIsOnFileSystem

  $inServiceMgr -Or $onFileSystem
}

Function DownloadAgentInstaller() {
  (New-Object System.Net.WebClient).DownloadFile("${AGENT_INSTALLER_URL}", "${AGENT_INSTALLER_PATH}")
}

# JumpCloud Agent Install
Function DownloadAndInstallAgent() {
  if (!(Check_Program_Installed("Microsoft Visual C++ 2013 x64")) -OR (!(Check_Program_Installed("Microsoft Visual C++ 2013 x86")))) {
    Write-Log -Message 'Downloading & Installing JCAgent prereq'
    DownloadLink -Link $msvc2013x64link -Path ($msvc2013path + $msvc2013x64file)
    DownloadLink -Link $msvc2013x86link -Path ($msvc2013path + $msvc2013x86file)
    "$msvc2013x86install" | cmd
    "$msvc2013x64install" | cmd
    Start-Sleep -s 10
    Write-Log -Message 'JCAgent prereq installed'
  }
  $agentIsInstalled = AgentIsInstalled
  if (-Not $agentIsInstalled) {
    Write-Log -Message 'Downloading agent installer'

    DownloadAgentInstaller

    if (AgentInstallerExists) {
      Write-Log -Message 'Jumpcloud Agent Download Complete'
      Write-Log -Message 'Installing Jumpcloud Agent'
      InstallAgent
      Start-Sleep -s 5

      $ConfirmInstall = AgentIsInServiceManager

      [int]$ConfirmInstallCounter = 0

      while ($ConfirmInstall -ne $true) {
        Start-Sleep -s 2
        $ConfirmInstall = AgentIsInServiceManager
        $ConfirmInstallCounter ++

        if ($ConfirmInstallCounter -eq 30) {

          Write-Log -Message ('Jumpcloud agent installation failed') -Level Error
          exit 1
        }
      }

      $exitCode = $?
      $agentIsInstalled = AgentIsInstalled

      Write-Log -Message 'Jumpcloud agent installation completed.'

      if ($exitCode -ne $true) {
        Write-Log -Message ('Agent installation failed. Please rerun this script, and if that doesnt work, please reboot and try again. If neither work, please contact support@jumpcloud.com') -Level Error
        exit 1
      }
      else {
        Write-Log -Message '* * * SUCCESS! Agent installation complete.* * *'
        Start-Sleep -s 2
      }
    }
    else {
      Write-Log -Message ('Could not download agent installer from ${AGENT_INSTALLER_URL}. Install FAILED.') -Level Error
      exit 1
    }
  }
  else {
    Write-Log -Message ('Agent is already installed, not installing again.')
  }
}

Function ForceRebootComputerWithDelay {
  Param(
    [int]$TimeOut = 10
  )
  $continue = $true

  while ($continue) {
    if ([console]::KeyAvailable) {
      Write-Host "Restart Canceled by key press"
      Exit
    }
    else {
      Write-Host "Press any key to cancel... restarting in $TimeOut" -NoNewLine
      Start-Sleep -Seconds 1
      $TimeOut = $TimeOut - 1
      Clear-Host
      if ($TimeOut -eq 0) {
        $continue = $false
        $Restart = $true
      }
    }
  }
  if ($Restart -eq $True) {
    Write-Host "Restarting Computer..."
    Restart-Computer -ComputerName $env:COMPUTERNAME -Force
  }
}

DownloadAndInstallAgent

#leave domain
Write-Log -Message ('Leaving Domain')
try {
  (Get-WmiObject -Class Win32_ComputerSystem).UnjoinDomainOrWorkgroup($null, $null, 0)
}
catch {
  Write-Log -Message ('Unable to leave domain, Jumpcloud agent will not start until resolved') -Level Error
  exit 1
}

#cleanup folders again before reboot
Write-Log -Message ('Removing Temp Files & Folders.')
try {
  Remove-ItemSafely -Path 'c:\windows\temp\JCADMU\' -Recurse
}
catch {
  Write-Log -Message ('Removal Of Temp Files & Folders Failed') -Level Warn
}

#forecerebootcomputerwithdelay
Write-Log -Message ('Forcing reboot of the PC now')

ForceRebootComputerWithDelay

#endregion
