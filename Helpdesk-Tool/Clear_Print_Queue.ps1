# Save as: Printer Tools\Clear_Spooler\Clear-Spooler-GUI.ps1
# Requires Administrator Rights

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Dialog Form (800x350)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Print Queue Management Utility"
$form.Size = New-Object System.Drawing.Size(800, 350)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Force window to top of all open windows
$form.TopMost = $true

# Label (AutoSize $true ensures text is never vertically clipped)
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(25, 20)
$label.Size = New-Object System.Drawing.Size(730, 35)
$label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$label.Text = "Select a printer queue to clear:"
$label.AutoSize = $false
$form.Controls.Add($label)

# Warning Label
$lblNote = New-Object System.Windows.Forms.Label
$lblNote.Location = New-Object System.Drawing.Point(25, 55)
$lblNote.Size = New-Object System.Drawing.Size(730, 20)
$lblNote.ForeColor = [System.Drawing.Color]::Red
$lblNote.Text = "* Displays queues managed by the local print spooler service."
$form.Controls.Add($lblNote)

# Dropdown List (Shifted down to Y = 65 to give label full clearance)
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(25, 85)
$comboBox.Size = New-Object System.Drawing.Size(730, 45)
$comboBox.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$comboBox.DropDownStyle = "DropDownList"

# Fetch installed printers
$printers = Get-Printer | Select-Object Name, JobCount
foreach ($p in $printers) {
    $comboBox.Items.Add("$($p.Name) ($($p.JobCount) jobs pending)") | Out-Null
}
if ($comboBox.Items.Count -gt 0) { $comboBox.SelectedIndex = 0 }
$form.Controls.Add($comboBox)

# Button 1: Clear Selected Queue (Shifted to Y = 160)
$btnClearSelected = New-Object System.Windows.Forms.Button
$btnClearSelected.Location = New-Object System.Drawing.Point(25, 180)
$btnClearSelected.Size = New-Object System.Drawing.Size(355, 55)
$btnClearSelected.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnClearSelected.Text = "Clear Selected Queue"
$btnClearSelected.Add_Click({
    if ($comboBox.SelectedIndex -ge 0) {
        $targetPrinter = $printers[$comboBox.SelectedIndex].Name
        Get-PrintJob -PrinterName $targetPrinter -ErrorAction SilentlyContinue | Remove-PrintJob -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show("Queue cleared for '$targetPrinter'.", "Success", "OK", "Information")
        $form.Close()
    }
})
$form.Controls.Add($btnClearSelected)

# Button 2: Purge ALL Queues (Shifted to Y = 160)
$btnClearAll = New-Object System.Windows.Forms.Button
$btnClearAll.Location = New-Object System.Drawing.Point(400, 180)
$btnClearAll.Size = New-Object System.Drawing.Size(355, 55)
$btnClearAll.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnClearAll.Text = "Clear ALL Queues"
$btnClearAll.Add_Click({
    Stop-Service -Name "Spooler" -Force
    Start-Sleep -Seconds 2
    Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue
    Start-Service -Name "Spooler"
    [System.Windows.Forms.MessageBox]::Show("All spooler queues cleared successfully!", "Success", "OK", "Information")
    $form.Close()
})
$form.Controls.Add($btnClearAll)

# Force activation to jump in front of ISE/Explorer
$form.Add_Shown({ $form.Activate() })

# Show Dialog
$form.ShowDialog() | Out-Null