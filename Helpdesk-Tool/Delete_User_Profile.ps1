<#
.SYNOPSIS
    Interactive GUI User Profile Cleanup Tool for Software Center / Non-Admin Techs.
    Resized and optimized with extra-large profile username fonts.
#>

# Enable High-DPI Auto-scaling so the GUI scales properly on high-res displays
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()


# Whitelisted system accounts
$ExcludedUsers = @("Administrator", "Public", "Default", "Setup", "llopez")
$LoggedOnUser = (Get-CimInstance Win32_ComputerSystem).UserName

if ($LoggedOnUser) {
    $LoggedOnUser = $LoggedOnUser.Split('\')[-1]
    $ExcludedUsers += $LoggedOnUser

    Write-Host "Logged On User: '$LoggedOnUser'"
}

# 1. Fetch available non-special, non-loaded user profiles
$Profiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object {
    $_.Special -eq $false -and 
    $_.Loaded -eq $false
}

$ProfileList = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($P in $Profiles) {
    try {
        $Account = (New-Object System.Security.Principal.SecurityIdentifier($P.SID)).Translate([System.Security.Principal.NTAccount]).Value
        $UserName = $Account.Split('\')[-1]
        Write-Host "Found User: '$UserName'"      
    } catch {
        $UserName = Split-Path $P.LocalPath -Leaf
    }

    if ($ExcludedUsers -notcontains $UserName) {
        $LastUse = if ($P.LastUseTime) { $P.LastUseTime.ToString("yyyy-MM-dd") } else { "Unknown" }
        $ProfileList.Add([PSCustomObject]@{
            UserName    = $UserName
            LastUsed    = $LastUse
            CimObject   = $P
            DisplayText = "$UserName  (Last Used: $LastUse)"
        })
    }
}

if ($ProfileList.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show(
    "No removable user profiles found on this machine.",
    "User Profile Cleanup",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information,
    [System.Windows.Forms.MessageBoxDefaultButton]::Button1,
    [System.Windows.Forms.MessageBoxOptions]::ServiceNotification
)
    exit
}

# 2. Build Resizable GUI Window
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "User Profile Cleanup Tool"
$Form.Size = New-Object System.Drawing.Size(650, 600)
$Form.MinimumSize = New-Object System.Drawing.Size(550, 500)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "Sizable"
$Form.AutoScaleMode = "Dpi"

# Font definitions
$BaseFont    = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$HeaderFont  = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$ListFont    = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold) # Enlarged List Font

$Form.Font = $BaseFont

# Header Label
$Label = New-Object System.Windows.Forms.Label
$Label.Location = New-Object System.Drawing.Point(20, 15)
$Label.Size = New-Object System.Drawing.Size(590, 30)
$Label.Font = $HeaderFont
$Label.Text = "Select an action or pick specific profiles to remove:"
$Label.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$Form.Controls.Add($Label)

# Radio Option: Specific Profile
$RadioSingle = New-Object System.Windows.Forms.RadioButton
$RadioSingle.Location = New-Object System.Drawing.Point(25, 55)
$RadioSingle.Size = New-Object System.Drawing.Size(300, 25)
$RadioSingle.Text = "Delete selected profile(s)"
$RadioSingle.Checked = $true
$RadioSingle.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$Form.Controls.Add($RadioSingle)

# Profile List Box (Enlarged Font & Row Spacing)
$ListBox = New-Object System.Windows.Forms.ListBox
$ListBox.Location = New-Object System.Drawing.Point(45, 90)
$ListBox.Size = New-Object System.Drawing.Size(540, 280)
$ListBox.Font = $ListFont
$ListBox.ItemHeight = 26 # Gives extra breathing room between large text rows
$ListBox.SelectionMode = "MultiExtended"
$ListBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
foreach ($Item in $ProfileList) {
    [void]$ListBox.Items.Add($Item.DisplayText)
}
$Form.Controls.Add($ListBox)

# Radio Option: Delete ALL Profiles
$RadioAll = New-Object System.Windows.Forms.RadioButton
$RadioAll.Location = New-Object System.Drawing.Point(25, 395)
$RadioAll.Size = New-Object System.Drawing.Size(350, 25)
$RadioAll.Text = "Delete ALL inactive user profiles"
$RadioAll.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
$Form.Controls.Add($RadioAll)

# Enable/Disable ListBox based on radio selection
$RadioSingle.Add_CheckedChanged({
    $ListBox.Enabled = $RadioSingle.Checked
})

# Delete Button
$BtnDelete = New-Object System.Windows.Forms.Button
$BtnDelete.Location = New-Object System.Drawing.Point(360, 480)
$BtnDelete.Size = New-Object System.Drawing.Size(110, 38)
$BtnDelete.Text = "Delete"
$BtnDelete.DialogResult = [System.Windows.Forms.DialogResult]::OK
$BtnDelete.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$Form.Controls.Add($BtnDelete)

# Cancel Button
$BtnCancel = New-Object System.Windows.Forms.Button
$BtnCancel.Location = New-Object System.Drawing.Point(480, 480)
$BtnCancel.Size = New-Object System.Drawing.Size(110, 38)
$BtnCancel.Text = "Cancel"
$BtnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$BtnCancel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$Form.Controls.Add($BtnCancel)

# Force form to the front
$Form.TopMost = $true

# Show Dialog
$Result = $Form.ShowDialog()

# 3. Process Execution
if ($Result -eq [System.Windows.Forms.DialogResult]::OK) {
    $TargetsToDelete = @()

    if ($RadioAll.Checked) {
        $Confirm = [System.Windows.Forms.MessageBox]::Show(
    $Form,
    "Are you sure you want to delete ALL inactive profiles?",
    "Confirm Bulk Delete",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Warning
)
        if ($Confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            $TargetsToDelete = $ProfileList
        }
    } else {
        foreach ($SelectedIndex in $ListBox.SelectedIndices) {
            $TargetsToDelete += $ProfileList[$SelectedIndex]
        }
    }

    if ($TargetsToDelete.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
        $Form,
        "No profiles were selected for deletion.", 
        "Cancelled", 
        [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }

    # Execute Deletions
    $SuccessCount = 0
    foreach ($Target in $TargetsToDelete) {
        try {
            Remove-CimInstance -InputObject $Target.CimObject -ErrorAction Stop
            $SuccessCount++
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
            $Form,
            "Failed to delete $($Target.UserName): $_", 
            "Error", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }

    [System.Windows.Forms.MessageBox]::Show(
    $Form,
    "Successfully removed $SuccessCount profile(s).", 
    "Complete", 
    [System.Windows.Forms.MessageBoxButtons]::OK, 
    [System.Windows.Forms.MessageBoxIcon]::Information)
}