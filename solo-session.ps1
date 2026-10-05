# --- FORCE UTF-8 CONSOLE ENCODING ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- DECLARE NATIVE WINDOWS METHODS ---
$ntdllCode = @"
using System;
using System.Runtime.InteropServices;

public class ProcessControl {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSuspendProcess(IntPtr processHandle);

    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtResumeProcess(IntPtr processHandle);
}
"@
Add-Type -TypeDefinition $ntdllCode -ErrorAction SilentlyContinue

# --- FIND THE PROCESS ---
$processName = "GTA5_Enhanced"
$process = Get-Process -Name $processName -ErrorAction SilentlyContinue

if (-not $process) {
    Write-Host "GTA V not found. Open the game first." -ForegroundColor Red
    exit
}

# --- FREEZE THE GAME ---
[ProcessControl]::NtSuspendProcess($process.Handle)

# --- ANIMATED PERCENTAGE ---
$total = 10
for ($i = $total; $i -ge 0; $i--) {
    Clear-Host
    
    # Compute percentage
    $pct = ($total - $i) / $total
    $percent = [int]($pct * 100)

    # Pick color by progress
    if ($pct -lt 0.34) { $color = "Red" }
    elseif ($pct -lt 0.67) { $color = "Yellow" }
    else { $color = "Green" }

    Write-Host ""
    Write-Host "   STATUS: IN PROGRESS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   $percent %" -ForegroundColor $color
    Write-Host ""
    Write-Host "   Time left: $i s" -ForegroundColor White
    Write-Host ""

    Start-Sleep -Seconds 1
}

# --- RESUME THE GAME ---
[ProcessControl]::NtResumeProcess($process.Handle)
Clear-Host
Write-Host ""
Write-Host "   STATUS: COMPLETED" -ForegroundColor Green
Write-Host ""
Write-Host "   100 %" -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 1

# --- FOCUS THE GTA V WINDOW ---
$wshell = New-Object -ComObject WScript.Shell
$wshell.AppActivate($process.Id) | Out-Null
Start-Sleep -Milliseconds 300 

Write-Host "   Sequence finished successfully!" -ForegroundColor Cyan
Start-Sleep -Seconds 1
exit
