$ErrorActionPreference = 'SilentlyContinue'
$logFile = "$env:USERPROFILE\Desktop\RockstarCleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
 
function Write-Log {
    param([string]$Msg, [string]$Color = 'White')
    Write-Host $Msg -ForegroundColor $Color
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'HH:mm:ss') $Msg"
}
 
function Write-Banner {
    Clear-Host
    Write-Host @"
╔══════════════════════════════════════════════════════╗
║   ROCKSTAR GAMES + EASY ANTI-CHEAT REMOVER  (W11)     ║
╚══════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
}
 
function Show-Checklist {
    param([string]$Title, [string[]]$Items)
    Write-Host "`n--- What this will check: $Title ---" -ForegroundColor Cyan
    foreach ($i in $Items) { Write-Host "  [ ] $i" -ForegroundColor DarkGray }
    Write-Host "------------------------------------------------------`n" -ForegroundColor Cyan
}
 
# ======================================================
#  SECTION 1 - UNINSTALL (removes the installed products)
# ======================================================
 
function Stop-TargetProcesses {
    Write-Log "`n[1/5] Stopping running processes..." Yellow
    $names = @(
        'PlayGTAV','GTA5','RDR2','LauncherPatcher','Launcher','RockstarService',
        'RockstarErrorHandler','SocialClubHelper','Social-Club-Setup','EasyAntiCheat',
        'EasyAntiCheat_Setup','EACRuntime'
    )
    foreach ($n in $names) {
        Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Log "  - Killing process: $n" DarkGray
            Stop-Process -Id $_.Id -Force
        }
    }
}
 
function Stop-TargetServices {
    Write-Log "`n[2/5] Stopping and removing services..." Yellow
    $services = @('RockstarService','EasyAntiCheat','EasyAntiCheatSys')
    foreach ($s in $services) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Log "  - Service found: $s" DarkGray
            Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
            sc.exe delete $s | Out-Null
        }
    }
}
 
function Remove-TargetTasks {
    Write-Log "`n[3/5] Removing scheduled tasks..." Yellow
    Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskName -match 'Rockstar|EasyAntiCheat|Social Club' } |
        ForEach-Object {
            Write-Log "  - Task: $($_.TaskName)" DarkGray
            Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false
        }
}
 
function Uninstall-ViaRegistry {
    Write-Log "`n[4/5] Running official silent uninstallers..." Yellow
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $apps = Get-ItemProperty $paths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'Rockstar|Social Club|Easy Anti-Cheat|EasyAntiCheat' }
 
    foreach ($app in $apps) {
        Write-Log "  - Uninstalling: $($app.DisplayName)" DarkGray
        $uninstStr = $app.QuietUninstallString
        if (-not $uninstStr) { $uninstStr = $app.UninstallString }
        if ($uninstStr) {
            if ($uninstStr -match '^"([^"]+)"(.*)') {
                $exe = $Matches[1]; $args = "$($Matches[2]) /S /silent /quiet /norestart"
            } else {
                $split = $uninstStr.Split(' ',2)
                $exe = $split[0]; $args = "$($split[1]) /S /silent /quiet /norestart"
            }
            try { Start-Process -FilePath $exe -ArgumentList $args -Wait -ErrorAction SilentlyContinue } catch {}
        }
    }
}
 
