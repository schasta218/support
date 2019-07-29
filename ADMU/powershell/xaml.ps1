# Load functions
. ((Split-Path -Path:($MyInvocation.MyCommand.Path)) + '\Functions.ps1')
# Define misc static variables
$WmiComputerSystem = Get-WmiObject -Class:('Win32_ComputerSystem')
$WmiUserProfile = Get-WmiObject -Class:('Win32_UserProfile') -Property *
$USMTPath = 'C:\adk\Assessment and Deployment Kit\User State Migration Tool\'
$FormResults = [PSCustomObject]@{}
#==============================================================================================
# XAML Code - Imported from Visual Studio WPF Application
#==============================================================================================
[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
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
        <Label Name="lbUSMTStatus" Content="" HorizontalAlignment="Left" Margin="604.764,187.444,0,0" VerticalAlignment="Top" Width="165.621"/>
        <GroupBox Header="Accept EULA" HorizontalAlignment="Left" Height="73.99" Margin="780.381,124.454,0,0" VerticalAlignment="Top" Width="92.719">
            <StackPanel Name="spAcceptEula" HorizontalAlignment="Left" Height="36.126" Margin="5.249,17.084,0,-1.21" VerticalAlignment="Top" Width="54.895" RenderTransformOrigin="0.5,0.5">
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
# Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
Try
{
    $Form = [Windows.Markup.XamlReader]::Load($reader)
}
Catch
{
    Write-Error "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered.";
    Exit;
}
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}
## Set labels and vars on load
# Check PartOfDomain & Disable Controls
If ($WmiComputerSystem.PartOfDomain)
{
    $DomainName = $WmiComputerSystem.Domain
}
Else
{
    $DomainName = "Not Domain Joined"
    $bDeleteProfile.Content = "No Domain"
    $bDeleteProfile.IsEnabled = $false
    $tbJumpCloudConnectKey.IsEnabled = $false
    $tbJumpCloudUserName.IsEnabled = $false
    $tbTempPassword.IsEnabled = $false
    $lvProfileList.IsEnabled = $false
    $spAcceptEula.IsEnabled = $false
    $lbDomainName.FontWeight = "Bold"
    $lbDomainName.Foreground = "Red"
}
$lbDomainName.Content = $DomainName
$lbComputerName.Content = $WmiComputerSystem.Name
$lbUSMTStatus.Content = Test-Path -Path:($USMTPath)
Function Validate-Button
{
    If (($tbJumpCloudUserName_valid -and $tbJumpCloudConnectKey_valid -and $tbTempPassword_valid) -eq $true -and -not [System.String]::IsNullOrEmpty($lvProfileList.SelectedItems.UserName))
    {
        $bDeleteProfile.Content = "Migrate Profile"
        $bDeleteProfile.IsEnabled = $true
    }
    ElseIf (($tbJumpCloudUserName_valid -and $tbJumpCloudConnectKey_valid -and $tbTempPassword_valid) -eq $false -and -not [System.String]::IsNullOrEmpty($lvProfileList.SelectedItems.UserName))
    {
        $bDeleteProfile.Content = "Correct Errors"
        $bDeleteProfile.IsEnabled = $false
    }
    Else
    {
        $bDeleteProfile.Content = "Select Profile"
        $bDeleteProfile.IsEnabled = $false
    }
}
## Form changes & interactions
# EULA radio button event handler
[System.Windows.RoutedEventHandler]$ChooseRadioHandler = {
    $AcceptEULA = If ($_.source.content -eq "False")
    {
        $false
    }
    Else
    {
        $true
    }
}
$spAcceptEula.AddHandler([System.Windows.Controls.RadioButton]::CheckedEvent, $ChooseRadioHandler)
$tbJumpCloudUserName.add_TextChanged( {
        $tbJumpCloudUserName_valid = !(Validate-IsNotEmpty $tbJumpCloudUserName.Text) -and (Validate-HasNoSpaces $tbJumpCloudUserName.Text)
        Validate-Button
        If ($tbJumpCloudUserName_valid -eq $false)
        {
            $tbJumpCloudUserName.Background = "red"
            $tbJumpCloudUserName.Tooltip = "JumpCloud User Name Can't Be Empty Or Contain Spaces"
        }
        Else
        {
            $tbJumpCloudUserName.Background = "white"
            $tbJumpCloudUserName.Tooltip = $null
            $tbJumpCloudUserName.FontWeight = "Normal"
        }
    })
