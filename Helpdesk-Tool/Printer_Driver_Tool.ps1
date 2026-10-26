Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Printer Maintenance Utility"
$form.Size = New-Object System.Drawing.Size(1000,450)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

# Printer Label

$lblPrinter = New-Object System.Windows.Forms.Label
$lblPrinter.Location = New-Object System.Drawing.Point(20,20)
$lblPrinter.Size = New-Object System.Drawing.Size(220,25)
$lblPrinter.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$lblPrinter.Text = "Select Printer:"

# Printer Dropdown

$cmbPrinter = New-Object System.Windows.Forms.ComboBox
$cmbPrinter.Location = New-Object System.Drawing.Point(290,20)
$cmbPrinter.Size = New-Object System.Drawing.Size(650,35)
$cmbPrinter.DropDownStyle = "DropDownList"
$cmbPrinter.Font = New-Object System.Drawing.Font("Segoe UI",13)
$cmbPrinter.IntegralHeight = $false
$cmbPrinter.DropDownHeight = 250

# Current Driver

$lblCurrentDriverTitle = New-Object System.Windows.Forms.Label
$lblCurrentDriverTitle.Location = New-Object System.Drawing.Point(20,80)
$lblCurrentDriverTitle.Size = New-Object System.Drawing.Size(220,25)
$lblCurrentDriverTitle.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$lblCurrentDriverTitle.Text = "Current Driver:"

$lblCurrentDriver = New-Object System.Windows.Forms.Label
$lblCurrentDriver.Location = New-Object System.Drawing.Point(290,80)
$lblCurrentDriver.Size = New-Object System.Drawing.Size(650,40)
$lblCurrentDriver.Font = New-Object System.Drawing.Font("Segoe UI",10)

# New Driver

$lblNewDriver = New-Object System.Windows.Forms.Label
$lblNewDriver.Location = New-Object System.Drawing.Point(20,140)
$lblNewDriver.Size = New-Object System.Drawing.Size(240,25)
$lblNewDriver.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$lblNewDriver.Text = "New Driver (Optional):"

$cmbDriver = New-Object System.Windows.Forms.ComboBox
$cmbDriver.Location = New-Object System.Drawing.Point(290,140)
$cmbDriver.Size = New-Object System.Drawing.Size(650,35)
$cmbDriver.DropDownStyle = "DropDownList"
$cmbDriver.Font = New-Object System.Drawing.Font("Segoe UI",13)
$cmbDriver.IntegralHeight = $false
$cmbDriver.DropDownHeight = 250

# Rename Printer

$lblRename = New-Object System.Windows.Forms.Label
$lblRename.Location = New-Object System.Drawing.Point(20,200)
$lblRename.Size = New-Object System.Drawing.Size(270,25)
$lblRename.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$lblRename.Text = "Rename Printer (Optional):"

$txtRename = New-Object System.Windows.Forms.TextBox
$txtRename.Location = New-Object System.Drawing.Point(290,200)
$txtRename.Size = New-Object System.Drawing.Size(650,35)
$txtRename.Font = New-Object System.Drawing.Font("Segoe UI",13)

# Apply Changes Button

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Location = New-Object System.Drawing.Point(290,285)
$btnApply.Size = New-Object System.Drawing.Size(200,50)
$btnApply.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnApply.Text = "Apply Changes"

# Refresh Button

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Location = New-Object System.Drawing.Point(530,285)
$btnRefresh.Size = New-Object System.Drawing.Size(200,50)
$btnRefresh.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnRefresh.Text = "Refresh Printers"