function Remove-InstallFolders {
    Write-Log "`n[5/5] Removing install folders and known registry keys..." Yellow
    $folders = @(
        "$env:ProgramFiles\Rockstar Games", "${env:ProgramFiles(x86)}\Rockstar Games",
        "$env:ProgramData\Rockstar Games", "$env:LOCALAPPDATA\Rockstar Games",
        "$env:APPDATA\Rockstar Games", "$env:USERPROFILE\Documents\Rockstar Games",
        "$env:ProgramData\EasyAntiCheat", "$env:ProgramFiles\EasyAntiCheat",
        "${env:ProgramFiles(x86)}\EasyAntiCheat", "$env:LOCALAPPDATA\EasyAntiCheat",
        "$env:SystemRoot\System32\drivers\EasyAntiCheat.sys",
        "$env:SystemRoot\SysWOW64\EasyAntiCheat.sys"
    )
    foreach ($f in $folders) {
        if (Test-Path $f) { Write-Log "  - Deleting: $f" DarkGray; Remove-Item -Path $f -Recurse -Force }
    }
    $keys = @(
        'HKLM:\SOFTWARE\Rockstar Games', 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games',
        'HKCU:\SOFTWARE\Rockstar Games', 'HKLM:\SYSTEM\CurrentControlSet\Services\EasyAntiCheat',
        'HKLM:\SYSTEM\CurrentControlSet\Services\EasyAntiCheatSys'
    )
    foreach ($k in $keys) {
        if (Test-Path $k) { Write-Log "  - Key: $k" DarkGray; Remove-Item -Path $k -Recurse -Force }
    }
    Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                   'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
        Where-Object { (Get-ItemProperty $_.PSPath).DisplayName -match 'Rockstar|Social Club|Easy Anti-Cheat' } |
        Remove-Item -Recurse -Force
}
 
function Invoke-Uninstall {
    Show-Checklist "Uninstall Rockstar Games Services" @(
        "Running processes: launchers, GTA V, RDR2, Social Club, EasyAntiCheat"
        "Windows services: RockstarService, EasyAntiCheat, EasyAntiCheatSys"
        "Scheduled tasks named Rockstar / EasyAntiCheat / Social Club"
        "Official silent uninstallers registered in Windows (Uninstall registry)"
        "Install folders: Program Files, ProgramData, AppData (Local/Roaming), Documents"
        "EasyAntiCheat driver files (.sys) in System32/SysWOW64"
        "Known Rockstar/EasyAntiCheat registry keys under HKLM/HKCU"
    )
    $confirm = Read-Host "This permanently uninstalls the above. Continue? (Y/N)"
    if ($confirm -notmatch '^[Yy]') { Write-Log "Cancelled by user." Yellow; return }
 
    Stop-TargetProcesses
    Stop-TargetServices
    Remove-TargetTasks
    Uninstall-ViaRegistry
    Remove-InstallFolders
    Write-Log "`nUninstall finished." Green
    Pause-AndClear
}
 
# ======================================================
#  SECTION 2 - TRACE REMOVAL (scans only, nothing is
#  uninstalled here; this only finds/removes leftovers)
# ======================================================
 
$RockstarPattern = '\b(Rockstar Games|Social ?Club|GTA ?V|RDR ?2|Red Dead Redemption|EasyAntiCheat|Easy Anti-?Cheat)\b'
 
function Backup-Registry {
    $backupPath = "$env:USERPROFILE\Desktop\RockstarCleanup_RegBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
    Write-Log "  - Registry backup: $backupPath" DarkGray
    reg export "HKLM\SOFTWARE\Rockstar Games" $backupPath /y 2>$null
    reg export "HKCU\SOFTWARE\Rockstar Games" "$backupPath.hkcu.reg" /y 2>$null
}
 
