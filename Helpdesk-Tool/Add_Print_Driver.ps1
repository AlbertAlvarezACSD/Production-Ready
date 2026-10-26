# Save As: Add-Driver-GUI.ps1
# Requires Administrator Rights

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ----------------------------------------------------------
# FORM
# ----------------------------------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Stage Printer Driver Utility"
$form.Size = New-Object System.Drawing.Size(800,350)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true

# Header Label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(25,20)
$label.Size = New-Object System.Drawing.Size(730,35)
$label.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$label.Text = "Select a driver package to stage for plug-and-play detection:"
$form.Controls.Add($label)

# Driver Selection Dropdown
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(25,65)
$comboBox.Size = New-Object System.Drawing.Size(730,45)
$comboBox.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$comboBox.DropDownStyle = "DropDownList"

# ----------------------------------------------------------
# DRIVER DEFINITIONS
# ----------------------------------------------------------

$scriptDir = $PSScriptRoot
$driversDir = Join-Path $scriptDir "Drivers"

$presets = [ordered]@{

    "HP UPD PCL6" = @{
        INF  = "$driversDir\HP\UPD_PCL6\hpcu340u.inf"
        Name = "HP Universal Printing PCL 6"
    }

    "OKI UPD PCL5" = @{
        INF  = "$driversDir\OKI\OKI_UPD_PCL5\Driver\OKW3C03Z.INF"
        Name = "OKI Universal PCL 5"
    }

    "Xerox C310/C315" = @{
        INF  = "$driversDir\Xerox\C310_C315_PCL6\Xerox_C310_C315_PCL6.inf"
        Name = "Xerox C310 Color Printer V4 PCL6"
    }

    "OKI B432 (PS)" = @{
        INF  = "$driversDir\OKI\PS\OKW3S055.INF"
        Name = "OKI B432(PS)"
    }
}

foreach ($key in $presets.Keys) {
    $comboBox.Items.Add($key) | Out-Null
}

$comboBox.SelectedIndex = 0

$form.Controls.Add($comboBox)

# ----------------------------------------------------------
# LOGGING
# ----------------------------------------------------------

$LogFolder = "C:\ProgramData\PrinterUtility\Logs"

if (!(Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

$LogFile = Join-Path $LogFolder "PrinterUtility.log"

function Write-Log {
    param([string]$Message)

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content -Path $LogFile -Value "$Timestamp - $Message"
}

# ----------------------------------------------------------
# DRIVER INSTALL FUNCTION
# ----------------------------------------------------------

function Stage-DriverPackage {

    param(
        [string]$InfPath,
        [string]$DriverName,
        [string]$LabelName
    )

    if (-not (Test-Path $InfPath)) {

        [System.Windows.Forms.MessageBox]::Show(
            "Could not locate INF file:`n`n$InfPath",
            "File Not Found",
            "OK",
            "Error"
        )

        Write-Log "Missing INF: $InfPath"

        return
    }

    Write-Log "Starting install: $LabelName"

    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $btnStage.Enabled = $false
 try {
        
# --------------------------------------------------
# Stage in Driver Store
# --------------------------------------------------

        $PnpArgs = "/add-driver `"$InfPath`" /install"

        cmd.exe /c "$env:SystemRoot\System32\pnputil.exe $PnpArgs"
        
        Write-Log "PNPUtil Command Executed"

        # --------------------------------------------------
        # Add Driver To Print Spooler
        # --------------------------------------------------
                          
        $PrintUIArgs = "printui.dll,PrintUIEntry /ia /m `"$DriverName`" /f `"$InfPath`" /q"

        $spoolerProcess = Start-Process `
            -FilePath "$env:SystemRoot\System32\rundll32.exe" `
            -ArgumentList $PrintUIArgs `
            -PassThru `
            -Wait `
            -NoNewWindow

        Write-Log "PrintUI Exit Code: $($spoolerProcess.ExitCode)"

        Start-Sleep -Seconds 2

        # --------------------------------------------------
        # VERIFY INSTALL
        # --------------------------------------------------

        $InstalledDriver = Get-PrinterDriver -ErrorAction SilentlyContinue |
            Where-Object Name -eq $DriverName

        if ($InstalledDriver) {

            Write-Log "SUCCESS - Driver Found: $DriverName"

            [System.Windows.Forms.MessageBox]::Show(
                "Driver installed successfully.`n`n$DriverName",
                "Success",
                "OK",
                "Information"
            )
        }
        else {

            Write-Log "FAILED - Driver Not Found: $DriverName"

            [System.Windows.Forms.MessageBox]::Show(
                "Driver staging completed but verification failed.`n`nDriver not found:`n$DriverName`n`nReview log:`n$LogFile",
                "Verification Failed",
                "OK",
                "Warning"
            )
        }
    }
    catch {

        Write-Log "ERROR - $_"

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "Installation Error",
            "OK",
            "Error"
        )
    }
    finally {

        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        $btnStage.Enabled = $true
    }
}

# ----------------------------------------------------------
# STAGE BUTTON
# ----------------------------------------------------------

$btnStage = New-Object System.Windows.Forms.Button
$btnStage.Location = New-Object System.Drawing.Point(25,160)
$btnStage.Size = New-Object System.Drawing.Size(355,55)
$btnStage.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$btnStage.Text = "Stage Selected Driver"

$btnStage.Add_Click({

    $Selection = $comboBox.SelectedItem.ToString()

    $Driver = $presets[$Selection]

    Stage-DriverPackage `
        -InfPath $Driver.INF `
        -DriverName $Driver.Name `
        -LabelName $Selection

})

$form.Controls.Add($btnStage)

# ----------------------------------------------------------
# VIEW INSTALLED DRIVERS
# ----------------------------------------------------------

$btnViewDrivers = New-Object System.Windows.Forms.Button
$btnViewDrivers.Location = New-Object System.Drawing.Point(400,160)
$btnViewDrivers.Size = New-Object System.Drawing.Size(355,55)
$btnViewDrivers.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$btnViewDrivers.Text = "View Installed Spooler Drivers"

$btnViewDrivers.Add_Click({

    $Drivers = Get-PrinterDriver |
        Sort-Object Name |
        Select-Object -ExpandProperty Name

    $DriverList = $Drivers -join "`r`n"

    [System.Windows.Forms.MessageBox]::Show(
        $DriverList,
        "Installed Printer Drivers",
        "OK",
        "Information"
    )
})

$form.Controls.Add($btnViewDrivers)

# ----------------------------------------------------------
# SHOW FORM
# ----------------------------------------------------------

$form.Add_Shown({
    $form.Activate()
})

$form.ShowDialog() | Out-Null