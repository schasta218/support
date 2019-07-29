$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptPath = Split-Path $Invocation.MyCommand.Path

#region Used Functions
$Banner = @'
         __                          ______ __                   __
        / /__  __ ____ ___   ____   / ____// /____   __  __ ____/ /
   __  / // / / // __  __ \ / __ \ / /    / // __ \ / / / // __  /
  / /_/ // /_/ // / / / / // /_/ // /___ / // /_/ // /_/ // /_/ /
  \____/ \____//_/ /_/ /_// ____/ \____//_/ \____/ \____/ \____/
                         /_/
                                                ADMU v1.0.0
'@

#Verify Domain Account Function
Function VerifyAccount {
  Param ([Parameter(Mandatory = $true)][System.String]$userName, [System.String]$domain = $null)

  $idrefUser = $null
  $strUsername = $userName
  If ($domain) {
    $strUsername += [String]("@" + $domain)
  }

  Try {
    $idrefUser = ([System.Security.Principal.NTAccount]($strUsername)).Translate([System.Security.Principal.SecurityIdentifier])
  }
  catch [System.Security.Principal.IdentityNotMappedException] {
    $idrefUser = $null
  }

  If ($idrefUser) {
    return $true
  }
  Else {
    return $false
  }
}

#Logging function
<#
  .Synopsis
     Write-Log writes a message to a specified log file with the current time stamp.
  .DESCRIPTION
     The Write-Log function is designed to add logging capability to other scripts.
     In addition to writing output and/or verbose you can write to a log file for
     later debugging.
  .NOTES
     Created by: Jason Wasser @wasserja
     Modified: 11/24/2015 09:30:19 AM

     Changelog:
      * Code simplification and clarification - thanks to @juneb_get_help
      * Added documentation.
      * Renamed LogPath parameter to Path to keep it standard - thanks to @JeffHicks
      * Revised the Force switch to work as it should - thanks to @JeffHicks

     To Do:
      * Add error handling if trying to create a log file in a inaccessible location.
      * Add ability to write $Message to $Verbose or $Error pipelines to eliminate
        duplicates.
  .PARAMETER Message
     Message is the content that you wish to add to the log file.
  .PARAMETER Path
     The path to the log file to which you would like to write. By default the function will
     create the path and file if it does not exist.
  .PARAMETER Level
     Specify the criticality of the log information being written to the log (i.e. Error, Warning, Informational)
  .PARAMETER NoClobber
     Use NoClobber if you do not wish to overwrite an existing file.
  .EXAMPLE
     Write-Log -Message 'Log message'
     Writes the message to c:\Logs\PowerShellLog.log.
  .EXAMPLE
     Write-Log -Message 'Restarting Server.' -Path c:\Logs\Scriptoutput.log
     Writes the content to the specified log file and creates the path and file specified.
  .EXAMPLE
     Write-Log -Message 'Folder does not exist.' -Path c:\Logs\Script.log -Level Error
     Writes the message to the specified log file as an error message, and writes the message to the error pipeline.
  .LINK
     https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0
  #>
function Write-Log {
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory = $true,
      ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("LogContent")]
    [string]$Message,

    [Parameter(Mandatory = $false)]
    [Alias('LogPath')]
    [string]$Path = 'C:\Windows\Temp\jcadmu.log',

    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warn", "Info")]
    [string]$Level = "Info",

    [Parameter(Mandatory = $false)]
    [switch]$NoClobber
  )

  Begin {
    # Set VerbosePreference to Continue so that verbose messages are displayed.
    $VerbosePreference = 'Continue'
  }
  Process {

    # If the file already exists and NoClobber was specified, do not write to the log.
    if ((Test-Path $Path) -AND $NoClobber) {
      Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
      Return
    }

    # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
    elseif (!(Test-Path $Path)) {
      Write-Verbose "Creating $Path."
      $NewLogFile = New-Item $Path -Force -ItemType File
    }

    else {
      # Nothing to see here yet.
    }

    # Format Date for our Log File
    $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Write message to error, warning, or verbose pipeline and specify $LevelText
    switch ($Level) {
      'Error' {
        Write-Error $Message
        $LevelText = 'ERROR:'
      }
      'Warn' {
        Write-Warning $Message
        $LevelText = 'WARNING:'
      }
      'Info' {
        Write-Verbose $Message
        $LevelText = 'INFO:'
      }
    }

    # Write log entry to $Path
    "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append

  }
  End {
  }
}

#POSH2 unzip func
function unzip($fileName, $sourcePath, $destinationPath) {
  $shell = new-object -com shell.application
  if (!(Test-Path "$sourcePath\$fileName")) {
    throw "$sourcePath\$fileName does not exist"
  }
  New-Item -ItemType Directory -Force -Path $destinationPath -WarningAction SilentlyContinue
  $shell.namespace($destinationPath).copyhere($shell.namespace("$sourcePath$fileName").items(), 0x14)
}

function Remove-ItemSafely {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true
    )]
    [String[]]
    $Path ,

    [Switch]
    $Recurse
  )

  Process {
    foreach ($p in $Path) {
      if (Test-Path $p) {
        Remove-Item $p -Recurse:$Recurse -WhatIf:$WhatIfPreference
      }
    }
  }
}

#Download $Link to $Path
Function DownloadLink($Link, $Path) {

  $WebClient = New-Object -TypeName System.Net.WebClient
  $Global:IsDownloaded = $false
  $SplatArgs = @{ InputObject = $WebClient
    EventName                 = 'DownloadFileCompleted'
    Action                    = { $Global:IsDownloaded = $true }
  }
  $DownloadCompletedEventSubscriber = Register-ObjectEvent @SplatArgs
  $WebClient.DownloadFileAsync("$Link", "$Path")
  while (-not $Global:IsDownloaded) {
    Start-Sleep -Seconds 3
  } #while
  Unregister-Event -SubscriptionId $DownloadCompletedEventSubscriber.Id
  $DownloadCompletedEventSubscriber.Dispose()
  $WebClient.Dispose()

}

#add localuser to group
function Add-LocalUser {
  Param(
    [String[]]
    $computer ,
    [String[]]
    $group ,
    [String[]]
    $localusername
  )
  ([ADSI]"WinNT://$computer/$group,group").psbase.Invoke("Add", ([ADSI]"WinNT://$computer/$localusername").path)
}

#Check if program is installed on system
function Check_Program_Installed( $programName ) {
  $wmi_check = (Get-WMIObject -Query "SELECT * FROM Win32_Product Where Name Like '%$programName%'").Length -gt 0
  return $wmi_check;
}

#Start process and wait then close after 5mins
function Start-NewProcess(
  [string]$pfile,
  [string]$arguments
) {
  $p = New-Object System.Diagnostics.Process;
  $p.StartInfo.FileName = $pfile;
  $p.StartInfo.Arguments = $arguments
  [void]$p.Start();
  if ( ! $p.WaitForExit(300000) )
  { Write-Log -Message "Windows ADK Setup did not complete after 5mins"; Get-Process | Where-Object {$_.Name -like "adksetup*"} | Stop-Process }
}

#endregion