function Find-RockstarTraces {
    # Checks: fixed drives (folder names), scoped registry roots (product
    # keys, uninstall entries, services - CLSID/AppID/Interface/TypeLib
    # excluded on purpose, they cause false positives), Start Menu/Desktop
    # shortcuts, firewall rules, and the hosts file.
    Write-Log "  - Scanning fixed drives for Rockstar/EAC folders..." DarkGray
    $found = [System.Collections.Generic.List[string]]::new()
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }
    foreach ($d in $drives) {
        Get-ChildItem -Path "$($d.Root)" -Recurse -Directory -ErrorAction SilentlyContinue -Force |
            Where-Object { $_.Name -match $RockstarPattern } |
            ForEach-Object { $found.Add($_.FullName) }
    }
 
    Write-Log "  - Scanning registry (scoped roots, no CLSID/AppID)..." DarkGray
    function Search-RegistryTree {
        param($RootPath)
        if (-not (Test-Path $RootPath)) { return }
        Get-ChildItem -Path $RootPath -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $_.PSPath -notmatch 'Classes\\(CLSID|AppID|Interface|TypeLib|WOW6432Node\\CLSID)' -and
                ($_.PSChildName -match $RockstarPattern)
            } | ForEach-Object { $found.Add("REG: $($_.Name)") }
    }
    Search-RegistryTree 'HKLM:\SOFTWARE\Rockstar Games'
    Search-RegistryTree 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games'
    Search-RegistryTree 'HKCU:\SOFTWARE\Rockstar Games'
    Search-RegistryTree 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    Search-RegistryTree 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    Search-RegistryTree 'HKLM:\SYSTEM\CurrentControlSet\Services'
 
    Write-Log "  - Scanning shortcuts (Desktop / Start Menu)..." DarkGray
    $shortcutPaths = @(
        "$env:PUBLIC\Desktop", "$env:USERPROFILE\Desktop",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
    )
    foreach ($sp in $shortcutPaths) {
        Get-ChildItem -Path $sp -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match $RockstarPattern } |
            ForEach-Object { $found.Add($_.FullName) }
    }
 
    Write-Log "  - Scanning firewall rules..." DarkGray
    Get-NetFirewallRule -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match $RockstarPattern } |
        ForEach-Object { $found.Add("FIREWALL: $($_.DisplayName)") }
 
    Write-Log "  - Scanning hosts file..." DarkGray
    if ((Get-Content $hostsFile -ErrorAction SilentlyContinue) -match 'rockstar|rgsc') {
        $found.Add("HOSTS: Rockstar-related entries in $hostsFile")
    }
    return $found
}
 
function Remove-RockstarTraces {
    param([string[]]$Traces)
    Backup-Registry
    foreach ($t in $Traces) {
        if ($t -like 'REG: *') {
            Remove-Item -Path ($t -replace '^REG: ', '') -Recurse -Force
        } elseif ($t -like 'FIREWALL: *') {
            Remove-NetFirewallRule -DisplayName ($t -replace '^FIREWALL: ', '')
        } elseif ($t -like 'HOSTS: *') {
            (Get-Content $hostsFile) | Where-Object { $_ -notmatch 'rockstar|rgsc' } | Set-Content $hostsFile -Force
        } else {
            Remove-Item -Path $t -Recurse -Force
        }
        Write-Log "  - Removed: $t" DarkGray
    }
}
 
function Find-SuspiciousFiles {
    # Heuristic-only, report style (never auto-deleted): flags executable-type
    # files whose NAME looks machine-generated rather than human-chosen -
    # the classic pattern for injectors/loaders dropped by cheat menus.
    #   - hash-like names: 12-40 chars, hex only (e.g. a3f9c1e2b7d4...)
    #   - GUID-shaped names: 8-4-4-4-12 hex blocks
    #   - double extensions: name.pdf.exe, name.doc.scr (classic disguise trick)
    # Scoped to common drop locations only (Temp, Downloads, Desktop, root of
    # AppData, root of each drive) to keep it fast and relevant.
    $found = [System.Collections.Generic.List[string]]::new()
    $exeExt = '\.(exe|dll|sys|scr|bat|cmd|ps1)$'
    $hexName = '^[0-9a-fA-F]{12,40}$'
    $guidName = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    $doubleExt = '\.\w{2,5}\.(exe|scr|bat|cmd)$'
 
    $scanPaths = @(
        $env:TEMP, "$env:LOCALAPPDATA\Temp", $env:APPDATA,
        "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop"
    )
    foreach ($p in $scanPaths) {
        if (-not (Test-Path $p)) { continue }
        Get-ChildItem -Path $p -File -Recurse -Depth 1 -ErrorAction SilentlyContinue | ForEach-Object {
            $base = $_.BaseName
            if ($_.Name -match $doubleExt) {
                $found.Add("SUSPICIOUS-INFO: $($_.FullName) (double extension, disguise trick)")
            } elseif ($_.Name -match $exeExt -and ($base -match $hexName -or $base -match $guidName)) {
                $found.Add("SUSPICIOUS-INFO: $($_.FullName) (machine-generated hash/GUID name)")
            }
        }
    }
 
    # Root of each fixed drive: a common dumb-drop spot for loaders.
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }
    foreach ($d in $drives) {
        Get-ChildItem -Path $d.Root -File -ErrorAction SilentlyContinue | ForEach-Object {
            $base = $_.BaseName
            if ($_.Name -match $exeExt -and ($base -match $hexName -or $base -match $guidName -or $_.Name -match $doubleExt)) {
                $found.Add("SUSPICIOUS-INFO: $($_.FullName) (unusual file at drive root)")
            }
        }
    }
    return $found
}
 
