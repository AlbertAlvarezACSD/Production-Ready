Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Change Printer Driver"
$form.Size = New-Object System.Drawing.Size(650,350)
$form.StartPosition = "CenterScreen"

$form.TopMost = $true
$form.Activate()

# Printer Label

$lblPrinter = New-Object System.Windows.Forms.Label
$lblPrinter.Location = New-Object System.Drawing.Point(20,20)
$lblPrinter.Size = New-Object System.Drawing.Size(160,25)
$lblPrinter.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$lblPrinter.Text = "Select Printer:"

# Printer Dropdown

$cmbPrinter = New-Object System.Windows.Forms.ComboBox
$cmbPrinter.Location = New-Object System.Drawing.Point(190,20)
$cmbPrinter.Size = New-Object System.Drawing.Size(400,30)
$cmbPrinter.DropDownStyle = "DropDownList"
$cmbPrinter.Font = New-Object System.Drawing.Font("Segoe UI",13)
$cmbPrinter.IntegralHeight = $false
$cmbPrinter.DropDownHeight = 250

# Current Driver Label

$lblCurrentDriverTitle = New-Object System.Windows.Forms.Label
$lblCurrentDriverTitle.Location = New-Object System.Drawing.Point(20,80)
$lblCurrentDriverTitle.Size = New-Object System.Drawing.Size(160,25)
$lblCurrentDriverTitle.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$lblCurrentDriverTitle.Text = "Current Driver:"

$lblCurrentDriver = New-Object System.Windows.Forms.Label
$lblCurrentDriver.Location = New-Object System.Drawing.Point(190,80)
$lblCurrentDriver.Size = New-Object System.Drawing.Size(420,40)
$lblCurrentDriver.Font = New-Object System.Drawing.Font("Segoe UI",10)

# New Driver Label

$lblNewDriver = New-Object System.Windows.Forms.Label
$lblNewDriver.Location = New-Object System.Drawing.Point(20,140)
$lblNewDriver.Size = New-Object System.Drawing.Size(160,25)
$lblNewDriver.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$lblNewDriver.Text = "New Driver:"

# Driver Dropdown

$cmbDriver = New-Object System.Windows.Forms.ComboBox
$cmbDriver.Location = New-Object System.Drawing.Point(190,140)
$cmbDriver.Size = New-Object System.Drawing.Size(400,30)
$cmbDriver.DropDownStyle = "DropDownList"
$cmbDriver.Font = New-Object System.Drawing.Font("Segoe UI",13)
$cmbDriver.IntegralHeight = $false
$cmbDriver.DropDownHeight = 250

# Change Driver Button

$btnChangeDriver = New-Object System.Windows.Forms.Button
$btnChangeDriver.Location = New-Object System.Drawing.Point(240,220)
$btnChangeDriver.Size = New-Object System.Drawing.Size(180,45)
$btnChangeDriver.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnChangeDriver.Text = "Change Driver"

$btnChangeDriver.Add_Click({

    if (-not $cmbPrinter.SelectedItem)
    {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select a printer.",
            "Change Printer Driver"
        )
        return
    }

    if (-not $cmbDriver.SelectedItem)
    {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select a driver.",
            "Change Printer Driver"
        )
        return
    }

    $CurrentDriver = (Get-Printer -Name $cmbPrinter.SelectedItem).DriverName

    if ($CurrentDriver -eq $cmbDriver.SelectedItem)
    {
        [System.Windows.Forms.MessageBox]::Show(
            "The selected printer is already using that driver.",
            "No Change Required"
        )
        return
    }

    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Change driver for:`r`n`r`n$($cmbPrinter.SelectedItem)`r`n`r`nFrom:`r`n$CurrentDriver`r`n`r`nTo:`r`n$($cmbDriver.SelectedItem)",
        "Confirm Driver Change",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

if ($Result -eq [System.Windows.Forms.DialogResult]::Yes)
{

try
{
    $PrinterName = $cmbPrinter.SelectedItem
$DriverName  = $cmbDriver.SelectedItem

Start-Process powershell.exe `
    -WindowStyle Hidden `
    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Printer -Name '$PrinterName' -DriverName '$DriverName'`""

 [System.Windows.Forms.MessageBox]::Show(
    "The printer driver change has been initiated.`r`n`r`nPrinter:`r`n$PrinterName`r`n`r`nDriver:`r`n$DriverName",
    "Success",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)
 
 $lblCurrentDriver.Text = $cmbDriver.SelectedItem
   
}
 
catch
{
    [System.Windows.Forms.MessageBox]::Show(
        ($_ | Out-String),
        "FULL ERROR"
    )
}

}

})

# Get Local Printers Only

$Printers = Get-Printer |
    Where-Object {
        $_.Type -eq "Local" -and
        $_.Name -notlike "\\*"
    } |
    Sort-Object Name

foreach ($Printer in $Printers)
{
    $cmbPrinter.Items.Add($Printer.Name) | Out-Null
}

# Get Installed Drivers

$Drivers = Get-PrinterDriver | Sort-Object Name

foreach ($Driver in $Drivers)
{
    $cmbDriver.Items.Add($Driver.Name) | Out-Null
}

# Update Current Driver When Printer Changes

$cmbPrinter.Add_SelectedIndexChanged({

    $SelectedPrinter = Get-Printer -Name $cmbPrinter.SelectedItem

    $lblCurrentDriver.Text = $SelectedPrinter.DriverName

})

# Add Controls

$form.Controls.Add($lblPrinter)
$form.Controls.Add($cmbPrinter)

$form.Controls.Add($lblCurrentDriverTitle)
$form.Controls.Add($lblCurrentDriver)

$form.Controls.Add($lblNewDriver)
$form.Controls.Add($cmbDriver)

$form.Controls.Add($btnChangeDriver)

# Show Form



$form.Add_Shown({
    $form.Activate()
    $form.TopMost = $true
})

$form.ShowDialog() | Out-Null