$btnApply.Add_Click({

    if (-not $cmbPrinter.SelectedItem)
    {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            "Please select a printer.",
            "Printer Maintenance"
        )
        return
    }

    try
    {
        $PrinterName    = $cmbPrinter.SelectedItem
        $CurrentDriver  = (Get-Printer -Name $PrinterName).DriverName
        $SelectedDriver = $cmbDriver.SelectedItem
        $NewName        = $txtRename.Text.Trim()

        $DriverChangeRequested = (
            $cmbDriver.SelectedIndex -gt 0 -and
            $SelectedDriver -ne $CurrentDriver
        )

        $RenameRequested = -not [string]::IsNullOrWhiteSpace($NewName)

        if (-not $DriverChangeRequested -and -not $RenameRequested)
        {
            [System.Windows.Forms.MessageBox]::Show(
                $form,
                "Select a different driver and/or enter a new printer name.",
                "No Changes Specified",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            return
        }

        if ($RenameRequested)
        {
            if ($NewName -eq $PrinterName)
            {
                [System.Windows.Forms.MessageBox]::Show(
                    $form,
                    "The new printer name matches the existing printer name.",
                    "Rename Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                return
            }

            if (Get-Printer -Name $NewName -ErrorAction SilentlyContinue)
            {
                [System.Windows.Forms.MessageBox]::Show(
                    $form,
                    "A printer named '$NewName' already exists.",
                    "Rename Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
                return
            }
        }

        $Summary = @()
        $Summary += "Printer: $PrinterName"
        $Summary += ""

        if ($DriverChangeRequested)
        {
            $Summary += "Driver Change:"
            $Summary += "  From: $CurrentDriver"
            $Summary += "  To:   $SelectedDriver"
            $Summary += ""
        }

        if ($RenameRequested)
        {
            $Summary += "Rename:"
            $Summary += "  From: $PrinterName"
            $Summary += "  To:   $NewName"
        }

        $Confirm = [System.Windows.Forms.MessageBox]::Show(
            $form,
            ($Summary -join "`r`n"),
            "Confirm Changes",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($Confirm -ne [System.Windows.Forms.DialogResult]::Yes)
        {
            return
        }

        if ($DriverChangeRequested)
        {
            Start-Process powershell.exe `
                -WindowStyle Hidden `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Printer -Name '$PrinterName' -DriverName '$SelectedDriver'`"" `
                -Wait

            Start-Sleep -Seconds 2
        }

        if ($RenameRequested)
        {
            Start-Process powershell.exe `
                -WindowStyle Hidden `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Rename-Printer -Name '$PrinterName' -NewName '$NewName'`"" `
                -Wait

            $PrinterName = $NewName
        }

        $Success = @()
        $Success += "Changes completed successfully."
        $Success += ""

        if ($DriverChangeRequested)
        {
            $Success += "Driver changed to:"
            $Success += $SelectedDriver
            $Success += ""
        }

        if ($RenameRequested)
        {
            $Success += "Printer renamed to:"
            $Success += $NewName
            $Success += ""
            $Success += "Click Refresh Printers to update the list."
        }

        $form.TopMost = $true
        $form.Activate()

        [System.Windows.Forms.MessageBox]::Show(
            $form,
            ($Success -join "`r`n"),
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        $cmbDriver.SelectedIndex = 0
        $txtRename.Clear()
    }
    catch
    {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            ($_ | Out-String),
            "FULL ERROR",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

$btnRefresh.Add_Click({

    try
    {
        $cmbPrinter.Items.Clear()

        $Printers = Get-Printer |
            Where-Object {
                $_.Name -notlike "\\*"
            } |
            Sort-Object Name

        foreach ($Printer in $Printers) 
        {
            $cmbPrinter.Items.Add($Printer.Name) | Out-Null
        }

        if ($cmbPrinter.Items.Count -gt 0)
        {
            $cmbPrinter.SelectedIndex = 0
        }
    }
    catch
    {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            ($_ | Out-String),
            "Refresh Failed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }

})

# Local Printers

$Printers = Get-Printer |
    Where-Object {
        $_.Name -notlike "\\*"
    } |
    Sort-Object Name

foreach ($Printer in $Printers)
{
    $cmbPrinter.Items.Add($Printer.Name) | Out-Null
}

# Installed Drivers

$cmbDriver.Items.Add("< No Driver Change >") | Out-Null

$Drivers = Get-PrinterDriver | Sort-Object Name

foreach ($Driver in $Drivers)
{
    $cmbDriver.Items.Add($Driver.Name) | Out-Null
}

$cmbDriver.SelectedIndex = 0

# Update Current Driver

$cmbPrinter.Add_SelectedIndexChanged({

    if ($cmbPrinter.SelectedItem)
    {
        $SelectedPrinter = Get-Printer -Name $cmbPrinter.SelectedItem
        $lblCurrentDriver.Text = $SelectedPrinter.DriverName
    }

})

# Initial Driver Display

if ($cmbPrinter.Items.Count -gt 0)
{
    $cmbPrinter.SelectedIndex = 0

    $SelectedPrinter = Get-Printer -Name $cmbPrinter.SelectedItem
    $lblCurrentDriver.Text = $SelectedPrinter.DriverName
}

# Controls

$form.Controls.Add($lblPrinter)
$form.Controls.Add($cmbPrinter)

$form.Controls.Add($lblCurrentDriverTitle)
$form.Controls.Add($lblCurrentDriver)

$form.Controls.Add($lblNewDriver)
$form.Controls.Add($cmbDriver)

$form.Controls.Add($lblRename)
$form.Controls.Add($txtRename)

$form.Controls.Add($btnApply)
$form.Controls.Add($btnRefresh)

$form.Add_Shown({
    $form.Activate()
    $form.TopMost = $true
})

$form.ShowDialog() | Out-Null