function Find-ReShadeTraces {
    # ReShade injects generic-named DLLs (dxgi.dll, d3d11.dll, opengl32.dll...)
    # that are ALSO legit system/game files - blanket-deleting those anywhere
    # would break unrelated software. Instead: only flag them when they sit
    # next to an unambiguous ReShade marker file (ReShade.ini/.log, or a
    # GShade fork), proving that specific copy is a ReShade injector.
    $found = [System.Collections.Generic.List[string]]::new()
    $markerNames = @('ReShade.ini','ReShade.log','ReShadePreset.ini','GShade.ini','GShade.log')
    $injectorDlls = @('dxgi.dll','d3d9.dll','d3d10.dll','d3d11.dll','d3d12.dll','opengl32.dll','dinput8.dll','d3dcompiler_47.dll')
 
    Write-Log "  - Scanning fixed drives for ReShade marker files..." DarkGray
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }
    $markerDirs = [System.Collections.Generic.HashSet[string]]::new()
 
    foreach ($d in $drives) {
        foreach ($m in $markerNames) {
            Get-ChildItem -Path $d.Root -Filter $m -Recurse -File -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $found.Add($_.FullName)
                    $markerDirs.Add($_.DirectoryName) | Out-Null
                }
        }
        # Shader/preset folders are unambiguous on their own, no marker needed.
        Get-ChildItem -Path $d.Root -Directory -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^reshade-(shaders|presets)$' } |
            ForEach-Object { $found.Add($_.FullName) }
    }
 
    Write-Log "  - Checking for injector DLLs next to confirmed ReShade installs..." DarkGray
    foreach ($dir in $markerDirs) {
        foreach ($dll in $injectorDlls) {
            $path = Join-Path $dir $dll
            if (Test-Path $path) { $found.Add($path) }
        }
    }
 
    Write-Log "  - Scanning registry for ReShade settings..." DarkGray
    if (Test-Path 'HKCU:\SOFTWARE\ReShade') { $found.Add('REG: HKCU:\SOFTWARE\ReShade') }
 
    return $found
}
 
