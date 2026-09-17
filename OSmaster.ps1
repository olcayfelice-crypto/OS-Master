# =========================================================================
# OS MASTER (ISLETIM SISTEMI HUKUMDARI) - %100 SAF POWERSHELL GUI
# =========================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Ana Form Tasarimi
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "OS MASTER: KERNEL VE SISTEM YONETIM MERKEZI [MUTLAK GUC]"
$Form.Size = New-Object System.Drawing.Size(900, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(15,15,15)
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false

# Ust Baslik Bilgisi
$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "BILGISAYARIN MUTLAK EFENDISI PANELÝ"
$TitleLabel.Size = New-Object System.Drawing.Size(850, 30)
$TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$TitleLabel.ForeColor = [System.Drawing.Color]::Cyan
$Form.Controls.Add($TitleLabel)

# Canli Durum Bildirim Satiri
$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Text = "Durum: Sistem izleniyor. Yapilacak islemi secin."
$StatusLabel.Size = New-Object System.Drawing.Size(550, 20)
$StatusLabel.Location = New-Object System.Drawing.Point(200, 570)
$StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$StatusLabel.ForeColor = [System.Drawing.Color]::DarkGray
$Form.Controls.Add($StatusLabel)

# 2. Ana Listeleme Kutusu (ListBox)
$ListBox = New-Object System.Windows.Forms.ListBox
$ListBox.Location = New-Object System.Drawing.Point(200, 60)
$ListBox.Size = New-Object System.Drawing.Size(480, 490)
$ListBox.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$ListBox.ForeColor = [System.Drawing.Color]::LimeGreen
$ListBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$Form.Controls.Add($ListBox)

$Global:CurrentMode = "SERVISLER"

# 3. Sol Menu (Mod Degistirici Butonlar)
$Modes = @("Servisler", "Kernel Suruculer", "Sistem Dosyalari", "Kayit Defteri")
$YPos = 60

foreach ($mode in $Modes) {
    $BtnMode = New-Object System.Windows.Forms.Button
    $BtnMode.Text = $mode.ToUpper()
    $BtnMode.Location = New-Object System.Drawing.Point(20, $YPos)
    $BtnMode.Size = New-Object System.Drawing.Size(160, 45)
    $BtnMode.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $BtnMode.ForeColor = [System.Drawing.Color]::White
    $BtnMode.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $BtnMode.FlatStyle = "Flat"
    
    $BtnMode.Add_Click({
        $Global:CurrentMode = $this.Text
        $StatusLabel.Text = "Durum: $($this.Text) katmani yuklendi."
        Refresh-Data
    })
    
    $Form.Controls.Add($BtnMode)
    $YPos += 55
}

# 4. Veri Yenileme Motoru (Refresh-Data)
function Refresh-Data {
    $ListBox.Items.Clear()
    
    if ($Global:CurrentMode -eq "SERVISLER") {
        Get-Service | ForEach-Object { $ListBox.Items.Add("[$($_.Status)] -> $($_.Name) ($($_.DisplayName))") | Out-Null }
    }
    elseif ($Global:CurrentMode -eq "KERNEL SURUCULER") {
        Get-CimInstance Win32_SystemDriver | ForEach-Object { $ListBox.Items.Add("[$($_.State)] -> $($_.Name) ($($_.DisplayName))") | Out-Null }
    }
    elseif ($Global:CurrentMode -eq "SISTEM DOSYALARI") {
        Get-ChildItem -Path "$env:windir\System32\*.exe" | Select-Object -First 100 | ForEach-Object { $ListBox.Items.Add("[DOSYA] -> $($_.Name) ($($_.FullName))") | Out-Null }
    }
    elseif ($Global:CurrentMode -eq "KAYIT DEFTERI") {
        Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control" | ForEach-Object { $ListBox.Items.Add("[REGISTRY] -> $($_.PSChildName)") | Out-Null }
    }
}

# 5. Sag Menu - Agresif Eylem Butonlari
# [ZORLA DURDUR]
$BtnStop = New-Object System.Windows.Forms.Button
$BtnStop.Text = "ZORLA DURDUR"
$BtnStop.Location = New-Object System.Drawing.Point(700, 60)
$BtnStop.Size = New-Object System.Drawing.Size(160, 50)
$BtnStop.BackColor = [System.Drawing.Color]::DarkRed
$BtnStop.ForeColor = [System.Drawing.Color]::White
$BtnStop.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$BtnStop.FlatStyle = "Flat"
$BtnStop.Add_Click({
    if ($ListBox.SelectedItem) {
        $Item = $ListBox.SelectedItem
        $Target = ($Item -split "-> ") -split " \(" | Select-Object -First 1 -Skip 1
        $Target = $Target.Trim()
        
        if ($Global:CurrentMode -eq "SERVISLER") {
            Stop-Service -Name $Target -Force -ErrorAction SilentlyContinue
            $StatusLabel.Text = "Durum: $Target servisi durduruldu."
        }
        elseif ($Global:CurrentMode -eq "KERNEL SURUCULER") {
            sc.exe stop $Target | Out-Null
            $StatusLabel.Text = "Durum: $Target kernel surucusu durduruldu."
        }
        Start-Sleep -Milliseconds 500
        Refresh-Data
    }
})
$Form.Controls.Add($BtnStop)

# [DEVAM ETTIR]
$BtnStart = New-Object System.Windows.Forms.Button
$BtnStart.Text = "DEVAM ETTIR"
$BtnStart.Location = New-Object System.Drawing.Point(700, 120)
$BtnStart.Size = New-Object System.Drawing.Size(160, 50)
$BtnStart.BackColor = [System.Drawing.Color]::DarkGreen
$BtnStart.ForeColor = [System.Drawing.Color]::White
$BtnStart.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$BtnStart.FlatStyle = "Flat"
$BtnStart.Add_Click({
    if ($ListBox.SelectedItem) {
        $Item = $ListBox.SelectedItem
        $Target = ($Item -split "-> ") -split " \(" | Select-Object -First 1 -Skip 1
        $Target = $Target.Trim()
        
        if ($Global:CurrentMode -eq "SERVISLER") {
            Start-Service -Name $Target -ErrorAction SilentlyContinue
        }
        elseif ($Global:CurrentMode -eq "KERNEL SURUCULER") {
            sc.exe start $Target | Out-Null
        }
        Start-Sleep -Milliseconds 500
        Refresh-Data
    }
})
$Form.Controls.Add($BtnStart)

# [SISTEMDEN KAZI]
$BtnDelete = New-Object System.Windows.Forms.Button
$BtnDelete.Text = "SISTEMDEN KAZI"
$BtnDelete.Location = New-Object System.Drawing.Point(700, 180)
$BtnDelete.Size = New-Object System.Drawing.Size(160, 50)
$BtnDelete.BackColor = [System.Drawing.Color]::FromArgb(210, 80, 0)
$BtnDelete.ForeColor = [System.Drawing.Color]::White
$BtnDelete.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$BtnDelete.FlatStyle = "Flat"
$BtnDelete.Add_Click({
    if ($ListBox.SelectedItem) {
        $Item = $ListBox.SelectedItem
        
        $Confirm = [System.Windows.Forms.MessageBox]::Show("Bu bileseni kalici olarak silmek istediginize emin misiniz?", "KRITIK ONAY", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($Confirm -eq "Yes") {
            
            if ($Global:CurrentMode -eq "SERVISLER" -or $Global:CurrentMode -eq "KERNEL SURUCULER") {
                $Target = ($Item -split "-> ") -split " \(" | Select-Object -First 1 -Skip 1
                $Target = $Target.Trim()
                Stop-Service -Name $Target -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Target" -Recurse -Force -ErrorAction SilentlyContinue
                $StatusLabel.Text = "Durum: $Target imha edildi."
            }
            elseif ($Global:CurrentMode -eq "SISTEM DOSYALARI") {
                $TargetFile = ($Item -split "-> ") -split " \(" | Select-Object -Last 1
                $TargetFile = $TargetFile.Trim(')').Trim()
                
                $adminSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltInAdministratorsSid, $null)
                $acl = Get-Acl -LiteralPath $TargetFile -ErrorAction SilentlyContinue
                if ($acl) { $acl.SetOwner($adminSid); Set-Acl -LiteralPath $TargetFile $acl -ErrorAction SilentlyContinue }
                [System.IO.File]::SetAttributes($TargetFile, [System.IO.FileAttributes]::Normal)
                [System.IO.File]::Delete("\\?\" + $TargetFile)
                $StatusLabel.Text = "Durum: $TargetFile silindi."
            }
            elseif ($Global:CurrentMode -eq "KAYIT DEFTERI") {
                $TargetReg = ($Item -split "-> ") | Select-Object -Last 1
                $TargetReg = $TargetReg.Trim()
                Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\$TargetReg" -Recurse -Force -ErrorAction SilentlyContinue
                $StatusLabel.Text = "Durum: Registry silindi."
            }
            
            Start-Sleep -Milliseconds 500
            Refresh-Data
        }
    }
})
$Form.Controls.Add($BtnDelete)

# [LISTEYI TAZELER]
$BtnRefresh = New-Object System.Windows.Forms.Button
$BtnRefresh.Text = "LISTEYI YENILE"
$BtnRefresh.Location = New-Object System.Drawing.Point(700, 500)
$BtnRefresh.Size = New-Object System.Drawing.Size(160, 50)
$BtnRefresh.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
$BtnRefresh.ForeColor = [System.Drawing.Color]::White
$BtnRefresh.FlatStyle = "Flat"
$BtnRefresh.Add_Click({ Refresh-Data })
$Form.Controls.Add($BtnRefresh)

# Ilk acilis verisini cek
Refresh-Data

# Formu Ekrana Yansit
$Form.ShowDialog() | Out-Null