$tbJumpCloudConnectKey.add_TextChanged( {
        $tbJumpCloudConnectKey_valid = (Validate-Is40chars $tbJumpCloudConnectKey.Text) -and (Validate-HasNoSpaces $tbJumpCloudConnectKey.Text)
        Validate-Button
        If ($tbJumpCloudConnectKey_valid -eq $false)
        {
            $tbJumpCloudConnectKey.Background = "red"
            $tbJumpCloudConnectKey.Tooltip = "Connect Key Must be 40chars & Not Contain Spaces"
        }
        Else
        {
            $tbJumpCloudConnectKey.Background = "white"
            $tbJumpCloudConnectKey.Tooltip = $null
            $tbJumpCloudConnectKey.FontWeight = "Normal"
            $JumpCloudConnectKey = $tbJumpCloudConnectKey.Text
        }
    })
$tbTempPassword.add_TextChanged( {
        $tbTempPassword_valid = !(Validate-IsNotEmpty $tbTempPassword.Text) -and (Validate-HasNoSpaces $tbTempPassword.Text)
        Validate-Button
        If ($tbTempPassword_valid -eq $false)
        {
            $tbTempPassword.Background = "red"
            $tbTempPassword.Tooltip = "Connect Key Must Be 40chars & No spaces"
        }
        Else
        {
            $tbTempPassword.Background = "white"
            $tbTempPassword.Tooltip = $null
            $tbTempPassword.FontWeight = "Normal"
            $TempPassword = $tbTempPassword.Text
        }
    })
# Change button when profile selected
$lvProfileList.Add_SelectionChanged( {
        $SelectedUserName = ($lvProfileList.SelectedItem.username)
        $DomainUserName = $SelectedUserName.Substring($SelectedUserName.IndexOf('\') + 1)
        Write-Host $DomainUserName
        Validate-Button
    })
# AcceptEULA moreinfo link - Mouse button event
$lbMoreInfo.Add_PreviewMouseDown( {[System.Diagnostics.Process]::start('https://github.com/TheJumpCloud/support/tree/BS-ADMU-version_1.0.0/ADMU#EULA--Legal-Explanation')})
$bDeleteProfile.Add_Click( {
        # Build FormResults object
        Add-Member -InputObject:($FormResults) -MemberType:('NoteProperty') -Name:('AcceptEula') -Value:($AcceptEula)
        Add-Member -InputObject:($FormResults) -MemberType:('NoteProperty') -Name:('DomainUserName') -Value:($DomainUserName)
        Add-Member -InputObject:($FormResults) -MemberType:('NoteProperty') -Name:('JumpCloudUserName') -Value:($JumpCloudUserName)
        Add-Member -InputObject:($FormResults) -MemberType:('NoteProperty') -Name:('TempPassword') -Value:($TempPassword)
        Add-Member -InputObject:($FormResults) -MemberType:('NoteProperty') -Name:('JumpCloudConnectKey') -Value:($JumpCloudConnectKey)
        # Close form
        $Form.Close()
    })
# Get list of profiles from computer into listview
$Profiles = $WmiUserProfile | Where-Object {$_.Special -eq $false} | Select-Object SID, RoamingConfigured, Loaded, @{Name = "LastLogin"; EXPRESSION = {$_.ConvertToDateTime($_.lastusetime)}}, @{Name = "UserName"; EXPRESSION = {(New-Object System.Security.Principal.SecurityIdentifier($_.SID)).Translate([System.Security.Principal.NTAccount]).Value}; }
# Put the list of profiles in the profile box
$Profiles | ForEach-Object {$lvProfileList.Items.Add($_) | Out-Null}
$TempPassword = $tbTempPassword.Text
#===========================================================================
# Shows the form
#===========================================================================
$Form.Showdialog() | Out-Null
Return $FormResults