function Find-WindowsTraces {
    # Checks: Prefetch files (evidence a program ran), BAM/DAM registry
    # (Windows' own per-app run-history, tracks executed paths + timestamps),
    # and Application/System Event Log entries mentioning Rockstar/EAC.
    # Event Log matches are reported ONLY, never auto-deleted: clearing a
    # whole log wipes unrelated entries too and can itself look suspicious.
    $found = [System.Collections.Generic.List[string]]::new()
 
    Write-Log "  - Scanning Prefetch (execution evidence)..." DarkGray
    Get-ChildItem "$env:SystemRoot\Prefetch" -Filter '*.pf' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $RockstarPattern -or $_.Name -match 'GTA5|RDR2|PlayGTAV' } |
        ForEach-Object { $found.Add("PREFETCH: $($_.FullName)") }
 
    Write-Log "  - Scanning BAM/DAM run-history (per-app execution record)..." DarkGray
    foreach ($svc in @('bam','dam')) {
        $root = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc\State\UserSettings"
        if (Test-Path $root) {
            Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
                $userKey = $_.PSPath
                Get-Item $userKey -ErrorAction SilentlyContinue | ForEach-Object {
                    (Get-ItemProperty $userKey).PSObject.Properties |
                        Where-Object { $_.Name -match $RockstarPattern -or $_.Name -match 'GTA5|RDR2|PlayGTAV' } |
                        ForEach-Object { $found.Add("BAM: $userKey\$($_.Name)") }
                }
            }
        }
    }
 
    Write-Log "  - Scanning for suspicious/weird-named files (heuristic)..." DarkGray
    Find-SuspiciousFiles | ForEach-Object { $found.Add($_) }
 
    Write-Log "  - Scanning Application/System Event Logs (last 60 days, report only)..." DarkGray
    $since = (Get-Date).AddDays(-60)
    foreach ($log in @('Application','System')) {
        Get-WinEvent -FilterHashtable @{ LogName = $log; StartTime = $since } -MaxEvents 2000 -ErrorAction SilentlyContinue |
            Where-Object { $_.Message -match $RockstarPattern } |
            Select-Object -First 30 |
            ForEach-Object {
                $firstLine = ($_.Message -split "`n")[0]
                $found.Add("EVTLOG-INFO: [$log] $($_.TimeCreated) - $($_.Id) $firstLine")
            }
    }
    return $found
}
 
