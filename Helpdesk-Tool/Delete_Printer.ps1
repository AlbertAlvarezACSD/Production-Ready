# Save as: Printer Tools\Remove_Printer\Remove-Printer-GUI.ps1
# Requires Administrator Rights

Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;

# Create Dialog Form (800x350)
$form = New-Object System.Windows.Forms.Form;
$form.Text = "Printer Removal Utility";
$form.Size = New-Object System.Drawing.Size(800, 350);$form.StartPosition = "CenterScreen";
$form.FormBorderStyle = "FixedDialog";
$form.MaximizeBox =$false;

# Force window to top
$form.TopMost =$true;

# Label
$label = New-Object System.Windows.Forms.Label;
$label.Location = New-Object System.Drawing.Point(25, 20);
$label.Size = New-Object System.Drawing.Size(730, 25);
$label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold);
$label.Text = "Select a locally installed printer to remove:";
$label.AutoSize =$false;
$form.Controls.Add($label);

# Warning Lable
$lblNote = New-Object System.Windows.Forms.Label
$lblNote.Location = New-Object System.Drawing.Point(25,50)
$lblNote.Size = New-Object System.Drawing.Size(730,20)
$lblNote.ForeColor = [System.Drawing.Color]::Red
$lblNote.Text = "* User-mapped and GPO-assigned printers are not displayed."
$form.Controls.Add($lblNote)

# Dropdown List
$comboBox = New-Object System.Windows.Forms.ComboBox;
$comboBox.Location = New-Object System.Drawing.Point(25, 80);
$comboBox.Size = New-Object System.Drawing.Size(730, 45);
$comboBox.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold);
$comboBox.DropDownStyle = "DropDownList";

# Function to refresh list
function Load-Printers {

    $comboBox.Items.Clear()

    $global:printers = Get-Printer |
        Where-Object {
            $_.Type -ne "Connection" -and
            $_.Name -notlike "\\*"
        } |
        Sort-Object Name |
        Select-Object Name, Type, PortName

    foreach ($p in $global:printers) {
        $comboBox.Items.Add("$($p.Name) [$($p.Type)]") | Out-Null
    }

    if ($comboBox.Items.Count -gt 0) {
        $comboBox.SelectedIndex = 0
    }
}

Load-Printers;
$form.Controls.Add($comboBox);

# Fast Non-Blocking Printer Removal Handler
function Invoke-FastPrinterRemoval ([string]$printerName) {
    # 1. Clear any stuck jobs locally
    Get-PrintJob -PrinterName $printerName -ErrorAction SilentlyContinue | Remove-PrintJob -ErrorAction SilentlyContinue;

    # 2. Native Windows PrintUI call (Non-blocking binary execution)
    $process = Start-Process -FilePath "rundll32.exe" -ArgumentList "printui.dll,PrintUIEntry /dl /n `"$printerName`"" -NoNewWindow -PassThru;
    
    # Wait maximum 4 seconds for native removal
    $finished =$process.WaitForExit(4000);
    
    if (-not $finished) {
        # Force kill stuck handle call
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue;
        
        # Fallback: WMI Direct Delete
        Get-CimInstance Win32_Printer -Filter "Name = '$($printerName -replace "'", "\'")'" | Remove-CimInstance -ErrorAction SilentlyContinue;
    }
}

# Button 1: Remove Selected Printer
$btnRemoveSelected = New-Object System.Windows.Forms.Button;
$btnRemoveSelected.Location = New-Object System.Drawing.Point(25, 180);
$btnRemoveSelected.Size = New-Object System.Drawing.Size(355, 55);$btnRemoveSelected.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold);
$btnRemoveSelected.Text = "Remove Selected Printer";
$btnRemoveSelected.Add_Click({
    if ($comboBox.SelectedIndex -ge 0) {$targetPrinter = $global:printers[$comboBox.SelectedIndex].Name;
        
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "Are you sure you want to remove '$targetPrinter'?", 
            "Confirm Removal", 
            [System.Windows.Forms.MessageBoxButtons]::YesNo, 
            [System.Windows.Forms.MessageBoxIcon]::Warning
        );
        
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            # Turn UI cursor to wait state & force repaint
            $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor;
            $btnRemoveSelected.Enabled =$false;
            [System.Windows.Forms.Application]::DoEvents();
            
            Invoke-FastPrinterRemoval -printerName $targetPrinter;
            
            # Reset UI
            $form.Cursor = [System.Windows.Forms.Cursors]::Default;
            $btnRemoveSelected.Enabled =$true;
            
            [System.Windows.Forms.MessageBox]::Show("Printer '$targetPrinter' removal command issued.", "Complete", "OK", "Information");
            Load-Printers;
        }
    }
});
$form.Controls.Add($btnRemoveSelected);

# Button 2: Remove All Local Printers
$btnRemoveAllLocal = New-Object System.Windows.Forms.Button;
$btnRemoveAllLocal.Location = New-Object System.Drawing.Point(400, 180);
$btnRemoveAllLocal.Size = New-Object System.Drawing.Size(355, 55);$btnRemoveAllLocal.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold);
$btnRemoveAllLocal.Text = "Remove All Local Printers";
$btnRemoveAllLocal.Add_Click({$confirm = [System.Windows.Forms.MessageBox]::Show(
    "WARNING:`r`n`r`nThis will remove ALL locally installed printers shown in this utility.`r`n`r`nAre you sure you want to continue?",
    "Confirm Printer Removal",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Warning
);
    
    if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {$form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor;
        $btnRemoveAllLocal.Enabled =$false;
        [System.Windows.Forms.Application]::DoEvents();
        
        Get-Printer | Where-Object { $_.Type -eq "Connection" -or $_.Name -like "\\*" } | ForEach-Object {
            Invoke-FastPrinterRemoval -printerName $_.Name;
        };
        
        $form.Cursor = [System.Windows.Forms.Cursors]::Default;
        $btnRemoveAllLocal.Enabled =$true;
        
        [System.Windows.Forms.MessageBox]::Show(
    "All displayed local printers have been removed.",
    "Complete",
    "OK",
    "Information"
);
        Load-Printers;
    }
});
$form.Controls.Add($btnRemoveAllLocal);

# Force activation to jump in front of ISE/Explorer
$form.Add_Shown({$form.Activate(); });

# Show Dialog
$form.ShowDialog() | Out-Null;