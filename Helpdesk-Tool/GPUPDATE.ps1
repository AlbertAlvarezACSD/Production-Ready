<#
.SYNOPSIS
    Updates Group Policies and presents a custom, click-safe GUI to the user.
#>

# 1. Update Computer Policies silently
$CompResult = cmd.exe /c "gpupdate /target:computer /force" 2>&1 | Out-String

# Check for true failures (ignoring MDM warnings)
$HasError = $false
$ErrorDetails = ""

if ($CompResult -match "Computer Policy update failed" -or $CompResult -match "The processing of Group Policy failed") {
    $HasError = $true
    $ErrorDetails += "--- Computer Policy Output ---`n$CompResult`n"
}

# 2. Get currently logged-in user and update User Policies silently (echo N prevents hanging prompts)
$ExplorerProcess = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'explorer.exe'" | Select-Object -First 1

if ($ExplorerProcess) {
    $Owner = Invoke-CimMethod -InputObject $ExplorerProcess -MethodName "GetOwner"
    $DomainUser = "$($Owner.Domain)\$($Owner.User)"

    if ($Owner.User) {
        $TaskName = "User_GPUpdate_Task"
        # "echo N |" automatically inputs 'N' if Windows asks to log off, preventing script hangs
        $Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c echo N | gpupdate /target:user /force"
        $Principal = New-ScheduledTaskPrincipal -UserId $DomainUser -LogonType Interactive
        
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Principal $Principal -Force | Out-Null
        Start-ScheduledTask -TaskName $TaskName
        
        Start-Sleep -Seconds 8
        
        $TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($TaskExists) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false | Out-Null
        }
    }
}

# 3. GUI Handling
Add-Type -AssemblyName PresentationFramework

if ($HasError) {
    # Failure Popup
    $Message = "Group Policy update encountered a critical issue and could not complete.`n`nPlease contact the Helpdesk for assistance.`n`nDetails:`n$ErrorDetails"
    [System.Windows.MessageBox]::Show($Message, "Group Policy Update - Failure", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
} 
else {
    # 4. Custom WPF GUI Window with Explicit Buttons
    [xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Group Policy Update Complete" Height="220" Width="460"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Topmost="True">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row="0" Text="Group Policy has finished updating successfully!" FontSize="14" FontWeight="Bold" Foreground="#005A9E"/>
        
        <TextBlock Grid.Row="1" Text="Some policy changes require a Restart or Log Off to take full effect. Please select how you would like to proceed:" 
                   TextWrapping="Wrap" Margin="0,10,0,10" VerticalAlignment="Center"/>
        
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button Name="BtnRestart" Content="Restart Now" Width="100" Height="30" Margin="5,0,5,0" Background="#0078D4" Foreground="White" FontWeight="Bold"/>
            <Button Name="BtnLogoff" Content="Log Off Now" Width="100" Height="30" Margin="5,0,5,0"/>
            <Button Name="BtnLater" Content="I'll Do It Later" Width="100" Height="30" Margin="5,0,0,0"/>
        </StackPanel>
    </Grid>
</Window>
"@

    # Load XAML
    $Reader = (New-Object System.Xml.XmlNodeReader $XAML)
    $Window = [Windows.Markup.XamlReader]::Load($Reader)

    # Bind Buttons
    $BtnRestart = $Window.FindName("BtnRestart")
    $BtnLogoff  = $Window.FindName("BtnLogoff")
    $BtnLater   = $Window.FindName("BtnLater")

    # Button Actions
    $BtnRestart.Add_Click({
        $Window.Close()
        shutdown.exe /r /t 30 /c "Group Policy Update requested a system restart."
    })

    $BtnLogoff.Add_Click({
        $Window.Close()
        shutdown.exe /l
    })

    $BtnLater.Add_Click({
        $Window.Close()
    })

    # Show Custom Window
    $null = $Window.ShowDialog()
}