function Remove-WindowsTraces {
    param([string[]]$Traces)
    foreach ($t in $Traces) {
        if ($t -like 'PREFETCH: *') {
            Remove-Item -Path ($t -replace '^PREFETCH: ', '') -Force
            Write-Log "  - Removed: $t" DarkGray
        } elseif ($t -like 'BAM: *') {
            $full = $t -replace '^BAM: ', ''
            $keyPath = $full.Substring(0, $full.LastIndexOf('\'))
            $valueName = $full.Substring($full.LastIndexOf('\') + 1)
            Remove-ItemProperty -Path $keyPath -Name $valueName -ErrorAction SilentlyContinue
            Write-Log "  - Removed: $t" DarkGray
        } elseif ($t -like 'EVTLOG-INFO: *') {
            Write-Log "  - Skipped (Event Log entries are not auto-deleted): $t" Yellow
        } elseif ($t -like 'SUSPICIOUS-INFO: *') {
            Write-Log "  - Skipped (review manually before deleting, heuristic can false-positive): $t" Yellow
        }
    }
}
 
function Remove-ReShadeTraces {
    param([string[]]$Traces)
    foreach ($t in $Traces) {
        if ($t -like 'REG: *') {
            Remove-Item -Path ($t -replace '^REG: ', '') -Recurse -Force
        } else {
            Remove-Item -Path $t -Recurse -Force
        }
        Write-Log "  - Removed: $t" DarkGray
    }
}
 
function Find-BattlEyeTraces {
    # Same logic as the EasyAntiCheat cleanup: known service, install folder,
    # and driver files. Also runs a diagnostic-only check for the system-level
    # causes of BE kicks that AREN'T cheat-related (Secure Boot, Test Mode,
    # virtualization, unsigned drivers) - those are reported, never deleted.
    $found = [System.Collections.Generic.List[string]]::new()
 
    Write-Log "  - Checking BattlEye service..." DarkGray
    if (Get-Service -Name 'BEService' -ErrorAction SilentlyContinue) { $found.Add('SVC: BEService') }
 
    Write-Log "  - Checking BattlEye install folders..." DarkGray
    foreach ($f in @(
        "$env:ProgramFiles\Common Files\BattlEye",
        "${env:ProgramFiles(x86)}\Common Files\BattlEye",
        "$env:ProgramData\BattlEye"
    )) { if (Test-Path $f) { $found.Add($f) } }
 
    Write-Log "  - Checking BattlEye driver files..." DarkGray
    foreach ($drv in @(
        "$env:SystemRoot\System32\drivers\BEDaisy.sys",
        "$env:SystemRoot\System32\drivers\BEDrv.sys"
    )) { if (Test-Path $drv) { $found.Add($drv) } }
 
    Write-Log "  - Checking BattlEye registry key..." DarkGray
    if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\BEDaisy') { $found.Add('REG: HKLM:\SYSTEM\CurrentControlSet\Services\BEDaisy') }
 
    Write-Log "`n  - Running diagnostic (report only, not deletable)..." DarkGray
    try {
        $sb = Confirm-SecureBootUEFI -ErrorAction Stop
        $found.Add("DIAG-INFO: Secure Boot is $(if ($sb) {'ENABLED (good)'} else {'DISABLED - can trigger BE kicks'})")
    } catch { $found.Add("DIAG-INFO: Secure Boot status unknown (legacy BIOS or unsupported)") }
 
    $testMode = (bcdedit /enum) -match 'testsigning\s+Yes'
    $found.Add("DIAG-INFO: Windows Test Mode is $(if ($testMode) {'ON - can trigger BE kicks, run: bcdedit /set testsigning off'} else {'off (good)'})")
 
    $hyperv = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue).State
    if ($hyperv -eq 'Enabled') { $found.Add("DIAG-INFO: Hyper-V is enabled - some anti-cheats flag active virtualization") }
 
    Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
        Where-Object { $_.DriverSigned -eq $false -and $_.DeviceName } |
        Select-Object -First 10 |
        ForEach-Object { $found.Add("DIAG-INFO: Unsigned driver loaded - $($_.DeviceName)") }
 
    return $found
}
 
function Remove-BattlEyeTraces {
    param([string[]]$Traces)
    foreach ($t in $Traces) {
        if ($t -like 'DIAG-INFO: *') {
            Write-Log "  - Info only, not removed: $t" Yellow
        } elseif ($t -like 'SVC: *') {
            $svcName = $t -replace '^SVC: ', ''
            Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            sc.exe delete $svcName | Out-Null
            Write-Log "  - Removed service: $svcName" DarkGray
        } elseif ($t -like 'REG: *') {
            Remove-Item -Path ($t -replace '^REG: ', '') -Recurse -Force
            Write-Log "  - Removed: $t" DarkGray
        } else {
            Remove-Item -Path $t -Recurse -Force
            Write-Log "  - Removed: $t" DarkGray
        }
    }
}
 
function Pause-AndClear {
    Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray
    Read-Host | Out-Null
    Clear-Host
    Write-Banner
}
 
function Invoke-TraceMenu {
    while ($true) {
        Write-Host "`n--- 2. Remove Traces ---" -ForegroundColor Cyan
        Write-Host "  1. Windows   (Prefetch, BAM/DAM run-history, weird-named files, Event Log report)"
        Write-Host "  2. Rockstar  (files, registry, shortcuts, firewall, hosts)"
        Write-Host "  3. ReShade   (injector DLLs, shaders/presets, config, registry)"
        Write-Host "  4. BattlEye  (service, drivers, folder + kick-cause diagnostic)"
        Write-Host "  5. Complete  (all of the above, nothing is uninstalled)"
        Write-Host "  0. Back"
        $opt = Read-Host "Choose an option"
 
        switch ($opt) {
            '1' {
                Show-Checklist "Windows" @(
                    "Prefetch files (\Windows\Prefetch\*.pf) matching Rockstar/GTA/RDR2/EAC"
                    "BAM/DAM registry run-history (per-user executed program paths)"
                    "Suspicious/weird-named files: hash-like or GUID-like .exe/.dll/.sys names, double extensions (Temp, Downloads, Desktop, AppData root, drive roots) - REPORT ONLY"
                    "Application + System Event Log entries mentioning Rockstar/EAC (last 60 days, REPORT ONLY - not deleted)"
                )
                $traces = Find-WindowsTraces
                Write-Log "  >> Traces found: $($traces.Count)" $(if ($traces.Count) {'Red'} else {'Green'})
                $traces | ForEach-Object { Write-Log "     $_" DarkGray }
                if ($traces.Count -gt 0) {
                    $c = Read-Host "Type DELETE to remove the removable traces above"
                    if ($c -ceq 'DELETE') { Remove-WindowsTraces -Traces $traces } else { Write-Log "Cancelled." Yellow }
                }
                Pause-AndClear
            }
            '2' {
                Show-Checklist "Rockstar" @(
                    "All fixed drives: folders/files named Rockstar Games, Social Club, GTA V, RDR2, EasyAntiCheat"
                    "Registry: HKLM/HKCU Rockstar Games keys, Uninstall entries, Services (CLSID/AppID excluded)"
                    "Desktop and Start Menu shortcuts (.lnk)"
                    "Windows Firewall rules"
                    "hosts file entries"
                )
                $traces = Find-RockstarTraces
                Write-Log "  >> Traces found: $($traces.Count)" $(if ($traces.Count) {'Red'} else {'Green'})
                $traces | ForEach-Object { Write-Log "     $_" DarkGray }
                if ($traces.Count -gt 0) {
                    $c = Read-Host "Type DELETE to remove these $($traces.Count) traces"
                    if ($c -ceq 'DELETE') { Remove-RockstarTraces -Traces $traces } else { Write-Log "Cancelled." Yellow }
                }
                Pause-AndClear
            }
            '3' {
                Show-Checklist "ReShade" @(
                    "Marker files: ReShade.ini, ReShade.log, ReShadePreset.ini, GShade.ini/.log"
                    "reshade-shaders / reshade-presets folders (unambiguous on their own)"
                    "Injector DLLs (dxgi.dll, d3d9/10/11/12.dll, opengl32.dll, dinput8.dll, d3dcompiler_47.dll) - ONLY when found next to a confirmed marker file, to avoid deleting legit system copies"
                    "Registry: HKCU\SOFTWARE\ReShade"
                )
                $traces = Find-ReShadeTraces
                Write-Log "  >> Traces found: $($traces.Count)" $(if ($traces.Count) {'Red'} else {'Green'})
                $traces | ForEach-Object { Write-Log "     $_" DarkGray }
                if ($traces.Count -gt 0) {
                    $c = Read-Host "Type DELETE to remove these $($traces.Count) traces"
                    if ($c -ceq 'DELETE') { Remove-ReShadeTraces -Traces $traces } else { Write-Log "Cancelled." Yellow }
                }
                Pause-AndClear
            }
            '4' {
                Show-Checklist "BattlEye" @(
                    "BEService (Windows service)"
                    "Install folders: Common Files\BattlEye, ProgramData\BattlEye"
                    "Driver files: BEDaisy.sys, BEDrv.sys"
                    "Registry: HKLM\SYSTEM\CurrentControlSet\Services\BEDaisy"
                    "Diagnostic (report only): Secure Boot status, Windows Test Mode, Hyper-V, unsigned drivers loaded - common non-cheat causes of BE kicks"
                )
                $traces = Find-BattlEyeTraces
                Write-Log "  >> Traces found: $($traces.Count)" $(if ($traces.Count) {'Red'} else {'Green'})
                $traces | ForEach-Object { Write-Log "     $_" DarkGray }
                if ($traces.Count -gt 0) {
                    $c = Read-Host "Type DELETE to remove the removable items above"
                    if ($c -ceq 'DELETE') { Remove-BattlEyeTraces -Traces $traces } else { Write-Log "Cancelled." Yellow }
                }
                Pause-AndClear
            }
            '5' {
                Show-Checklist "Complete (no uninstall)" @(
                    "Everything from 'Windows' + 'Rockstar' + 'ReShade' + 'BattlEye' above"
                    "Nothing is uninstalled: no processes killed, no services/tasks removed, no uninstallers run"
                )
                $t1 = Find-WindowsTraces
                $t2 = Find-RockstarTraces
                $t3 = Find-ReShadeTraces
                $t4 = Find-BattlEyeTraces
                $all = @($t1) + @($t2) + @($t3) + @($t4)
                Write-Log "  >> Traces found: $($all.Count)" $(if ($all.Count) {'Red'} else {'Green'})
                $all | ForEach-Object { Write-Log "     $_" DarkGray }
                if ($all.Count -gt 0) {
                    $c = Read-Host "Type DELETE to remove the removable traces above"
                    if ($c -ceq 'DELETE') {
                        Remove-WindowsTraces -Traces $t1
                        Remove-RockstarTraces -Traces $t2
                        Remove-ReShadeTraces -Traces $t3
                        Remove-BattlEyeTraces -Traces $t4
                    } else { Write-Log "Cancelled." Yellow }
                }
                Pause-AndClear
            }
            '0' { Clear-Host; Write-Banner; return }
            default { Write-Host "Invalid option." -ForegroundColor Red }
        }
    }
}
 
function Invoke-StopAllLaunchers {
    Show-Checklist "Stop Launcher Services (Rockstar / Steam / Epic Games)" @(
        "Rockstar: Launcher, RockstarService, RockstarErrorHandler, SocialClubHelper, EasyAntiCheat"
        "Steam: steam.exe, steamwebhelper.exe, steamservice.exe, GameOverlayUI.exe, SteamService (Windows service)"
        "Epic Games: EpicGamesLauncher.exe, EpicWebHelper.exe, EOSBootstrapper.exe, EOSOverlayRenderer-Win64-Shipping.exe"
        "Nothing is uninstalled or deleted - only running processes/services are stopped, safe to relaunch anytime"
    )
    $confirm = Read-Host "Stop all of the above now? (Y/N)"
    if ($confirm -notmatch '^[Yy]') { Write-Log "Cancelled by user." Yellow; Pause-AndClear; return }
 
    $processNames = @(
        # Rockstar
        'PlayGTAV','GTA5','RDR2','LauncherPatcher','Launcher','RockstarService',
        'RockstarErrorHandler','SocialClubHelper','Social-Club-Setup','EasyAntiCheat',
        'EasyAntiCheat_Setup','EACRuntime',
        # Steam
        'steam','steamwebhelper','steamservice','GameOverlayUI','steamerrorreporter',
        # Epic Games
        'EpicGamesLauncher','EpicWebHelper','EOSBootstrapper','EOSOverlayRenderer-Win64-Shipping',
        'UnrealEngineLauncher',
        # BattlEye
        'BEService','BEDaisy','BattlEye'
    )
    Write-Log "`nStopping processes..." Yellow
    foreach ($n in $processNames) {
        Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Log "  - Killing process: $n" DarkGray
            Stop-Process -Id $_.Id -Force
        }
    }
 
    Write-Log "`nStopping services (not removed, just stopped)..." Yellow
    $serviceNames = @('RockstarService','EasyAntiCheat','EasyAntiCheatSys','SteamService','BEService')
    foreach ($s in $serviceNames) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq 'Running') {
            Write-Log "  - Stopping service: $s" DarkGray
            Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "`nAll launcher processes/services stopped." Green
    Pause-AndClear
}
 
# ---------------- MAIN MENU ----------------
Write-Banner
Write-Log "Log: $logFile" DarkGray
 
while ($true) {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "  1. Uninstall Rockstar Games Services"
    Write-Host "  2. Remove Traces"
    Write-Host "  3. Stop Launcher Services (Rockstar / Steam / Epic Games)"
    Write-Host "  0. Exit"
    Write-Host "========================================================" -ForegroundColor Cyan
    $choice = Read-Host "Choose an option"
    switch ($choice) {
        '1' { Invoke-Uninstall }
        '2' { Invoke-TraceMenu }
        '3' { Invoke-StopAllLaunchers }
        '0' { Write-Log "`nDone. Restart your computer if you made changes." Green; exit }
        default { Write-Host "Invalid option." -ForegroundColor Red }
    }
}