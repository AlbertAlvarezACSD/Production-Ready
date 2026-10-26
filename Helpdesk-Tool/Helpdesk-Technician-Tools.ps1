Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --------------------------------------------------
# FORM
# --------------------------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Helpdesk Technician Tools"
$form.Size = New-Object System.Drawing.Size(650,900)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true

# --------------------------------------------------
# TITLE
# --------------------------------------------------

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Location = New-Object System.Drawing.Point(20,20)
$lblTitle.Size = New-Object System.Drawing.Size(600,60)
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)
$lblTitle.Text = "Helpdesk Technician Tools"
$lblTitle.AutoSize = $false
$lblTitle.TextAlign = "BottomLeft"
$form.Controls.Add($lblTitle)

# --------------------------------------------------
# COMPUTER INFO
# --------------------------------------------------

$ComputerName = $env:COMPUTERNAME

try {
    $LoggedInUser = (Get-CimInstance Win32_ComputerSystem).UserName
}
catch {
    $LoggedInUser = "Unknown"
}

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Location = New-Object System.Drawing.Point(20,85)
$lblInfo.Size = New-Object System.Drawing.Size(550,40)
$lblInfo.Text = "Computer: $ComputerName`r`nUser: $LoggedInUser"
$form.Controls.Add($lblInfo)

# --------------------------------------------------
# PRINTING
# --------------------------------------------------

$lblPrinting = New-Object System.Windows.Forms.Label
$lblPrinting.Location = New-Object System.Drawing.Point(20,140)
$lblPrinting.AutoSize = $true
$lblPrinting.Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Bold)
$lblPrinting.Text = "Printing"
$form.Controls.Add($lblPrinting)

# Add Driver

$btnDriver = New-Object System.Windows.Forms.Button
$btnDriver.Location = New-Object System.Drawing.Point(75,190)
$btnDriver.Size = New-Object System.Drawing.Size(220,60)
$btnDriver.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnDriver.Text = "Add Printer Driver"

$btnDriver.Add_Click({

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\Scripts\Printer-tools\Add_Print_Driver.ps1`""

})

$form.Controls.Add($btnDriver)

# Delete Printer

$btnDeletePrinter = New-Object System.Windows.Forms.Button
$btnDeletePrinter.Location = New-Object System.Drawing.Point(330,190)
$btnDeletePrinter.Size = New-Object System.Drawing.Size(220,60)
$btnDeletePrinter.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnDeletePrinter.Text = "Delete Local Printer"

$btnDeletePrinter.Add_Click({

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\Scripts\Printer-tools\Delete_Printer.ps1`""

})

$form.Controls.Add($btnDeletePrinter)

# Clear Queue

$btnQueue = New-Object System.Windows.Forms.Button
$btnQueue.Location = New-Object System.Drawing.Point(330,260)
$btnQueue.Size = New-Object System.Drawing.Size(220,60)
$btnQueue.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnQueue.Text = "Clear Printer Queue"

$btnQueue.Add_Click({

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\Scripts\Printer-tools\Clear_Print_Queue.ps1`""

})

$form.Controls.Add($btnQueue)

#--------------------------------------------------
# CHANGE PRINTER DRIVER
#--------------------------------------------------

$btnChangePrinterDriver = New-Object System.Windows.Forms.Button
$btnChangePrinterDriver.Location = New-Object System.Drawing.Point(75,260)
$btnChangePrinterDriver.Size = New-Object System.Drawing.Size(220,60)
$btnChangePrinterDriver.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnChangePrinterDriver.Text = "Change Printer Driver"

$btnChangePrinterDriver.Add_Click({

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\Scripts\Printer-tools\Change_Printer_Driver.ps1`""

})

$form.Controls.Add($btnChangePrinterDriver)


# --------------------------------------------------
# USER MANAGEMENT
# --------------------------------------------------

$lblUsers = New-Object System.Windows.Forms.Label
$lblUsers.Location = New-Object System.Drawing.Point(20,390)
$lblUsers.AutoSize = $true
$lblUsers.Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Bold)
$lblUsers.Text = "User Management"
$form.Controls.Add($lblUsers)

$btnProfiles = New-Object System.Windows.Forms.Button
$btnProfiles.Location = New-Object System.Drawing.Point(210,440)
$btnProfiles.Size = New-Object System.Drawing.Size(220,60)
$btnProfiles.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnProfiles.Text = "Delete User Profile"

$btnProfiles.Add_Click({

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\Scripts\User-tools\Delete_User_Profile.ps1`""

})

$form.Controls.Add($btnProfiles)

# --------------------------------------------------
# WINDOWS
# --------------------------------------------------

$lblWindows = New-Object System.Windows.Forms.Label
$lblWindows.Location = New-Object System.Drawing.Point(20,560)
$lblWindows.AutoSize = $true
$lblWindows.Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Bold)
$lblWindows.Text = "Windows"
$form.Controls.Add($lblWindows)

$btnGPUpdate = New-Object System.Windows.Forms.Button
$btnGPUpdate.Location = New-Object System.Drawing.Point(210,600)
$btnGPUpdate.Size = New-Object System.Drawing.Size(220,60)
$btnGPUpdate.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnGPUpdate.Text = "Run GPUpdate"

$btnGPUpdate.Add_Click({

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\Scripts\Windows-tools\GPUPDATE.ps1`""

})

$form.Controls.Add($btnGPUpdate)

# --------------------------------------------------
# SHOW FORM
# --------------------------------------------------

$form.Add_Shown({

    $form.Activate()
    $form.ActiveControl = $null

})


$form.ShowDialog() | Out-Null
