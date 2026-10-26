Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Printer Driver Viewer"
$form.Size = New-Object System.Drawing.Size(750,260)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

$form.Add_Shown({
    $form.Activate()
    $form.BringToFront()
    $form.TopMost = $false
})

# Computer Name Label
$lblComputer = New-Object System.Windows.Forms.Label
$lblComputer.Location = New-Object System.Drawing.Point(20,20)
$lblComputer.AutoSize = $true
$lblComputer.Text = "Computer Name"
$lblComputer.Font = New-Object System.Drawing.Font("Segoe UI",11)

# Computer Name TextBox
$txtComputer = New-Object System.Windows.Forms.TextBox
$txtComputer.Location = New-Object System.Drawing.Point(20,60)
$txtComputer.Size = New-Object System.Drawing.Size(690,35)
$txtComputer.Font = New-Object System.Drawing.Font("Segoe UI",14)

# Get Drivers Button
$btnGetDrivers = New-Object System.Windows.Forms.Button
$btnGetDrivers.Location = New-Object System.Drawing.Point(295,130)
$btnGetDrivers.Size = New-Object System.Drawing.Size(150,45)
$btnGetDrivers.Text = "Get Drivers"
$btnGetDrivers.Font = New-Object System.Drawing.Font("Segoe UI",11)

$form.Controls.Add($lblComputer)
$form.Controls.Add($txtComputer)
$form.Controls.Add($btnGetDrivers)

# Button Click
$btnGetDrivers.Add_Click({

    $ComputerName = $txtComputer.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($ComputerName))
    {
        [System.Windows.Forms.MessageBox]::Show(
            "Please enter a computer name.",
            "Missing Information",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    try
    {
        $Results = @()
        $Results += "Computer: $ComputerName"
        $Results += ""
        $Results += "========================================================="
        $Results += ""

        $Drivers = Get-PrinterDriver |
            Sort-Object Name |
            Select-Object Name, Manufacturer

        foreach ($Driver in $Drivers)
        {
            $Results += ("{0,-65} {1}" -f $Driver.Name, $Driver.Manufacturer)
        }

        $Results = $Results -join "`r`n"

        # Results Form
        $ResultsForm = New-Object System.Windows.Forms.Form
        $ResultsForm.Text = "Printer Drivers - $ComputerName"
        $ResultsForm.Size = New-Object System.Drawing.Size(1400,800)
        $ResultsForm.StartPosition = "CenterScreen"
        $ResultsForm.TopMost = $true

        $ResultsForm.Add_Shown({
            $ResultsForm.Activate()
            $ResultsForm.BringToFront()
            $ResultsForm.TopMost = $false
        })

        # Results Textbox
        $txtResults = New-Object System.Windows.Forms.TextBox
        $txtResults.Multiline = $true
        $txtResults.ReadOnly = $true
        $txtResults.ScrollBars = "Vertical"
        $txtResults.WordWrap = $false
        $txtResults.Dock = "Fill"
        $txtResults.BackColor = [System.Drawing.Color]::White
        $txtResults.Font = New-Object System.Drawing.Font("Consolas",16)

        $txtResults.Text = $Results

        $ResultsForm.Controls.Add($txtResults)

        [void]$ResultsForm.ShowDialog()
    }
    catch
    {
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

[void]$form.ShowDialog()
