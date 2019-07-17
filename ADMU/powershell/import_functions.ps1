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

#region xaml form functions
function xamlform {
  #==============================================================================================
  # XAML Code - Imported from Visual Studio WPF Application
  #==============================================================================================
  [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
  [xml]$XAML = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="JumpCloud ADMU 1.0.0" Height="269.952" Width="894.796" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" ForceCursor="True">
    <Grid Margin="0,0,-0.2,0.2">
        <ListView Name="lvProfileList" HorizontalAlignment="Left" Height="114.454" Margin="10,10,0,0" VerticalAlignment="Top" Width="863.1">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="UserName" DisplayMemberBinding="{Binding 'UserName'}" Width="180"/>
                    <GridViewColumn Header="LastLogin" DisplayMemberBinding="{Binding 'LastLogin'}" Width="140"/>
                    <GridViewColumn Header="CurrentlyActive" DisplayMemberBinding="{Binding 'Loaded'}" Width="100" />
                    <GridViewColumn Header="DomainRoaming" DisplayMemberBinding="{Binding 'RoamingConfigured'}" Width="120"/>
                </GridView>
            </ListView.View>
        </ListView>
        <Button Name="bDeleteProfile" Content="Fix Errors" HorizontalAlignment="Left" Margin="780.381,200.814,0,0" VerticalAlignment="Top" Width="92.719" Height="23" IsEnabled="False">
            <Button.Effect>
                <DropShadowEffect/>
            </Button.Effect>
        </Button>
        <Label Content="Local Computer Name:" HorizontalAlignment="Left" Margin="473.763,131.665,0,0" VerticalAlignment="Top"/>
        <Label Content="Domain Name:" HorizontalAlignment="Left" Margin="473.763,159.665,0,0" VerticalAlignment="Top"/>
        <Label Name="lbDomainName" Content="" Margin="604.764,158.817,121.815,39.956" Foreground="Black"/>
        <Label Content="USMT Status:" HorizontalAlignment="Left" Margin="473.763,189.764,0,0" VerticalAlignment="Top"/>
        <Label Content="JumpCloud User Name :" HorizontalAlignment="Left" Margin="14.796,134.764,0,0" VerticalAlignment="Top"/>
        <Label Content="Temp Password :" HorizontalAlignment="Left" Margin="14.796,162.764,0,0" VerticalAlignment="Top"/>
        <Label Content="JumpCloud Connect Key :" HorizontalAlignment="Left" Margin="13.796,191.764,0,0" VerticalAlignment="Top" AutomationProperties.HelpText="https://console.jumpcloud.com/#/systems/new" ToolTip="https://console.jumpcloud.com/#/systems/new"/>
        <TextBox Name="tbJumpCloudUserName" HorizontalAlignment="Left" Height="23" Margin="158.818,136.764,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="301.026" Text="Enter JumpCloud UserName Here" Background="#FFF30000" FontWeight="Bold" />
        <TextBox Name="tbTempPassword" HorizontalAlignment="Left" Height="23" Margin="158.818,165.764,0,0" TextWrapping="Wrap" Text="Temp123!" VerticalAlignment="Top" Width="301.026"/>
        <TextBox Name="tbJumpCloudConnectKey" HorizontalAlignment="Left" Height="23" Margin="158.818,193.764,0,0" TextWrapping="Wrap" Text="Enter JumpCloud Connect Key" VerticalAlignment="Top" Width="301.026" Background="Red" FontWeight="Bold"/>
        <Label Content="Label" HorizontalAlignment="Left" Margin="301.285,512.775,0,0" VerticalAlignment="Top"/>
        <Label Name="lbComputerName" Content="" HorizontalAlignment="Left" Margin="604.764,130.817,0,0" VerticalAlignment="Top" Width="166.021"/>
        <Label Content="Label" HorizontalAlignment="Left" Margin="675.367,441.755,0,0" VerticalAlignment="Top"/>
        <Label Name="lbusmtStatus" Content="" HorizontalAlignment="Left" Margin="604.764,187.444,0,0" VerticalAlignment="Top" Width="165.621"/>
        <GroupBox Header="Accept EULA" HorizontalAlignment="Left" Height="73.99" Margin="780.381,124.454,0,0" VerticalAlignment="Top" Width="92.719">
            <StackPanel Name="spaccepteula" HorizontalAlignment="Left" Height="36.126" Margin="5.249,17.084,0,-1.21" VerticalAlignment="Top" Width="54.895" RenderTransformOrigin="0.5,0.5">
                <StackPanel.RenderTransform>
                    <TransformGroup>
                        <ScaleTransform/>
                        <SkewTransform AngleX="-1.233"/>
                        <RotateTransform/>
                        <TranslateTransform X="-0.699"/>
                    </TransformGroup>
                </StackPanel.RenderTransform>
                <RadioButton Name="rb_accepteula" Content="True" IsChecked="True"/>
                <RadioButton Name="rb_notaccepteula" Content="False"/>
            </StackPanel>
        </GroupBox>
        <Label Name="lbMoreInfo" Content="More Info" HorizontalAlignment="Left" Margin="793.381,132.715,0,0" VerticalAlignment="Top" Width="65.381" FontSize="11" FontWeight="Bold" FontStyle="Italic" Foreground="#FF005DFF"/>
    </Grid>
</Window>
'@
  #Read XAML

  $reader = (New-Object System.Xml.XmlNodeReader $xaml)
  try {$Form = [Windows.Markup.XamlReader]::Load( $reader )}
  catch {Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}

  #===========================================================================
  # Store Form Objects In PowerShell
  #===========================================================================

  $xaml.SelectNodes("//*[@Name]") | % {Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

  ##set labels and vars on load

  #Check PartOfDomain & Disable Controls
  if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
    $domainname = (Get-WmiObject win32_computersystem).Domain
  }
  else {
    $domainname = "Not Domain Joined"
    $bDeleteProfile.Content = "No Domain"
    $bDeleteProfile.IsEnabled = $false
    $tbJumpCloudConnectKey.IsEnabled = $false
    $tbJumpCloudUserName.IsEnabled = $false
    $tbTempPassword.IsEnabled = $false
    $lvProfileList.IsEnabled = $false
    $spaccepteula.IsEnabled = $false
    $lbDomainName.FontWeight = "Bold"
    $lbDomainName.Foreground = "Red"
  }

  #$netbiosname = $domainname.Substring(0, $domainname.IndexOf('.'))
  $localcomputername = (Get-WmiObject Win32_ComputerSystem).Name
  $adksetuppath = 'C:\windows\Temp\JCAD\'
  $adksetupfile = 'adksetup.exe'
  $usmtstatus = (Test-Path 'C:\adk\Assessment and Deployment Kit\User State Migration Tool\')
  $lbDomainName.Content = $domainname
  $lbComputerName.Content = $localcomputername
  $lbusmtStatus.Content = $usmtstatus

  #!([string]::IsNullOrEmpty($field))

  Function Validate-button {
    if (($tbJumpCloudUserName_valid -and $tbJumpCloudConnectKey_valid -and $tbTempPassword_valid) -eq $true -and ($lvProfileList.SelectedItems -ne $null)) {
      $bDeleteProfile.Content = "Migrate Profile"
      $bDeleteProfile.IsEnabled = "true"
    }
    elseif (($tbJumpCloudUserName_valid -and $tbJumpCloudConnectKey_valid -and $tbTempPassword_valid) -eq $false -and ($lvProfileList.SelectedItems -ne $null)) {
      $bDeleteProfile.Content = "Correct Errors"
      $bDeleteProfile.IsEnabled = $false
    }
    else {
      $bDeleteProfile.Content = "Select Profile"
      $bDeleteProfile.IsEnabled = $false
    }
  }

  #validation
  function Validate-IsNotEmpty ([string] $field) {
    If (([System.String]::IsNullOrEmpty($field))) {
      return $true
    }
    else {
      return $false
    }
  }

  function Validate-Is40chars ([string] $field) {
    if ($field.Length -eq 40) {
      return $true
    }
    return $false
  }

  function Validate-HasNoSpaces ([string] $field) {
    if ($field -like "* *") {
      return $false
    }
    return $true
  }

  Function Get-ProfileList {
    #get list of profiles from computer
    $Profiles = Get-wmiobject -Class Win32_UserProfile -Property * | Where-Object {$_.Special -eq $false} | Add-Member -MemberType ScriptProperty -Name UserName -Value { (New-Object System.Security.Principal.SecurityIdentifier($this.Sid)).Translate([System.Security.Principal.NTAccount]).Value } -PassThru | Select-Object Username, RoamingConfigured, Loaded, @{Name = "LastLogin"; EXPRESSION = {$_.ConvertToDateTime($_.lastusetime)}}
    $lvPorfileListOutput = $Profiles | % {$lvProfileList.Items.Add($_)} #put the list of profiles in the profile box
  }

  ##Form changes & interactions

  #EULA radio button event handler
  [System.Windows.RoutedEventHandler]$ChoosedRadioHandler = {
    if ($_.source.content -eq "False") {
      $script:AcceptEULA = $false
    }
    else {
      $script:AcceptEULA = $true
    }
  }
  $spaccepteula.AddHandler([System.Windows.Controls.RadioButton]::CheckedEvent, $ChoosedRadioHandler)
  $tbJumpCloudUserName.add_TextChanged( {
      $script:tbJumpCloudUserName_valid = !(Validate-IsNotEmpty $tbJumpCloudUserName.Text) -and (Validate-HasNoSpaces $tbJumpCloudUserName.Text)
      Validate-button
      if ($tbJumpCloudUserName_valid -eq $false) {
        $tbJumpCloudUserName.Background = "red"
        $tbJumpCloudUserName.Tooltip = "JumpCloud User Name Can't Be Empty Or Contain Spaces"
      }
      else {
        $tbJumpCloudUserName.Background = "white"
        $tbJumpCloudUserName.Tooltip = $null
        $tbJumpCloudUserName.FontWeight = "Normal"
        $script:JumpCloudUserName = $tbJumpCloudUserName.Text
      }
    })

  $tbJumpCloudConnectKey.add_TextChanged( {
      $script:tbJumpCloudConnectKey_valid = (Validate-Is40chars $tbJumpCloudConnectKey.Text) -and (Validate-HasNoSpaces $tbJumpCloudConnectKey.Text)
      Validate-button
      if ($tbJumpCloudConnectKey_valid -eq $false) {
        $tbJumpCloudConnectKey.Background = "red"
        $tbJumpCloudConnectKey.Tooltip = "Connect Key Must be 40chars & Not Contain Spaces"
      }
      else {
        $tbJumpCloudConnectKey.Background = "white"
        $tbJumpCloudConnectKey.Tooltip = $null
        $tbJumpCloudConnectKey.FontWeight = "Normal"
        $script:JumpCloudConnectKey = $tbJumpCloudConnectKey.Text
      }
    })

  $tbTempPassword.add_TextChanged( {
      $script:tbTempPassword_valid = !(Validate-IsNotEmpty $tbTempPassword.Text) -and (Validate-HasNoSpaces $tbTempPassword.Text)
      Validate-button
      if ($tbTempPassword_valid -eq $false) {
        $tbTempPassword.Background = "red"
        $tbTempPassword.Tooltip = "Connect Key Must Be 40chars & No spaces"
      }
      else {
        $tbTempPassword.Background = "white"
        $tbTempPassword.Tooltip = $null
        $tbTempPassword.FontWeight = "Normal"
        $script:TempPassword = $tbTempPassword.Text
      }
    })

  #change button when profile selected
  $lvProfileList.Add_SelectionChanged( {
      $selectedusername = ($lvProfileList.SelectedItems.UserName)
      $script:DomainUserName = $selectedusername.Substring($selectedusername.IndexOf('\') + 1)
      Validate-button
    })

  #AcceptEULA moreinfo link - Mouse button event
  $lbMoreInfo.Add_PreviewMouseDown( {[system.Diagnostics.Process]::start('https://github.com/TheJumpCloud/support/wiki')})

  $bDeleteProfile.Add_Click( {
      #close form
      $Form.close()
      $jcadmupath = "$PSScriptRoot\jcadmu.ps1"
      $args = "-noexit -File $jcadmupath -DomainUserName $DomainUsername -JumpCloudUserName $JumpCloudUserName -TempPassword $TempPassword -JumpCloudConnectKey $JumpCloudConnectKey -acceptEULA $acceptEULA"
      Start-Process -FilePath:('PowerShell.exe') -ArgumentList:( $args ) -PassThru
    })

  #Load profilelist into listview
  Get-ProfileList

  $script:TempPassword = $tbTempPassword.Text
  $script:AcceptEULA = $true
  $script:tbTempPassword_valid = $true

  #===========================================================================
  # Shows the form
  #===========================================================================
  $Form.Showdialog() | out-null


  return $FormResults

}
#endregion

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
